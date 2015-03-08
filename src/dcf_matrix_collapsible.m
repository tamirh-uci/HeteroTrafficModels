classdef dcf_matrix_collapsible < handle
    %DCF_MATRIX_COLLAPSIBLE Markov chain for DCF backoff simulation
    
    methods (Static)
        function key = Dim(type, indices)
            key = [int32(type) indices];
        end
        
        % there is only 1 success state, no need for indices
        % you enter the success state once you have successfully
        % transmitted a packet and need to know if you have another one
        % (and what size) you will attempt next
        function key = SuccessState()
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleSuccess, 0);
        end
        
        % the fail state for each stage goes to all of the backoff options
        % for the next stage
        % indices = [stage, packetsize]
        function key = FailState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleFailure, indices);
        end
        
        % initial transmit will distribute between stage 1 and postbackoff
        % indices = [packetsize]
        function key = InitialTransmitAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleInitialTransmit, indices);
        end
        
        % packetsize attempt means there was a packet in the buffer,
        % calculate the size of the packet
        % there is only 1 packetsize calculation (for stage 1)
        function key = PacketsizeCalculateAttemptState()
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsiblePacketSize, 0);
        end
        
        % each stage has a number of backoff states, which count down until
        % a packet will attempt to transmit
        % indices = [stage, packetsize, backoffTimer]
        function key = BackoffState(indices)
            assert( size(indices,1)==1 && size(indices,2)==3 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Backoff, indices);
        end
        
        % simulate the correct size of packet for the length we have chosen
        % at a previous point
        % indices = [stage, packetsize, chainTimer]
        function key = PacketsizeChainState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==3 ) );
            if ( indices(1,3) == 1 )
                key = dcf_matrix_collapsible.Dim(dcf_state_type.Transmit, indices);
            else
                key = dcf_matrix_collapsible.Dim(dcf_state_type.PacketSize, indices);
            end
        end
        
        % Where to hop into packetsize chain if you want to traverse it
        % indices = [stage, packetsize]
        function key = PacketsizeChainBeginState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==2 ) );
            key = dcf_matrix_collapsible.PacketsizeChainState([ indices(1,1), indices(1,2), indices(1,2) ]);
        end
        
        % Where to hop into packetsize chain if you want it over
        % indices = [stage, packetsize]
        function key = PacketsizeChainEndState(indices)
            assert( size(indices,1)==1 && ( size(indices,2)==2 ) );
            key = dcf_matrix_collapsible.PacketsizeChainState([ indices(1,1), indices(1,2), 1 ]);
        end
        
        % Determine outcome of a transmission, if it fails go to next stage
        % indices = [stage, packetsize]
        function key = TransmitAttemptState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleTransmit, indices);
        end
        
        % Distribute with even weight to backoff/transmit states in stage
        % indices = [stage, packetsize]
        function key = DistributionState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.CollapsibleDistribute, indices);
        end
        
        % calculate how long to wait until a new packet arrives in buffer
        % indices = [interarrivalTimer]
        function key = InterarrivalState(indices)
            assert( size(indices,1)==1 && size(indices,2)==1 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Interarrival, indices);
        end
        
        % indices = [packetsize, postbackoffLength]
        function key = PostbackoffState(indices)
            assert( size(indices,1)==1 && size(indices,2)==2 );
            key = dcf_matrix_collapsible.Dim(dcf_state_type.Postbackoff, indices);
        end
        
        % maps the new state types back onto the old simplified version
        % indices = [stage, packetsize, backoffTimer]
        function key = DCFState(indices)
            assert( size(indices,1)==1 && size(indices,2)==3 );
            if ( indices(1,3) == 1 )
                % backoff timer = 1 is now mapped to starting the
                % packetsize chain
                key = this.PacketsizeChainBeginState([ indices(1,1), indices(1,2) ]);
            else
                % all other are just backoff states, index fixed
                key = this.BackoffState([ indices(1,1), indices(1,2), indices(1,3)-1 ]);
            end
        end
    end % methods (Static)
    
    methods
        function obj = dcf_matrix_collapsible()
            obj = obj@handle;
        end
        
        function dcf = CreateMarkovChain(this, pSuccess, failureState, bVerbose)
            this.pRawSuccess = pSuccess;
            this.bFailureState = failureState;
            this.CalculateConstants();
            
            % Initialize the transition matrix
            dcf = markov_chain();
            
            % Create all of the states and set probabilities of transitions
            this.GenerateStates(dcf);
            this.SetProbabilities(dcf);
            
            if (bVerbose)
                dcf.PrintMapping();
                dcf.PrintAllTransitions();
            end
            
            % Remove temporary states
            dcf.Collapse();
            
            if (bVerbose)
                dcf.PrintMapping();
            end
            
            assert( dcf.Verify() );

        end %function CreateMatrix
        
        function GenerateStates(this, dcf)
            % all transmit success will go back to stage 1 for
            % redistribution of what happens next
            dcf.NewState( dcf_state( this.SuccessState(), dcf_state_type.CollapsibleSuccess ) );
            
            % packetsize and interarrival only happens after success -- it
            % will set the packetsize depth, so we only need one of these
            dcf.NewState( dcf_state(this.PacketsizeCalculateAttemptState(), dcf_state_type.CollapsiblePacketSize) );
            
            % interarival time 'calculation' states
            for k = 1:this.nInterarrival
                % # states = max interarrival wait time
                % jump randomly into any location in the chain
                % with p=1 traverse down the chain
                % when you reach the end, go back into the normal DCF
                dcf.NewState( dcf_state(this.InterarrivalState(k), dcf_state_type.Interarrival) );
            end
            
            assert( this.nPkt > 0 );
            for packetsize = this.packetStart:this.nPkt
                % where we make our 'initial' attempt to send calculations
                dcf.NewState( dcf_state( this.InitialTransmitAttemptState(packetsize), dcf_state_type.CollapsibleInitialTransmit ) );
                
                % one extra distribution state for last stage + 1
                % this will just loop back on the last stage
                dcf.NewState( dcf_state(this.DistributionState([this.nStages+1, packetsize]), dcf_state_type.CollapsibleDistribute) );
                
                for stage = 1:this.nStages
                    wCols = this.W(1, stage);

                    % collapsible distribution state for each stage
                    dcf.NewState( dcf_state(this.DistributionState([stage, packetsize]), dcf_state_type.CollapsibleDistribute) );
                    
                    % transmission attempt, after backoff and packetsize
                    % timers have finished
                    dcf.NewState( dcf_state(this.TransmitAttemptState([stage, packetsize]), dcf_state_type.CollapsibleTransmit) );

                    % packetsize chain
                    for chainIndex = 1:packetsize
                        key = this.PacketsizeChainState([stage, packetsize, chainIndex]);
                        if ( chainIndex == 1 )
                            dcf.NewState( dcf_state(key, dcf_state_type.Transmit) );
                        else
                            dcf.NewState( dcf_state(key, dcf_state_type.PacketSize) );
                        end
                    end

                    % backoff states (timer > 1)
                    nBackoff = wCols - 1;
                    for k = 1:nBackoff
                        key = this.BackoffState([stage, packetsize, k]);
                        dcf.NewState( dcf_state(key, dcf_state_type.Backoff) );
                    end
                end
                
                % Postbackoff is a single stage, mirroring the first stage (i = 1), 
                % and is indexed by timer value
                if (this.pRawArrive < 1.0)
                    for i = 1:this.W(1,1)
                       key = this.PostbackoffState([packetsize, i]);
                       dcf.NewState( dcf_state(key, dcf_state_type.Postbackoff) );
                    end
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
            
            this.SetPacketsizeCalculateProbabilities(dcf);
            
            % Initialize the probabilities from all transmission stages
            for packetsize = this.packetStart:this.nPkt
                % Handle backoff countdowns -- each one with probability 1-q
                % (a new packet does not arrive)
                if (this.pRawArrive < 1.0)
                    this.SetPostBackoffProbabilities(dcf, packetsize);
                end
                
                for stage = 1:this.nStages
                    % Initialize the probabilities from backoff stages to the transmission
                    % stage (all timers k > 1)
                    this.SetBackoffChainProbabilities(dcf, stage, packetsize);
                    
                    % We go into packetsize chain after backoff timer==1
                    this.SetPacketsizeChainProbabilities(dcf, stage, packetsize);

                    % We go into transmit attempt after packetsize chain
                    this.SetTransmitAttemptProbabilities(dcf, stage, packetsize);

                    % Going from failure state to backoff states of next stage
                    this.SetDistributionProbabilities(dcf, stage, packetsize);
                end
            end
        end % function SetProbabilities
        
        
        % Determine if we are going to wait on interarrival or send packet
        % If we are going to send packet, determine its size
        function SetSuccessProbabilities(this, dcf)
            src = this.SuccessState();
            
            % If we have no interarrival, we go straight to packetsize calc
            dst = this.PacketsizeCalculateAttemptState();
            dcf.SetP( src, dst, 1.0 - this.pEnterInterarrival, dcf_transition_type.Collapsible );
            
            % If we do have interarrival
            if (this.pEnterInterarrival > 0)
                assert( this.nInterarrival > 0 );
                
                if (this.bFixedInterarrivalChain)
                    % We are always going to the end of the chain
                    dst = this.InterarrivalState(this.nInterarrival);
                    dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
                else
                    % Equal probabilities to go to any state in the interarrival chain
                    pInterarrivalState = this.pEnterInterarrival / this.nInterarrival;
                    for k = 1:this.nInterarrival
                        dst = this.InterarrivalState(k);
                        dcf.SetP( src, dst, pInterarrivalState, dcf_transition_type.Collapsible );
                    end                    
                end
            end

        end % function SetSuccessProbabilities
        
        
        % Figure out which packetsize depth we are traveling to
        function SetPacketsizeCalculateProbabilities(this, dcf)
            % Equal chance to go to any packetsize depth
            % If bFixedPacketChain, we basically always go to the max depth
            src = this.PacketsizeCalculateAttemptState();
            range = 1 + this.nPkt - this.packetStart;
            p = 1.0 / range;
            
            % Every valid packetsize depth has a 'initial transmit attempt'
            for packetsize = this.packetStart:this.nPkt
                dst = this.InitialTransmitAttemptState(packetsize);
                dcf.SetP( src, dst, p, dcf_transition_type.Collapsible );
            end
            
            % redistribute our first attempt at a send
            src = this.InitialTransmitAttemptState(packetsize);
            for packetsize = this.packetStart:this.nPkt
                pDistNorm = this.pRawArrive;
                pDistPostbackoff = (1.0 - this.pRawArrive) / this.W(1,1);
                
                % If we have an arrival, we need to distribute over
                % backoff/transmit state of the 1st stage
                dst = this.DistributionState([1, packetsize]);
                dcf.SetP( src, dst, pDistNorm, dcf_transition_type.Collapsible );
                
                % If we don't have an arrival, we need to distribute over
                % the postbackoff states
                if (pDistPostbackoff > 0)
                    for k = 1:this.W(1,1)
                        dst = this.PostbackoffState([packetsize, k]);
                        dcf.SetP( src, dst, pDistPostbackoff, dcf_transition_type.Postbackoff );
                    end
                end
            end
        end % function SetPacketsizeCalculateProbabilities
        
        
        function SetPostBackoffProbabilities(this, dcf, packetsize)
            baseBackoffProbability = this.pRawArrive * (1 - this.pRawFail);
            
            for k = 2:this.W(1,1)
                src = this.PostbackoffState([packetsize, k]); % (1,k)_e

                postbackoffDst = this.PostbackoffState([packetsize, k - 1]); % (1, k-1)_e
                dcf.SetP( src, postbackoffDst, 1 - this.pRawArrive, dcf_transition_type.Postbackoff );

                backoffDst = this.DCFState([1, packetsize, k - 1]); % (1, k-1) -> normal DCF state
                dcf.SetP( src, backoffDst, this.pRawArrive, dcf_transition_type.Backoff );
            end

            %%% Handle backoff transitions from (0,0)_e === (1,1)_e
            %%% Source: Modelling the 802.11 Distributed Coordination Function with Heterogenous Finite Load

            % Case 1: loop
            postbackoffOrigin = this.PostbackoffState([packetsize, 1]);
            postbackoffOriginLoopProbability = 1 - this.pRawArrive + ((this.pRawArrive * (1 - this.pRawFail) * (1 - this.pRawFail)) / this.W(1,1));
            dcf.SetP( postbackoffOrigin, postbackoffOrigin, postbackoffOriginLoopProbability, dcf_transition_type.Postbackoff );

            % Case 2/4: Loop back to post backoff and real backoff
            for k = 1:this.W(1,1)
                
                if (k > 1) % case 2
                    postbackoffDst = this.PostbackoffState([packetsize, k]); % (1, k)_e
                    dcf.SetP( postbackoffOrigin, postbackoffDst, (baseBackoffProbability * (1 - this.pRawFail)) / this.W(1,1), dcf_transition_type.Postbackoff );
                end

                backoffDst = this.DCFState([1, packetsize, k]); % (1, k) -> normal DCF state
                dcf.SetP( postbackoffOrigin, backoffDst, (baseBackoffProbability * this.pRawFail) / this.W(1,1), dcf_transition_type.Backoff );
            end

            for k = 1:this.W(1,2)
                backoffFailDst = this.DCFState([2, packetsize, k]); % (2, k) -> normal DCF state
                dcf.SetP( postbackoffOrigin, backoffFailDst, baseBackoffProbability / this.W(1,2), dcf_transition_type.Backoff );
            end
        end % function GenerateBackofProbabilities
        
        
        function SetBackoffChainProbabilities(this, dcf, stage, packetsize)
            % number of backoff states in this stage
            nBackoff = this.W(1,stage) - 1;
            
            % Countdown of backoff chain
            for k = 2:nBackoff
                src = this.BackoffState([stage, packetsize, k]);
                dst = this.BackoffState([stage, packetsize, k-1]);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.Backoff );
            end
            
        end % function SetBackoffChainProbabilities
        
        
        function SetTransmitAttemptProbabilities(this, dcf, stage, packetsize)
            src = this.TransmitAttemptState([stage, packetsize]);
            
            % We have traversed the packetsize chain, see how likely it
            % was that we succeeded on all of the hops
            pAllSucceed = this.pRawSuccess ^ packetsize;
            pAnyPartFail = 1 - pAllSucceed;
            
            % Failure will distribute us along the next stage
            dst = this.DistributionState([stage+1, packetsize]);
            dcf.SetP( src, dst, pAnyPartFail, dcf_transition_type.TxFailure );
            
            % Success resets everything and we start all over
            dst = this.SuccessState();
            dcf.SetP( src, dst, pAllSucceed, dcf_transition_type.TxSuccess );
            
        end % function SetTransmitAttemptProbabilities
        
        
        function SetDistributionProbabilities(this, dcf, srcStage, packetsize)
            if (srcStage == this.nStages)
                % We need to add an extra state which extends to one stage
                % beyond our max, which will loop back to the max stage
                this.SetDistributionProbabilities(dcf, srcStage+1, packetsize);
            end
            
            % we need to loop back onto the max stage if we're beyond it
            if (srcStage <= this.nStages)
                dstStage = srcStage;
            else
                dstStage = this.nStages;
            end
            
            nCols = this.W(1, dstStage);
            nBackoff = nCols - 1;
            pDist = 1.0 / nCols;
            
            % Evenly distribute over all backoff stages
            src = this.DistributionState([srcStage, packetsize]);
            for k = 1:nBackoff
                dst = this.BackoffState([dstStage, packetsize, k]);
                dcf.SetP( src, dst, pDist, dcf_transition_type.Collapsible );
            end
            
            % Or we can go to the packetsize chain
            dst = this.PacketsizeChainState([dstStage, packetsize, packetsize]);
            dcf.SetP( src, dst, pDist, dcf_transition_type.Collapsible );
        end % function SetFailureProbabilities

        
        function SetPacketsizeChainProbabilities(this, dcf, stage, packetsize)
            % Since we're just marching down the packetsize chain, we need
            % a way to exit if we're being forced (multiple transmits) to
            % fail
            if (this.bFailureState)
                pContinueDownChain = 0;
                pGoToFailure = 1;
            else
                pContinueDownChain = 1;
                pGoToFailure = 0;
            end

            % At end of backoff chain, we go into packetsize calculation
            % We hop in at the end of the chain so it can countdown
            src = this.BackoffState([stage, packetsize, 1]);
            dst = this.PacketsizeChainBeginState([stage, packetsize]);
            dcf.SetP( src, dst, pContinueDownChain, dcf_transition_type.Backoff );
            
            % Or see if we go straight into failure state
            dst = this.DistributionState([stage+1, packetsize]);
            dcf.SetP( src, dst, pGoToFailure, dcf_transition_type.TxFailure );
            
            % Travel down the packetsize chain
            for k = 2:packetsize
                src = this.PacketsizeChainState([stage, packetsize, k]);
                dst = this.PacketsizeChainState([stage, packetsize, k-1]);
                dcf.SetP( src, dst, pContinueDownChain, dcf_transition_type.PacketSize );
                
                dst = this.DistributionState([stage+1, packetsize]);
                dcf.SetP( src, dst, pGoToFailure, dcf_transition_type.TxFailure );
            end
            
            % The last index of the packetsize chain will see if it
            % succeeded or not
            src = this.PacketsizeChainEndState([stage, packetsize]);
            dst = this.TransmitAttemptState([stage, packetsize]);
            dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );

        end % function GeneratePacketsizeStates
        
        
        function SetInterarrivalProbabilities(this, dcf)
            % Traveling down the interarrival chain (no chance of
            % failure because we're not really doing anything)
            for k = 2:this.nInterarrival
                src = this.InterarrivalState(k);
                dst = this.InterarrivalState(k-1);
                dcf.SetP( src, dst, 1.0, dcf_transition_type.Interarrival );
            end

            % At the last state in the chain, we will figure out the size
            % of the packet which just came in
            src = this.InterarrivalState(1);
            dst = this.PacketsizeCalculateAttemptState();
            dcf.SetP( src, dst, 1.0, dcf_transition_type.Collapsible );
        end % function GenerateInterarrivalStates
        
        % Calculate how long we need to wait between transmissions in order
        % to send the payload with a given bps at a given datarate
        function CalculateInterarrival(this, type, desiredBps, payloadSizeBits)
            % what rate would be be sending if we have 0 interarrival
            maxDatarate = phys80211.EffectiveMaxDatarate(type, payloadSizeBits, 1.0, this.wMin);
            
            % at what speed do we want to send to get our desired bps?
            percentTransmit = desiredBps / maxDatarate;
            
            % NOTE: This is just assuming transmit time == 1x backoff time
            % how many interarrival states should we make?
            this.nInterarrival = ceil( 1/percentTransmit );
        end
        
        function CalculateConstants(this)
            % Basic assumptions
            assert( this.pRawSuccess >= 0 && this.pRawSuccess <= 1 );
            assert( this.pRawArrive > 0 && this.pRawArrive <= 1 ); % arrival rate of 0 means absolutely no packets will be sent
            assert( this.pEnterInterarrival >= 0 && this.pEnterInterarrival <= 1 );
            assert( this.m >= 1 );
            assert( this.wMin >= 0 );
            assert( this.nPkt >= 0 );
            assert( this.nInterarrival >= 0 );
            
            % Compute some useful variables based on our input params
            this.pRawFail = 1 - this.pRawSuccess;
            this.nStages = this.m + 1;

            if (this.pEnterInterarrival < 0)
                this.pEnterInterarrival = 0;
            end
            
            % packetsize chain of 0 is just the regular model, the
            % equivilent of packetsize chain of 1
            if (this.nPkt < 1)
                this.nPkt = 1;
            end
            
            if (this.bFixedPacketchain)
                this.packetStart = this.nPkt;
            else
                this.packetStart = 1;
            end

            % Compute values for W -- how many backoff states there are
            % each stage
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
        pRawFail = 0.0;

        % number of stages
        m = 4;

        % minimum number of backoff states
        wMin = 2;

        % maximum size of packets
        % transmissions will be [1:nPkt] length
        nPkt = 1;

        % number of states in the interarrival chain, we will jump to one
        % randomly with probability pEnterInterarrival
        nInterarrival = 0;
        
        % probability to enter the interarrival chain, so probability there is
        % not a packet immediately ready to send
        pEnterInterarrival = 0.0;
        
        % probability a packet shows up when it's supposed to
        pRawArrive = 1.0;
        
        % do we always have the maximum packetchain length?
        % if false, we will randomly have a packetchain length of [0,nPkt]
        bFixedPacketchain = false;
        
        % do we always have the maximum interarrival length?
        % if false, we will randomly have a interarrival length of
        % [0,nInterarrival]
        bFixedInterarrivalChain = false;
        
        % are we in the state where everything should fail?
        bFailureState = false;
    end %properties (SetAccess = public)

    properties (SetAccess = protected)
        % W matrix which holds number of DCF states in each row
        W;
        
        % 1 - pRawFail
        pRawSuccess;
        
        % number of stages (rows) in the basic DCF matrix
        nStages;
        
        % maximum number of columns in any of the rows
        nColsMax;
        
        % The lower end of possibile packetsize
        packetStart;
    end %properties (SetAccess = protected)
end % classdef
