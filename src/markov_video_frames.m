classdef markov_video_frames < handle
    %MARKOV_VIDEO_FRAMES determine the frame type of a video transmission
    
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        % indices = [gopIndex]
        function key = FrameState(indices)
            key = markov_video_frames.Dim(dcf_state_type.VideoFrame, indices);
        end
    end % methods (Static)
    
    methods
        function obj = markov_video_frames()
            obj = obj@handle;
        end
        
        function chain = CreateMarkovChain(this, verbose)
            chain = markov_chain();
            
            this.CalculateConstants();
            this.GenerateStates(chain);
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
        end
        
        function GenerateStates(this, chain)
            gopIndex = 1;
            
            % Single i frame will lead the GOP
            chain.NewState( dcf_state( markov_video_frames.FrameState(gopIndex), dcf_state_type.IFrame ) );
            gopIndex = gopIndex + 1;
            
            % Repeat pattern of BBP
            for group = 1:this.nGroups
                % Repition of B's
                for bCount = 1:this.nBPerGroup
                    chain.NewState( dcf_state( markov_video_frames.FrameState(gopIndex), dcf_state_type.BFrame ) );
                    gopIndex = gopIndex + 1;
                end
                
                % P frames cap off the group of B's, unless it's the last
                if (group < this.nGroups)
                    chain.NewState( dcf_state( markov_video_frames.FrameState(gopIndex), dcf_state_type.PFrame ) );
                    gopIndex = gopIndex + 1;
                end
            end
            
            assert( gopIndex == this.gopFullFrameDistance+1 );
        end
        
        function SetProbabilities(this, chain)
            for gopIndex = 1:this.gopFullFrameDistance
                src = markov_video_frames.FrameState(gopIndex);
                if (gopIndex == this.gopFullFrameDistance)
                    dst = markov_video_frames.FrameState(1);
                else
                    dst = markov_video_frames.FrameState(1+gopIndex);
                end
                
                dstType = chain.Type(dst);
                switch(dstType)
                    case dcf_state_type.IFrame
                        txType = dcf_transition_type.TxIFrame;
                    case dcf_state_type.BFrame
                        txType = dcf_transition_type.TxBFrame;
                    case dcf_state_type.PFrame
                        txType = dcf_transition_type.TxPFrame;
                end
                
                chain.SetP( src, dst, 1.0, txType );
            end
        end
    end % methods
    
    % GOP characteristics
    properties
        % One minus the distance between two P frames in a GOP
        gopAnchorFrameDistance = 3;
        
        % Distance between two I frames (length of a GOP less the bookend I)
        gopFullFrameDistance = 12;
    end
    
    % Calculated GOP characteristics
    properties (SetAccess = protected)
        % Number of BP groups
        nGroups;
        
        % Number of B frames per group
        nBPerGroup;
    end   
end

