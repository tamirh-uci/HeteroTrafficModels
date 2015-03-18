classdef markov_video_frames < handle
    %MARKOV_VIDEO_FRAMES determine the frame type of a video transmission
    
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        function type = GOPFrameType(gopIndex, countdownTimer, anchorDist, iMin, bMin, pMin)
            if (gopIndex == 1)
                if (countdownTimer == iMin)
                    type = dcf_state_type.IFrameNew;
                else
                    type = dcf_state_type.IFrameContinue;
                end
            else
                groupIndex = mod(gopIndex - 1, anchorDist);
                if (groupIndex == 0)
                    if (countdownTimer == pMin)
                        type = dcf_state_type.PFrameNew;
                    else
                        type = dcf_state_type.PFrameContinue;
                    end
                else
                    if (countdownTimer == bMin)
                        type = dcf_state_type.BFrameNew;
                    else
                        type = dcf_state_type.BFrameContinue;
                    end
                end
            end
        end
        
        function bIFrame = IsIFrame(type)
            bIFrame = (type == dcf_state_type.IFrameNew || type == dcf_state_type.IFrameContinue);
        end
        
        function bBFrame = IsBFrame(type)
            bBFrame = (type == dcf_state_type.BFrameNew || type == dcf_state_type.BFrameContinue); 
        end
        
        function bPFrame = IsPFrame(type)
            bPFrame = (type == dcf_state_type.PFrameNew || type == dcf_state_type.PFrameContinue);
        end
        
        % gopIndex goes from 1 - (gopFullFrameDistance+1), uniquely
        % identifies the type of frame (IBBPBBP....BBP)
        % packetCountdown determines how many more packets we have until
        % this frame has finished sending
        % indices = [gopIndex, packetCountdown]
        function key = FrameState(indices, type)
            key = markov_video_frames.Dim(type, indices);
        end
    end % methods (Static)
    
    methods
        function obj = markov_video_frames()
            obj = obj@handle;
        end
        
        function chain = CreateMarkovChain(this, verbose)
            chain = markov_chain();
            
            this.CalculateConstants();
            this.GenerateStates(chain, verbose);
            this.SetProbabilities(chain);
            
            if (verbose)
                chain.PrintMapping();
            end
            
            chain.Collapse();
            assert( chain.Verify() );
        end
        
        function CalculateConstants(this)
            this.nGroups = floor(this.gopFullFrameDistance / this.gopAnchorFrameDistance);
            this.nBPerGroup = this.gopAnchorFrameDistance - 1;
            
            nIPerGOP = 1;
            nPPerGOP = this.nGroups;
            nBPerGOP = this.nGroups * this.nBPerGroup;
            nFramePerGOP = nIPerGOP + nPPerGOP + nBPerGOP;
            
            assert( nPPerGOP + nBPerGOP == this.gopFullFrameDistance );
            
            this.pIFrame = nIPerGOP / nFramePerGOP;
            this.pPFrame = nPPerGOP / nFramePerGOP;
            this.pBFrame = nBPerGOP / nFramePerGOP;
            
            this.iFps = this.fps * this.pIFrame;
            this.pFps = this.fps * this.pPFrame;
            this.bFps = this.fps * this.pBFrame;
            
            this.iBps = this.bps * this.pIBit;
            this.pBps = this.bps * this.pPBit;
            this.bBps = this.bps * this.pBBit;
            
            this.iPktAvgCount = ceil( (this.iBps / this.iFps) / this.payloadSize );
            this.pPktAvgCount = ceil( (this.pBps / this.pFps) / this.payloadSize );
            this.bPktAvgCount = ceil( (this.bBps / this.bFps) / this.payloadSize );
            
            this.iPktMinCount = 1;
            this.pPktMinCount = 1;
            this.bPktMinCount = 1;
            
            this.iPktMaxCount = this.iPktAvgCount + (this.iPktAvgCount - this.iPktMinCount);
            this.pPktMaxCount = this.pPktAvgCount + (this.pPktAvgCount - this.pPktMinCount);
            this.bPktMaxCount = this.bPktAvgCount + (this.bPktAvgCount - this.bPktMinCount);
            
            this.iPktRange = this.iPktMaxCount - this.iPktMinCount;
            this.pPktRange = this.pPktMaxCount - this.pPktMinCount;
            this.bPktRange = this.bPktMaxCount - this.bPktMinCount;
        end
        
        function type = FrameType(this, gopIndex, countdownTimer)
            type = markov_video_frames.GOPFrameType(gopIndex, countdownTimer, this.gopAnchorFrameDistance, this.iPktMinCount, this.bPktMinCount, this.pPktMinCount);
        end
        
        function GenerateStates(this, chain, verbose)
            gopIndex = 1;
            
            % Single i frame will lead the GOP
            for i = this.iPktMinCount:this.iPktMaxCount
                type = this.FrameType(gopIndex, i);
                assert( markov_video_frames.IsIFrame(type) );
                
                key = markov_video_frames.FrameState([gopIndex, i], type);
                chain.NewState( dcf_state(key, type) );
            end
            if (verbose)
                fprintf('I = %d (%d-%d)\n', gopIndex, this.iPktMinCount, this.iPktMaxCount);
            end
            gopIndex = gopIndex + 1;
            
            % Repeat pattern of BBP
            for group = 1:this.nGroups
                % Repition of B's
                for bCount = 1:this.nBPerGroup
                    for i = this.bPktMinCount:this.bPktMaxCount
                        type = this.FrameType(gopIndex, i);
                        assert( markov_video_frames.IsBFrame(type) );

                        key = markov_video_frames.FrameState([gopIndex, i], type);
                        chain.NewState( dcf_state(key, type) );
                    end
                    if (verbose)
                        fprintf('B = %d (%d-%d)\n', gopIndex, this.bPktMinCount, this.bPktMaxCount);
                    end
                    gopIndex = gopIndex + 1;
                end
                
                % P frames cap off the group of B's, unless it's the last
                if (group < this.nGroups)
                    for i = this.pPktMinCount:this.pPktMaxCount
                        type = this.FrameType(gopIndex, i);
                        assert( markov_video_frames.IsPFrame(type) );

                        key = markov_video_frames.FrameState([gopIndex, i], type);
                        chain.NewState( dcf_state(key, type) );
                    end
                    if (verbose)
                        fprintf('P = %d (%d-%d)\n', gopIndex, this.pPktMinCount, this.pPktMaxCount);
                    end
                    gopIndex = gopIndex + 1;
                end
            end
            
            assert( gopIndex == this.gopFullFrameDistance+1 );
        end
        
        function SetProbabilities(this, chain)
            for gopIndex = 1:this.gopFullFrameDistance
                % Loop back if we're at the end of the chain
                if (gopIndex == this.gopFullFrameDistance)
                    nextGopIndex = 1;
                else
                    nextGopIndex = 1+gopIndex;
                end
                
                srcType = this.FrameType(gopIndex, 1);
                src = this.FrameState([gopIndex, 1], srcType);
                if (markov_video_frames.IsIFrame(srcType))
                    srcMin = this.iPktMinCount;
                    srcMax = this.iPktMaxCount;
                    txType = dcf_transition_type.TxIFrame;
                elseif (markov_video_frames.IsBFrame(srcType))
                    srcMin = this.bPktMinCount;
                    srcMax = this.bPktMaxCount;
                    txType = dcf_transition_type.TxBFrame;
                elseif (markov_video_frames.IsPFrame(srcType))
                    srcMin = this.pPktMinCount;
                    srcMax = this.pPktMaxCount;
                    txType = dcf_transition_type.TxPFrame;
                end
                
                % Distribute "evenly" to the next frame
                % Source is the end of the timer, so we go to the next
                dstType = this.FrameType(nextGopIndex, 1);
                if (markov_video_frames.IsIFrame(dstType))
                    min = this.iPktMinCount;
                    med = this.iPktAvgCount;
                    max = this.iPktMaxCount;
                    this.Distribute(chain, src, txType, nextGopIndex, min, med, max, this.iAvgWeight, this.iSmallWeight, this.iLargeWeight);
                elseif (markov_video_frames.IsBFrame(dstType))
                    min = this.bPktMinCount;
                    med = this.bPktAvgCount;
                    max = this.bPktMaxCount;
                    this.Distribute(chain, src, txType, nextGopIndex, min, med, max, this.bAvgWeight, this.bSmallWeight, this.bLargeWeight);
                elseif (markov_video_frames.IsPFrame(dstType))
                    min = this.pPktMinCount;
                    med = this.pPktAvgCount;
                    max = this.pPktMaxCount;
                    this.Distribute(chain, src, txType, nextGopIndex, min, med, max, this.pAvgWeight, this.pSmallWeight, this.pLargeWeight);
                end
                
                % Generate the packet timer chain
                for i = (srcMin+1):srcMax
                    src = markov_video_frames.FrameState([gopIndex, i], this.FrameType(gopIndex, i));
                    dst = markov_video_frames.FrameState([gopIndex, i-1], this.FrameType(gopIndex, i-1));
                    chain.SetP( src, dst, 1.0, txType );
                end
            end
        end
    
        function Distribute(this, chain, src, txType, nextGopIndex, min, med, max, avgWeight, smallWeight, largeWeight)
            % chance to go directly to the avg weight packet
            %fprintf('Trying to make [%d, %d]\n', nextGopIndex, med);
            dstType = this.FrameType(nextGopIndex, med);
            dst = markov_video_frames.FrameState([nextGopIndex, med], dstType);
            chain.SetP( src, dst, avgWeight, txType );
            
            % evenly distribute over the smalller values
            nSmall = med - min;
            pSmall = smallWeight / nSmall;
            for i = min:(med-1)
                dstType = this.FrameType(nextGopIndex, i);
                dst = markov_video_frames.FrameState([nextGopIndex, i], dstType);
                chain.SetP( src, dst, pSmall, txType );
            end
            
            % evenly distribute over the larger values
            nLarge = max - med;
            pLarge = largeWeight / nLarge;
            for i = (med+1):max
                dstType = this.FrameType(nextGopIndex, i);
                dst = markov_video_frames.FrameState([nextGopIndex, i], dstType);
                chain.SetP( src, dst, pLarge, txType );
            end
        end
    end % methods
    
    % GOP characteristics
    properties
        % One minus the distance between two P frames in a GOP
        % One greater than the number of B frames in a (B*)P group
        gopAnchorFrameDistance = 3;
        
        % Distance between two I frames (length of a GOP less the bookend I)
        gopFullFrameDistance = 12;
        
        % percentage of data which ends up as each type of frame
        pIBit = 0.182;
        pPBit = 0.454;
        pBBit = 0.364;
        
        % percent of markov states that go directly to average # packets
        iAvgWeight = 0.50;
        pAvgWeight = 0.50;
        bAvgWeight = 0.50;
        
        % percent of markov states that go below the avg # packets
        iSmallWeight = 0.20;
        pSmallWeight = 0.20;
        bSmallWeight = 0.20;
        
        % percent of markov states that go above the avg # packets
        iLargeWeight = 0.30;
        pLargeWeight = 0.30;
        bLargeWeight = 0.30;
        
        % goal datarate in bits/second
        bps = 4 * 1000000; % 4MBits/second
        
        % FPS of video
        fps = 30;
        
        % the 802.11 datagram size we're working with in bits
        payloadSize = 1500*8;
    end
    
    % Calculated GOP characteristics
    properties (SetAccess = protected)
        % Number of BP groups
        nGroups;
        
        % Number of B frames per BP group
        nBPerGroup;
        
        % probability of frame in sequence
        pIFrame;
        pPFrame;
        pBFrame;
        
        % frames per second of each frame type
        iFps;
        pFps;
        bFps;
        
        % bits per second of each frame type
        iBps;
        pBps;
        bBps;
        
        % size of average frame type in # packets
        iPktAvgCount;
        pPktAvgCount;
        bPktAvgCount;
        
        % minimum num packets per frame type
        iPktMinCount;
        pPktMinCount;
        bPktMinCount;
        
        % maximum num of packets per frame type
        iPktMaxCount;
        pPktMaxCount;
        bPktMaxCount;
        
        % number of possible distinct packet #s per frame type
        iPktRange;
        pPktRange;
        bPktRange;
    end
end
