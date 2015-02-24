classdef markov_video_frames < handle
    %MARKOV_VIDEO_FRAMES determine the frame type of a video transmission
    
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        % There is one i-frame per GOP (we don't count the end bookend,
        % because we just consider that part of the next GOP for markov
        % chain reasons)
        function key = IFrameState()
            key = markov_video_frames.Dim(dcf_state_type.IFrame, 0);
        end
        
        % indices = [group, countdown]
        function key = BFrameState(indices)
            key = markov_video_frames.Dim(dcf_state_type.BFrame, indices);
        end
        
        % indices = [group]
        function key = PFrameState(indices)
            key = markov_video_frames.Dim(dcf_state_type.PFrame, indices);
        end
    end % methods (Static)
    
    methods
        function obj = markov_video_frames()
            obj = obj@handle;
        end
        
        function chain = CreateMarkovChain(this)
            chain = markov_chain();
            
            this.CalculateConstants();
            this.GenerateStates(chain);
            this.SetProbabilities(chain);
            
            chain.Collapse();
            assert( chain.Verify() );
        end
        
        function CalculateConstants(this)
            this.nGroups = int32( floor(this.gopFullFrameDistance / this.gopAnchorFrameDistance) );
            this.nBPerGroup = this.gopAnchorFrameDistance - 1;
        end
        
        function GenerateStates(this, chain)
            % Single i frame will lead the GOP
            chain.NewState( dcf_state( IFrameState(), dcf_state_type.IFrame ) );
            
            % Repeat pattern of BBP
            for group = 1:this.nGroups
                % Repition of B's
                for bCount = 1:this.nBPerGroup
                    chain.NewState( dcf_state( BFrameState([group, bCount]), dcf_state_type.BFrame ) );
                end
                
                % P frames cap off the group of B's, unless it's the last
                if (group < this.nGroups)
                    chain.NewState( dcf_state( PFrameState(group), dcf_state_type.PFrame ) );
                end
            end
        end
        
        function SetProbabilities(this, chain)
            % Single i frame will lead the GOP
            src = IFrameState();
            
            % Repeat pattern of BBP
            for group = 1:this.nGroups
                % Repition of B's
                for bCount = 1:this.nBPerGroup
                    dst = BFrameState([group, bCount]);
                    chain.SetP( src, dst, 1.0, dcf_transition_type.BFrame );
                    src = dst;
                end
                
                % P frames cap off the group of B's, unless it's the last
                if (group < this.nGroups)
                    dst = PFrameState(group);
                    chain.SetP( src, dst, 1.0, dcf_transition_type.PFrame );
                    src = dst;
                else
                    dst = IFrameState();
                    chain.SetP( src, dst, 1.0, dcf_transition_type.IFrame );
                    src = dst;
                end
            end
        end
    end % methods
    
    % GOP characteristics
    properties
        % One minus the distance between two P frames in a GOP
        gopAnchorFrameDistance@int32 = 3;
        
        % Distance between two I frames (length of a GOP less the bookend I)
        gopFullFrameDistance@int32 = 12;
        
        % Number of BP groups
        nGroups@int32;
        
        % Number of B frames per group
        nBPerGroup@int32;
    end   
end

