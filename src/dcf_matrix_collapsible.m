classdef dcf_matrix_collapsible < handle
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        % there is only 1 success state, no need for indices
        function key = SuccessState()
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleSuccess, 0);
        end
        
        % indices = [stage]
        function key = FailState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleFailure, indices);
        end
        
        % indices = [stage]
        function key = TransmitAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleTransmit, indices);
        end
        
        % indices = [stage]
        function key = PacketsizeAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsiblePacketSize, indices);
        end
        
        % indices = [stage]
        function key = InterarrivalAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleInterarrival, indices);
        end
        
        % indices = [stage, backoffTimer]
        % backoffTimer = 1 means a transmit state
        function key = DCFState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Backoff, indices);
        end
        
        % indices = [stage, packetSize]
        function key = PacketsizeSingleChainState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==2 || size(indices,2)==3 ) );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PacketSize, indices);
        end
        
        % indices = [stage, interarrivalLength]
        function key = InterarrivalState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Interarrival, indices);
        end
        
        % indices = [stage, postbackoffLength]
        function key = PostbackoffStageState(indices)
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PostbackoffStage, indices);
        end
        
        % indices = [stage, postbackoffLength]
        function key = PostbackoffTimerState(indices)
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PostbackoffTimer, indices);
        end
    end
    
    methods
        function obj = dcf_matrix_collapsible()
            obj = obj@handle;
        end
        
        function [pi, dims, dcf] = CreateMatrix(this, pFail)
            this.pRawFail = pFail;
            this.CalculateConstants();
            
            % Initialize the transition matrix
            dcf = dcf_container();
            
            % store the dimensions of each DCF state
            dims = [this.nStages, this.nColsMax]; 

            % Create all of the states and set probabilities of transitions
            this.GenerateStates(dcf);
            this.SetProbabilities(dcf);

            % Remove temporary states and format output for 
            dcf.Collapse();
            [pi, ~] = dcf.TransitionTable();
            assert( dcf.Verify() );

        end %function CreateMatrix
        
        
        function GenerateStates(this, dcf)
            % all transmit success will go back to stage 1 for
            % redistribution of what happens next
            dcf.NewState( dcf_state( this.SuccessState(), dcf_state_type.CollapsibleSuccess ) );
            
            for i = 1:this.nStages
                wCols = this.W(1,i);

                % going into this state means we are going to attempt to
                % transmit a packet (which may not be there to transmit)
                dcf.NewState( dcf_state( this.TransmitAttemptState(i), dcf_state_type.CollapsibleTransmit ) );
                
                % collapsible failure state for each stage
                dcf.NewState( dcf_state(this.FailState(i), dcf_state_type.CollapsibleFailure) );
                
                % collapsible packetsize and interarrival states
                % these stand right before the chains
                dcf.NewState( dcf_state(this.PacketsizeAttemptState(i), dcf_state_type.CollapsiblePacketSize) );
                dcf.NewState( dcf_state(this.InterarrivalAttemptState(i), dcf_state_type.CollapsibleInterarrival) );
                
                % backoff timer has reached 0
                for k = 1:this.beginBackoffCol-1
                    key = this.DCFState([i, k]);
                    dcf.NewState( dcf_state(key, dcf_state_type.Transmit) );
                end

                % backoff states
                for k = this.beginBackoffCol:wCols
                    key = this.DCFState([i, k]);
                    dcf.NewState( dcf_state(key, dcf_state_type.Backoff) );
                end

                % packet size 'calculation' states
                if (this.bUseSingleChainPacketsize)
                    for k = 1:this.nPkt
                        key = this.PacketsizeSingleChainState([i, k]);
                        dcf.NewState( dcf_state(key, dcf_state_type.PacketSize) );
                    end
                else
                    for k = 1:this.nPkt
                        for j = 1:k
                            key = this.PacketsizeMultiChainState([i, k, j]);
                            dcf.NewState( dcf_state(key, dcf_state_type.PacketSize) );
                        end
                    end
                end

                % interarival time 'calculation' states
                for k = 1:this.nInterarrival
                    key = this.InterarrivalState([i, k]);
                    dcf.NewState( dcf_state(key, dcf_state_type.Interarrival) );
                end
            end
        end % function GenerateStates
        
        
        function SetProbabilities(this, dcf)
            % CASE 2
            % If success, we have equal probability to go to each of
            % stage 1 backoff or transmit immediately
            pDistSuccess = 1.0 / this.W(1,1);
            src = this.SuccessState();
            for k = 1:this.W(1,1)
                dst = this.DCFState([1, k]);
                dcf.SetP( src, dst, pDistSuccess, dcf_transition_type.TxSuccess );
            end
            
            % Initialize the probabilities from all transmission stages 
            for i = 1:this.nStages
                wCols = this.W(1,i);
                
                % Handle the last stage specially -- it loops on top of itself
                nextStage = this.nStages;
                if (i < this.nStages)
                    nextStage = i + 1;
                end
                
                % CASE 1
                % Initialize the probabilities from backoff stages to the transmission
                % stage (all timers k>1)
                for k = this.beginBackoffCol:wCols
                    src = this.DCFState([i, k]);
                    dst = this.DCFState([i, k-1]);
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.Backoff );
                end
                
                % Once the backoff timer reaches 0, we will attempt to send
                src = this.DCFState([i,1]);
                dst = this.TransmitAttemptState(i);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
                
                % CASE 2                
                % "Success" case 
                % (actual success is down the packetsize chain)
                % 50% chance to packet size calculation
                % 50% chance to interarrival size calculation
                src = this.TransmitAttemptState(i);
                
                dst = this.PacketsizeAttemptState(i);
                dcf.SetP( src, dst, 0.5, dcf_transition_type.Collapsible );
                
                dst = this.InterarrivalAttemptState(i);
                dcf.SetP( src, dst, 0.5, dcf_transition_type.Collapsible );
                
                % Going from failure state to backoff states of next stage
                wColsNext = this.W(1, nextStage);
                pDistFail = 1.0 / wColsNext;
                src = this.FailState(i);
                for k = 1:wColsNext
                    dst = this.DCFState([nextStage, k]);
                    dcf.SetP( src, dst, pDistFail, dcf_transition_type.TxFailure );    
                end
                
                % We have data to transmit -- go to packetsize chain
                if (this.nPkt < 1)
                    % Packetsize is always 1 unit long in this case, so we
                    % don't even enter the chain
                    src = this.PacketsizeAttemptState(i);
                    
                    dst = this.FailState(i);
                    dcf.SetP( src, dst, this.pRawFail, dcf_transition_type.Collapsible );
                    
                    dst = this.SuccessState();
                    dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.Collapsible );
                else
                    if (this.bUseSingleChainPacketsize)
                        this.GenerateSingleChainPacketsizeStates(i);
                    else
                        this.GenerateMultichainPacketsizeStates(i);
                    end
                end

                % We have nothing to transmit -- go into interarrival chain
                if (this.nInterarrival < 1)
                    % We are not simulating buffer emptying, so really we do
                    % have a packet to send
                    src = this.InterarrivalAttemptState(i);
                    
                    dst = this.FailState(i);
                    dcf.SetP( src, dst, this.pRawFail, dcf_transition_type.Collapsible );
                    
                    dst = this.SuccessState();
                    dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.Collapsible );
                else
                    this.GenerateInterarrivalStates(i);
                end
            end
        end % function SetProbabilities
        
        function GenerateSingleChainPacketsizeStates(this, i)
            % Equal probability to go to any packetsize
            pPacketState = 1.0 / this.nPkt;
            for k = 1:this.nPkt
                src = this.PacketsizeAttemptState(i);
                dst = this.PacketsizeSingleChainState(i, k);
                dcf.SetP( src, dst, pPacketState, dcf_transition_type.PacketSize );
            end

            % With probability of success, we travel down the
            % packetsize chain
            for k = 1:this.nPkt-1
                src = this.PacketsizeState(i, k);
                dst = this.PacketsizeSingleChainState(i, k+1);
                dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.PacketSize );
            end

            % The last index of the packetsize chain going into the
            % actual success state if it succeeds
            src = this.PacketsizeSingleChainState(i, this.nPkt);
            dst = this.SuccessState();
            dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.Collapsible );

            % All failures in the chain go straight to the fail state
            for k = 1:this.nPkt
                src = this.PacketsizeState(i, k);
                dst = this.FailState(i);
                dcf.SetP( src, dst, this.pRawFail, dcf_transition_type.Collapsible );
            end
        end % function GenerateSingleChainPacketsizeStates
        
        function GenerateMultichainPacketsizeStates(this, i)
            % Equal probability to go to any start of the packetsize chain
            pPacketState = 1.0 / this.nPkt;
            for k = 1:this.nPkt
                src = this.PacketsizeAttemptState(i);
                dst = this.PacketsizeMultiChainState(i, k, 1);
                dcf.SetP( src, dst, pPacketState, dcf_transition_type.PacketSize );
            end
            
            % Travel down the packetsize chains
            for k = 2:this.nPkt
                for j = 1:k-1
                    src = this.PacketsizeMultiChainState(i, k, j);
                    dst = this.PacketsizeMultiChainState(i, k, j+1);
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.PacketSize );
                end
            end
            
            % The last index of the packetsize chain will calculate if it
            % succeeded or failed
            for k = 1:this.nPkt
                src = this.PacketsizeSingleChainState(i, k, k);
                pAllSucceed = this.pRawSuccess ^ k;
                pOneFail = 1 - pAllSucceed;
                
                dst = this.SuccessState();
                dcf.SetP( src, dst, pAllSucceed, dcf_transition_type.Collapsible );
                
                dst = this.FailState(i);
                dcf.SetP( src, dst, pOneFail, dcf_transition_type.Collapsible );
            end
        end % function GenerateMultichainPacketsizeStates
        
        function GenerateInterarrivalStates(this, i)
            % Equal probabilities to go to any state in the chain
            pInterarrivalState = 1.0 / this.nInterarrival;
            for k = 1:this.nInterarrival
                dcf.SetP( this.InterarrivalAttemptState(i), this.InterarrivalState(i, k), pInterarrivalState, dcf_transition_type.Interarrival );
            end

            % Traveling down the interarrival chain (no chance of
            % failure because we're not really doing anything)
            for k = 2:this.nInterarrival
                dcf.SetP( this.InterarrivalState(i, k), this.InterarrivalState(i, k-1), 1.0, dcf_transition_type.PacketSize );
            end

            % At the last state in the chain, we will attempt send
            dcf.SetP( this.InterarrivalState(i, 1), this.TransmitAttemptState(i), this.pRawSuccess, dcf_transition_type.Collapsible );
            dcf.SetP( this.InterarrivalState(i, 1), this.FailState(i), this.pRawFail, dcf_transition_type.Collapsible );
        end % function GenerateInterarrivalStates
        
        
        function CalculateConstants(this)
            this.pRawSuccess = 1 - this.pRawFail;
            this.nStages = this.m + 1;
            this.beginBackoffCol = 2;

            if (this.nInterarrival < 1 || this.pEnterInterarrival == 0)
                this.nInterarrival = 0;
                this.pEnterInterarrival = 0;
            end

            % Compute values for W
            this.W = zeros(1,this.nStages);
            for i = 1:this.nStages
                this.W(1,i) = (2^(i - 1)) * this.wMin;
            end
            
            this.nColsMax = this.W(1, this.nStages);
        end
    end % methods
    
    properties (SetAccess = public)
        % probability any given packet transmission will succeed, given the
        % channel is free
        pRawFail;

        % number of stages
        m;

        % minimum number of backoff states
        wMin;

        % maximum size of packets
        % transmissions will be [1:nPkt] length
        nPkt;

        % number of states in the interarrival chain, we will jump to one
        % randomly with probability pEnterInterarrival
        nInterarrival;
        
        % probability to enter the interarrival chain, so probability there is
        % not a packet immediately ready to send
        pEnterInterarrival;
        
        % use single chain or multichain packetsize states (0 or 1)
        bUseSingleChainPacketsize;
    end %properties (SetAccess = public)

    properties (SetAccess = protected)
        % W matrix which holds number of DCF states in each row
        W;
        
        % 1 - pRawFail
        pRawSuccess;
        
        % number of stages (rows) in the basic DCF matrix
        nStages;
        
        % column where backoff states start
        beginBackoffCol;
        
        % maximum number of columns in any of the rows
        nColsMax;
    end %properties (SetAccess = protected)
end % classdef

