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
            % TODO: Depricated w/ postbackoff?
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
            assert( size(indices,1)==1 && ( size(indices,2)==2 ) );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PacketSize, indices);
        end
        
        % indices = [stage, packetSize, chain timer]
        function key = PacketsizeMultiChainState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==3 ) );
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
            dcf.PrintMapping();
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
                    if (i == 1 && k == 1)
                        continue;
                    end
                    
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
                    % # states = max packet size
                    % Jump into the chain at a random point
                    % At every state, test success vs. failure
                    % At last state, jump back into normal DCF
                    for k = 1:this.nPkt
                        key = this.PacketsizeSingleChainState([i, k]);
                        dcf.NewState( dcf_state(key, dcf_state_type.PacketSize) );
                    end
                else
                    % # chains = max packet size
                    % sending packetsize=X gives X states in that chain
                    % Jump to tail of that chain, and with p=1 traverse
                    % When you reach the head of the chain, check
                    % probability that all of the slots should have
                    % succeeded
                    for k = 1:this.nPkt
                        for j = 1:k
                            key = this.PacketsizeMultiChainState([i, k, j]);
                            dcf.NewState( dcf_state(key, dcf_state_type.PacketSize) );
                        end
                    end
                end

                % interarival time 'calculation' states
                for k = 1:this.nInterarrival
                    % # states = max interarrival wait time
                    % jump randomly into any location in the chain
                    % with p=1 traverse down the chain
                    % when you reach the end, go back into the normal DCF
                    key = this.InterarrivalState([i, k]);
                    dcf.NewState( dcf_state(key, dcf_state_type.Interarrival) );
                end
            end
        end % function GenerateStates
        
        
        function SetProbabilities(this, dcf)
            % CASE 2
            % If success, we have equal probability to go to each of
            % stage 1 backoff or we go back to attempting to send a new
            % packet
            pDistSuccess = 1.0 / this.W(1,1);
            src = this.SuccessState();
            for k = 2:this.W(1,1)
                dst = this.DCFState([1, k]);
                dcf.SetP( src, dst, pDistSuccess, dcf_transition_type.TxSuccess );
            end
            
            % From success, instead of going to DCFState[1 1] we go to
            % TransmitAttempt with the probability we would have used to go
            % to DCFState[1 1]
            dst = this.TransmitAttemptState(1);
            dcf.SetP( src, dst, pDistSuccess, dcf_transition_type.TxSuccess );
            
            
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
                    
                    % for stage 1, we go straight to the TransmitAttempt
                    % once we are done with backoff
                    if (i == 1 && k == 2)
                        dst = this.TransmitAttemptState(1);
                    else
                        dst = this.DCFState([i, k-1]);
                    end
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.Backoff );
                end
                
                % Once the backoff timer reaches 0, we will attempt to send
                % DCFState([1 1]) does not exist
                % it's covered by PacketSizeState( [1 1] ) 
                if (i ~= 1)
                    src = this.DCFState([i,1]);
                    dst = this.TransmitAttemptState(i);
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
                end
                
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
                assert(this.nPkt >= 1);
                if (this.bUseSingleChainPacketsize)
                    this.GenerateSingleChainPacketsizeStates(i, dcf);
                else
                    this.GenerateMultichainPacketsizeStates(i, dcf);
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
        
        
        function GenerateSingleChainPacketsizeStates(this, i, dcf)
            % Equal probability to go to any packetsize
            pPacketState = 1.0 / this.nPkt;
            src = this.PacketsizeAttemptState(i);
            for k = 1:this.nPkt
                dst = this.PacketsizeSingleChainState([i, k]);
                dcf.SetP( src, dst, pPacketState, dcf_transition_type.PacketSize );
            end

            % With probability of success, we travel down the
            % packetsize chain (packetsize 1 has no chain to create)
            for k = 1:this.nPkt-1
                src = this.PacketsizeSingleChainState([i, k]);
                dst = this.PacketsizeSingleChainState([i, k+1]);
                dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.PacketSize );
            end

            % The last index of the packetsize chain going into the
            % actual success state if it succeeds
            src = this.PacketsizeSingleChainState([i, this.nPkt]);
            dst = this.SuccessState();
            dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.Collapsible );

            % All failures in the chain go straight to the fail state
            for k = 1:this.nPkt
                src = this.PacketsizeSingleChainState([i, k]);
                dst = this.FailState(i);
                dcf.SetP( src, dst, this.pRawFail, dcf_transition_type.Collapsible );
            end
        end % function GenerateSingleChainPacketsizeStates
        
        
        function GenerateMultichainPacketsizeStates(this, i, dcf)
            % Equal probability to go to any start of the packetsize chain
            pPacketState = 1.0 / this.nPkt;
            src = this.PacketsizeAttemptState(i);
            for k = 1:this.nPkt
                dst = this.PacketsizeMultiChainState([i, k, 1]);
                dcf.SetP( src, dst, pPacketState, dcf_transition_type.PacketSize );
            end
            
            % Travel down the packetsize chains (packetsize 1 has no chain)
            for k = 2:this.nPkt
                for j = 1:k-1
                    src = this.PacketsizeMultiChainState([i, k, j]);
                    dst = this.PacketsizeMultiChainState([i, k, j+1]);
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.PacketSize );
                end
            end
            
            % The last index of the packetsize chain will calculate if it
            % succeeded or failed
            for k = 1:this.nPkt
                src = this.PacketsizeSingleChainState([i, k, k]);
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
            src = this.InterarrivalAttemptState(i);
            for k = 1:this.nInterarrival
                dst = this.InterarrivalState([i, k]);
                dcf.SetP( src, dst, pInterarrivalState, dcf_transition_type.Interarrival );
            end

            % Traveling down the interarrival chain (no chance of
            % failure because we're not really doing anything)
            for k = 1:this.nInterarrival-1
                src = this.InterarrivalState([i, k]);
                dst = this.InterarrivalState([i, k+1]);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.PacketSize );
            end

            % At the last state in the chain, we will attempt send
            % We now know there is a packet to send, so go straight to the
            % packetsize calculation state
            src = this.InterarrivalState([i, this.nInterarrival]);
            dst = this.PacketsizeAttemptState(i);
            dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
        end % function GenerateInterarrivalStates
        
        
        function CalculateConstants(this)
            this.pRawSuccess = 1 - this.pRawFail;
            this.nStages = this.m + 1;
            this.beginBackoffCol = 2;

            if (this.nInterarrival < 1 || this.pEnterInterarrival == 0)
                this.nInterarrival = 0;
                this.pEnterInterarrival = 0;
            end
            
            if (this.nPkt < 1)
                this.nPkt = 1;
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
