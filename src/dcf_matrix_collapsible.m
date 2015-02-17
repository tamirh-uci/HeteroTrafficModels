classdef dcf_matrix_collapsible < handle
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        % there is only 1 success state, no need for indices
        function key = SuccessState()
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleSuccess, 0);
        end
        
        % the fail state for each stage goes to all of the backoff options
        % for the next stage
        % indices = [stage]
        function key = FailState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleFailure, indices);
        end
        
        % the transmit attempt state is when backoff is done for this stage
        % indices = [stage]
        function key = TransmitAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleTransmit, indices);
        end
        
        % packetsize attempt means there was a packet in the buffer,
        % calculate the size of the packet
        % indices = [stage]
        function key = PacketsizeAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsiblePacketSize, indices);
        end
        
        % interarrival attempt means there was no packet in the buffer
        % there is only 1 interarrival attempt state (for stage 1)
        function key = InterarrivalAttemptState()
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleInterarrival, 0);
        end
        
        % each stage as a number of backoff states, which count down until
        % a packet will attempt to transmit
        % indices = [stage, backoffTimer]
        function key = DCFState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            
            % backoffTimer==1 means a we are in the above TransmitAttempt state
            if (indices(1,2) == 1)
                key = dcf_matrix_collapsible.TransmitAttemptState( indices(1,1) );
            else
                key = dcf_matrix_collapsible.Dim(dcf_state_type.Backoff, indices);
            end
        end
        
        % calculate the size of the packet (failure at each step)
        % indices = [stage, packetSize]
        function key = PacketsizeSingleChainState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==2 ) );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PacketSize, indices);
        end
        
        % calculate the size of the packet (failure at the last stage)
        % indices = [stage, packetSize, chain timer]
        function key = PacketsizeMultiChainState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==3 ) );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.PacketSize, indices);
        end
        
        % calculate how long to wait until a new packet arrives in buffer
        % indices = [interarrivalTimer]
        function key = InterarrivalState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Interarrival, indices);
        end
        
        % indices = [stage, postbackoffLength]
        function key = PostbackoffState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Postbackoff, indices);
        end
    end
    
    methods
        function obj = dcf_matrix_collapsible()
            obj = obj@handle;
        end
        
        function [pi, dcf] = CreateMatrix(this, pFail)
            this.pRawFail = pFail;
            this.CalculateConstants();
            
            % Initialize the transition matrix
            dcf = dcf_container();
            
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
            dcf.NewState( dcf_state(this.InterarrivalAttemptState(), dcf_state_type.CollapsibleInterarrival) );
            
            % interarival time 'calculation' states
            for k = 1:this.nInterarrival
                % # states = max interarrival wait time
                % jump randomly into any location in the chain
                % with p=1 traverse down the chain
                % when you reach the end, go back into the normal DCF
                key = this.InterarrivalState(k);
                dcf.NewState( dcf_state(key, dcf_state_type.Interarrival) );
            end
            
            for i = 1:this.nStages
                wCols = this.W(1,i);

                % collapsible failure state for each stage
                dcf.NewState( dcf_state(this.FailState(i), dcf_state_type.CollapsibleFailure) );
                
                % collapsible packetsize states
                % these stand right before the chains
                dcf.NewState( dcf_state(this.PacketsizeAttemptState(i), dcf_state_type.CollapsiblePacketSize) );
                
                % backoff timer has reached 0
                dcf.NewState( dcf_state(this.DCFState([i, 1]), dcf_state_type.CollapsibleTransmit) );

                % packet size 'calculation' states
                if (this.bUseSingleChainPacketsize)
                    % # states = max packet size
                    % Jump into the chain at a random point
                    % At every state, test success vs. failure
                    % At last state, jump back into normal DCF
                    for k = 1:this.nPkt
                        if (k==1)
                            stateType = dcf_state_type.Transmit;
                        else
                            stateType = dcf_state_type.PacketSize;
                        end
                        
                        key = this.PacketsizeSingleChainState([i, k]);
                        dcf.NewState( dcf_state(key, stateType) );
                    end
                else
                    % # chains = max packet size
                    % sending packetsize=X gives X states in that chain
                    % Jump to tail of that chain, and with p=1 traverse
                    % When you reach the head of the chain, check
                    % probability that all of the slots should have
                    % succeeded
                    for k = 1:this.nPkt
                        if (k==1)
                            stateType = dcf_state_type.Transmit;
                        else
                            stateType = dcf_state_type.PacketSize;
                        end
                        
                        for j = 1:k
                            key = this.PacketsizeMultiChainState([i, k, j]);
                            dcf.NewState( dcf_state(key, stateType) );
                        end
                    end
                end
                
                % backoff states
                for k = this.beginBackoffCol:wCols
                    key = this.DCFState([i, k]);
                    dcf.NewState( dcf_state(key, dcf_state_type.Backoff) );
                end
            end
            
            % Postbackoff is a single stage, mirroring the first stage (i = 1), 
            % and is indexed by the stage and timer value
            if (this.pRawArrive < 1.0)
                for i = 1:this.W(1,1)
                   key = this.PostbackoffState([1, i]);
                   dcf.NewState( dcf_state(key, dcf_state_type.Postbackoff) );
                end
            end
        end % function GenerateStates
        
        
        function SetProbabilities(this, dcf)
            % what happens AFTER a packet has been succesfully sent
            this.SetSuccessProbabilities(dcf);
            
            % Interarrival states, for when we have nothing to send
            if (this.nInterarrival > 0)
                this.SetInterarrivalProbabilities(dcf);
            end
            
            % Handle backoff countdowns -- each one with probability 1-q
            % (a new packet does not arrive)
            if (this.pRawArrive < 1.0)
                this.SetPostBackoffProbabilities(dcf);
            end
            
            % Initialize the probabilities from all transmission stages
            for i = 1:this.nStages
                % number of backoff states in this stage
                wCols = this.W(1,i);
                
                % Initialize the probabilities from backoff stages to the transmission
                % stage (all timers k > 1)
                this.SetBackoffChainProbabilities(dcf, wCols, i);

                % Set what happens once we are done with our backoff chain
                % backoff timers where k == 1
                this.SetTransmitAttemptProbabilities(dcf, i);
                
                % Going from failure state to backoff states of next stage
                this.SetFailureProbabilities(dcf, i);
                
                % We have data to transmit -- go to packetsize chain
                if (this.bUseSingleChainPacketsize)
                    this.SetSingleChainPacketsizeProbabilities(dcf, i);
                else
                    this.SetMultichainPacketsizeProbabilities(dcf, i);
                end
            end
        end % function SetProbabilities
        
        function SetSuccessProbabilities(this, dcf)
            % CASE 2 (success)
            src = this.SuccessState();
            
            % If we did have a packet, we have equal probability to go to
            % each of the stage 1 backoff states
            pDistSuccess = this.pRawArrive / this.W(1,1);
            pDistPostbackoff = (1.0 - this.pRawArrive) / this.W(1,1);
            for k = 1:this.W(1,1)
                if (k == 1)
                    dst = this.TransmitAttemptState(k);
                    dcf.SetP( src, dst, pDistSuccess, dcf_transition_type.TxSuccess );
                else
                    dst = this.DCFState([1, k]);
                    dcf.SetP( src, dst, pDistSuccess, dcf_transition_type.TxSuccess );
                end
                
                if (pDistPostbackoff > 0)
                    dst = this.PostbackoffState([1, k]);
                    dcf.SetP( src, dst, pDistPostbackoff, dcf_transition_type.Postbackoff );
                end
            end
        end % function SetSuccessProbabilities
        
        
        function SetPostBackoffProbabilities(this, dcf)
            for k = 2:this.W(1,1)
                src = this.PostbackoffState([1, k]); % (1,k)_e

                postbackoffDst = this.PostbackoffState([1, k - 1]); % (1, k-1)_e
                dcf.SetP( src, postbackoffDst, 1 - this.pRawArrive, dcf_transition_type.Postbackoff );

                backoffDst = this.DCFState([1, k - 1]); % (1, k-1) -> normal DCF state
                dcf.SetP( src, backoffDst, this.pRawArrive, dcf_transition_type.Backoff );
            end

            %%% Handle backoff transitions from (0,0)_e === (1,1)_e
            %%% Source: Modelling the 802.11 Distributed Coordination Function with Heterogenous Finite Load

            % Case 1: loop
            postbackoffOrigin = this.PostbackoffState([1, 1]);
            postbackoffOriginLoopProbability = 1 - this.pRawArrive + ((this.pRawArrive * (1 - this.pRawFail) * (1 - this.pRawFail)) / this.W(1,1));
            dcf.SetP( postbackoffOrigin, postbackoffOrigin, postbackoffOriginLoopProbability, dcf_transition_type.Postbackoff );

            % Case 2/4: Loop back to post backoff and real backoff
            for k = 1:this.W(1,1)
                baseBackoffProbability = this.pRawArrive * (1 - this.pRawFail);
                if (k > 1) % case 2
                    postbackoffDst = this.PostbackoffState([1, k]); % (1, k)_e
                    dcf.SetP( postbackoffOrigin, postbackoffDst, (baseBackoffProbability * (1 - this.pRawFail)) / this.W(1,1), dcf_transition_type.Postbackoff );
                end

                backoffDst = this.DCFState([1, k]); % (1, k) -> normal DCF state
                dcf.SetP( postbackoffOrigin, backoffDst, (baseBackoffProbability * this.pRawFail) / this.W(1,1), dcf_transition_type.Backoff );
            end

            for k = 1:this.W(1,2)
                baseBackoffProbability = this.pRawArrive * (1 - this.pRawFail);
                backoffFailDst = this.DCFState([2, k]); % (2, k) -> normal DCF state
                dcf.SetP( postbackoffOrigin, backoffFailDst, baseBackoffProbability / this.W(1,2), dcf_transition_type.Backoff );
            end
        end % function GenerateBackofProbabilities
        
        
        function SetBackoffChainProbabilities(this, dcf, wCols, i)
            for k = this.beginBackoffCol:wCols
                src = this.DCFState([i, k]);
                dst = this.DCFState([i, k-1]);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.Backoff );
            end
        end % function SetBackoffChainProbabilities
        
        
        function SetTransmitAttemptProbabilities(this, dcf, i)
            src = this.TransmitAttemptState(i);
            if (i == 1)
                % If we're at stage 1, then we have to decide on interarrival
                dst = this.PacketsizeAttemptState(i);
                dcf.SetP( src, dst, 1.0 - this.pEnterInterarrival, dcf_transition_type.Collapsible );
                
                if (this.pEnterInterarrival > 0)
                    dst = this.InterarrivalAttemptState(i);
                    dcf.SetP( src, dst, this.pEnterInterarrival, dcf_transition_type.Collapsible );
                end
            else
                % If we're on any other stage, just go to packetsize
                dst = this.PacketsizeAttemptState(i);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
            end
        end % function SetTransmitAttemptProbabilities
        
        
        function SetFailureProbabilities(this, dcf, i)
            % Handle the last stage specially -- it loops on top of itself
            nextStage = this.nStages;
            if (i < this.nStages)
                nextStage = i + 1;
            end

            wColsNext = this.W(1, nextStage);
            pDistFail = 1.0 / wColsNext;
            src = this.FailState(i);
            
            for k = 1:wColsNext
                dst = this.DCFState([nextStage, k]);
                dcf.SetP( src, dst, pDistFail, dcf_transition_type.TxFailure );    
            end
        end % function SetFailureProbabilities
        
        
        function SetSingleChainPacketsizeProbabilities(this, dcf, i)
            % Equal probability to go to any packetsize
            pPacketState = 1.0 / this.nPkt;
            src = this.PacketsizeAttemptState(i);
            for k = 1:this.nPkt
                dst = this.PacketsizeSingleChainState([i, k]);
                
                if (k == 1)
                    dcf.SetP( src, dst, pPacketState, dcf_transition_type.TxSuccess );
                else
                    dcf.SetP( src, dst, pPacketState, dcf_transition_type.PacketSize );
                end
            end
            
            % With probability of success, we travel down the
            % packetsize chain (packetsize 1 has no chain to create)
            if (this.nPkt > 1)
                for k = 2:this.nPkt
                    src = this.PacketsizeSingleChainState([i, k]);
                    dst = this.PacketsizeSingleChainState([i, k-1]);
                    dcf.SetP( src, dst, this.pRawSuccess, dcf_transition_type.PacketSize );
                end
            end
            
            % At packetsize 1, we can finally go into a real succcess state
            src = this.PacketsizeSingleChainState([i, 1]);
            dcf.SetP( src, this.SuccessState(), this.pRawSuccess, dcf_transition_type.Collapsible );

            % All failures in the chain go straight to the fail state
            dst = this.FailState(i);
            for k = 1:this.nPkt
                src = this.PacketsizeSingleChainState([i, k]);
                dcf.SetP( src, dst, this.pRawFail, dcf_transition_type.Collapsible );
            end
        end % function GenerateSingleChainPacketsizeStates
        
        
        function SetMultichainPacketsizeProbabilities(this, dcf, i)
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
        
        
        function SetInterarrivalProbabilities(this, dcf)
            % Equal probabilities to go to any state in the chain
            pInterarrivalState = 1.0 / this.nInterarrival;
            src = this.InterarrivalAttemptState();
            for k = 1:this.nInterarrival
                dst = this.InterarrivalState(k);
                dcf.SetP( src, dst, pInterarrivalState, dcf_transition_type.Interarrival );
            end

            % Traveling down the interarrival chain (no chance of
            % failure because we're not really doing anything)
            for k = 1:this.nInterarrival-1
                src = this.InterarrivalState(k);
                dst = this.InterarrivalState(k+1);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.PacketSize );
            end

            % At the last state in the chain, we will attempt send
            % We now know there is a packet to send, so go straight to the
            % packetsize calculation state
            src = this.InterarrivalState(this.nInterarrival);
            dst = this.PacketsizeAttemptState(1);
            dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
        end % function GenerateInterarrivalStates
        
        
        function CalculateConstants(this)
            % Basic assumptions
            assert( this.pRawFail >= 0 && this.pRawFail <= 1 );
            assert( this.pRawArrive >= 0 && this.pRawArrive <= 1 );
            assert( this.pEnterInterarrival >= 0 && this.pEnterInterarrival <= 1 );
            assert( this.m >= 1 );
            assert( this.wMin >= 0 );
            assert( this.nPkt >= 0 );
            assert( this.nInterarrival >= 0 );
            
            % Compute some useful variables based on our input params
            this.pRawSuccess = 1 - this.pRawFail;
            this.nStages = this.m + 1;
            this.beginBackoffCol = 2;

            % If either interarrival variable tells us to turn it off, then
            % ensure both tell us to turn it off
            if (this.nInterarrival < 1 || this.pEnterInterarrival <= 0)
                this.nInterarrival = 0;
                this.pEnterInterarrival = 0;
            end
            
            % internally we treat 0 packetsize chains the same as 1
            % packetsize chains (since it takes over the DCF(1 1) state
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
        
        % probability a packet shows up when it's supposed to
        pRawArrive;
        
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
