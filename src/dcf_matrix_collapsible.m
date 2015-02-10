classdef dcf_matrix_collapsible < dcf_matrix_oo
    methods (Static)
        function key = SuccessState()
            key = [-1, -1];
        end
        
        function key = FailState(stage)
            key = [-1, stage];
        end
    end
    
    methods
        function obj = dcf_matrix_collapsible()
            obj = obj@dcf_matrix_oo;
        end
        
        function [pi, dims, dcf] = CreateMatrix(this, pFail, nPacketSizeStates, nInterarrivalStates)
            this.pRawFail = pFail;
            this.nPkt = nPacketSizeStates;
            this.nInterarrival = nInterarrivalStates;
            this.CalculateConstants();
            
            % Initialize the transition matrix
            dcf = dcf_container();
            
            % store the dimensions of each state
            dims = [this.nRows, this.nColsMax]; 

            % Create all of the states
            % current format is [row, col, nPkt, nInterarrival]
            
            % all transmit success will go back to stage 1 for
            % redistribution of what happens next
            dcf.NewState( dcf_state( this.SuccessState(), dcf_state_type.Collapsible ) );
            
            for i = 1:this.nRows
                wCols = this.W(1,i);

                % transmit attempt states
                for k = 1:this.beginBackoffCol-1
                    dcf.NewState( dcf_state( [i, k], dcf_state_type.Transmit ) );
                end

                % backoff states
                for k = this.beginBackoffCol:wCols
                    dcf.NewState( dcf_state( [i, k], dcf_state_type.Backoff ) );
                end

                % packet size 'calculation' states
                if (this.nPkt > 1)
                    for k = 2:this.nPkt
                        dcf.NewState( dcf_state( [i, 1, k], dcf_state_type.PacketSize ) );
                    end
                end

                % interarival time 'calculation' states
                for k = 1:this.nInterarrival
                    dcf.NewState( dcf_state( [i, 1, 1, k], dcf_state_type.Interarrival ) );
                end
                
                % collapsible failure state for each stage
                dcf.NewState( dcf_state( this.FailState(i), dcf_state_type.Collapsible ) );

                % unused states
            %     if (wCols < this.nColsMax)
            %         for k=wCols+1:this.nColsMax
            %             dcf.NewState( dcf_state( [i, k], dcf_state_type.Null ) );
            %         end
            %     end
            end

            
            % If success, we have equal probability to go to each of
            % stage 1 backoff or transmit immediately
            % CASE 2
            pDistSuccess = 1.0 / this.W(1,1);
            for k = 1:this.W(1,1)
                dcf.SetP( this.SuccessState(), [1, k], pDistSuccess, dcf_transition_type.TxSuccess );
            end
            
            % Initialize the probabilities from all transmission stages 
            for i = 1:this.nRows
                wCols = this.W(1,i);

                % Handle the last stage specially -- it loops on top of itself
                nextStage = this.nRows;
                if (i < this.nRows)
                    nextStage = i + 1;
                end

                % Failure case
                % CASE 3/4
                % Going from our transmit attempt to failure state
                dcf.SetP( [i, 1], this.FailState(i), this.pRawFail, dcf_transition_type.TxFailure );
                
                % Going from failure state to backoff states of next stage
                wColsNext = this.W(1, nextStage);
                pDistFail = 1.0 / wColsNext;
                for k = 1:wColsNext
                    dcf.SetP( this.FailState(i), [nextStage,k], pDistFail, dcf_transition_type.TxFailure );    
                end

                
                % Success case
                % CASE 2                
                % Set the probabilities for each of the transmit attempt states to succeed
                dcf.SetP( [i, 1], this.SuccessState(), this.pRawSuccess, dcf_transition_type.TxSuccess );
                
                
                % Initialize the probabilities from backoff stages to the transmission
                % stage (all stages k > 1)
                % CASE 1
                for k = this.beginBackoffCol:wCols
                    dcf.SetP( [i,k], [i,k-1], 1.0, dcf_transition_type.Backoff );
                end
            end

            dcf.Collapse();
            [pi, ~] = dcf.TransitionTable();
            assert( dcf.Verify() );

        end %function CreateMatrix
    end    
end

