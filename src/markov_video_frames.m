classdef markov_video_frames < handle
    %MARKOV_VIDEO_FRAMES determine the frame type of a video transmission
    
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        function key = IFrameState()
            key = markov_video_frames.Dim(dcf_state_type.IFrame, 0);
        end
        
        function key = BFrameState()
            key = markov_video_frames.Dim(dcf_state_type.BFrame, 0);
        end
        
        function key = PFrameState()
            key = markov_video_frames.Dim(dcf_state_type.PFrame, 0);
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
            this.pII = 0.5;
            this.pBB = 0.6;
            this.pPI = 0.1;
            this.pPB = 0.2;
            
            % Dump into a matrix to calculate easier
            pi = [this.pII, this.pIB, this.pIP; this.pBI, this.pBB, this.pBP; this.pPI, this.pPB, this.pPP];
            epsilon = 0.0001;
            
            for row=1:3
                z = find( pi(row,:)==0 );
                nonz = find( pi(row,:)~=0 );
                nZero = size(z,2);
                
                % Divide equally if all 3 gone
                if( nZero == 3 )
                    pi(row, z) = 1.0/3.0;
                elseif (nZero == 2)
                    % Divide between both 0's if you only have 1 p
                    r = 1.0 - pi(row,nonz);
                    pi(row,z) = 0.5 * r;
                elseif (nZero == 1)
                    % Remainder goes to 0 p
                    r = 1.0 - sum( pi(row,nonz) );
                    pi(row,z) = r;
                end
            end
            
            for row=1:3
                s = sum( pi(row,:) );
                assert( s >= -epsilon );
                assert( s <= 1.0 + epsilon );
            end
            
            % dump values back into variables for easy use
            this.pII = pi(1,1);
            this.pIB = pi(1,2);
            this.pIP = pi(1,3);
            
            this.pBI = pi(2,1);
            this.pBB = pi(2,2);
            this.pBP = pi(2,3);
            
            this.pPI = pi(3,1);
            this.pPB = pi(3,2);
            this.pPP = pi(3,3);            
        end
        
        function GenerateStates(this, chain)
            chain.NewState( dcf_state( this.IFrameState(), dcf_state_type.IFrame ) );
            chain.NewState( dcf_state( this.BFrameState(), dcf_state_type.BFrame ) );
            chain.NewState( dcf_state( this.PFrameState(), dcf_state_type.PFrame ) );
        end
        
        function SetProbabilities(this, chain)
            % Simple 3 state markov chain, each state has p to every other
            iFrame = this.IFrameState();
            bFrame = this.BFrameState();
            pFrame = this.PFrameState();
            
            chain.SetP( iFrame, iFrame, this.pII, dcf_transition_type.IFrame );
            chain.SetP( iFrame, bFrame, this.pIB, dcf_transition_type.BFrame );
            chain.SetP( iFrame, pFrame, this.pIP, dcf_transition_type.PFrame );
            
            chain.SetP( bFrame, iFrame, this.pBI, dcf_transition_type.IFrame );
            chain.SetP( bFrame, bFrame, this.pBB, dcf_transition_type.BFrame );
            chain.SetP( bFrame, pFrame, this.pBP, dcf_transition_type.PFrame );
            
            chain.SetP( pFrame, iFrame, this.pPI, dcf_transition_type.IFrame );
            chain.SetP( pFrame, bFrame, this.pPB, dcf_transition_type.BFrame );
            chain.SetP( pFrame, pFrame, this.pPP, dcf_transition_type.PFrame );
        end
    end % methods
    
    % Transition probabilities from each frame type to each other
    properties
        pII = 0;
        pIB = 0;
        pIP = 0;
        
        pBI = 0;
        pBB = 0;
        pBP = 0;
        
        pPI = 0;
        pPB = 0;
        pPP = 0;
    end % properties
    
end

