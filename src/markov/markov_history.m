classdef markov_history < handle
    %MARKOV_HISTORY Keep track of position and history of markov chain
    
    properties
        % List of all possible state indices
        sampleIndices;

        % State index of previous time slot
        prevStateIndex;
        
        % State index for current time slot
        currentStateIndex;
        
        % Matrix indexed by [src,dst] of possible state->state transitions
        % index with int32(index), and result is dcf_transition_type
        txTypes;
        
        % Array of src indicies to state type
        % index with int32(index), and result is dcf_state_type
        stateTypes;
        
        % History of all previous states
        % (their index values from the transition table)
        % Appended at every step
        % type: int32 (index)
        indexHistory;
        
        % History of all previous state types
        % Created after all steps taken
        % type: dcf_state_type
        stateTypeHistory;
        
        % History of all state transitions from i->i+1
        % Created after all steps taken
        % type: dcf_transition_type
        transitionHistory;
        
        % History of how long each packet i took to successfully send
        packetWaitHistory;
        currentPacketIndex;
        
        % Number of completed steps taken and recorded
        nStepsTaken;
    end
    
    methods
        function obj = markov_history()
            obj = obj@handle;
        end
        
        function tx = CurrentTransition(this)
            tx = this.txTypes(this.prevStateIndex, this.currentStateIndex);
        end
        
        function Setup(this, markovModel, pi, startState)
            nValidStates = size(pi, 2);
            this.sampleIndices  = 1:nValidStates;
            
            if (startState > 0)
                startStateIndex = startState;
            else
                epsilon = 0.0001;
                steadyStateMaxRepeat = 10000;
                startStateIndex = markovModel.WeightedRandomState(epsilon, steadyStateMaxRepeat);
            end
            
            this.prevStateIndex = startStateIndex;
            this.currentStateIndex = startStateIndex;
        end
        
        function SetupSteps(this, nSteps)
            assert( size(this.indexHistory,2)==0 );
            this.indexHistory = zeros(1, nSteps);
            this.packetWaitHistory = zeros(1, nSteps);
            
            this.currentPacketIndex = 1;
            this.nStepsTaken = 0;
        end
        
        % Advance the markov chain until we hit a given state
        % endStates : Array of states to stop on, any other will result in
        % continued steps
        function StepUntil(this, pi, endTypes)
            maxSteps = 100000;
            
            step = 1;
            done = false;
            while (~done && step < maxSteps)
                Step(this, pi, false);
                
                step = step + 1;
                done = sum(this.CurrentTransition() == endTypes) > 0;
            end
        end
        
        % Advance one single state in the markov chain
        % pi : the transition table to use
        % bPrevAsCurrent=true : travel from previous state
        % bPrevAsCurrent=false: travel from current state (normal)
        function Step(this, pi, bPrevAsCurrent)
            assert(size(pi,2)==size(this.txTypes,2));
            
            % find the probability to go to all other states from this one
            if (bPrevAsCurrent)
                pCur = pi{this.prevStateIndex};
            else
                this.prevStateIndex = this.currentStateIndex;
                pCur = pi{this.currentStateIndex};
            end
            
            % choose one of the states randomly based on weights
            this.currentStateIndex = pCur.sample();
            %this.currentStateIndex = randsample(this.sampleIndices, 1, true, pCur);
        end
        
        function PostSimulation(this, bDoPacketchainBacktrack, bVerbose)
            this.CalculateStateHistory();
            this.CalculateTransitionHistory();
            
            if (bDoPacketchainBacktrack)
                this.PostSimulationPacketchainBacktrack(bVerbose);
            end
        end
        
        function PostSimulationPacketchainBacktrack(this, bVerbose)
            % Find packetsize chains by looking for packetsize states
            packetChainStates = find(this.stateTypeHistory == dcf_state_type.PacketSize);
            transmitStates = find(this.stateTypeHistory == dcf_state_type.Transmit);

            nTransitionHistory = size(this.transitionHistory, 2);
            nPacketchainStates = size(packetChainStates, 2);
            
            if (bVerbose)
                fprintf('%d packetchains found, backtracking...\n', nPacketchainStates);
            end
            
            if (nPacketchainStates == 0)
                return;
            end
            
            % We will get end of contiguous chains
            % Do this by looking at where we have packetsize states and
            % where the difference between indicies is > 1
            packetChainStates(nPacketchainStates+1) = -1;
            deltaPacketchains = diff(packetChainStates) - 1;
            beginChainIndex = packetChainStates(1);
            
            chainSuccess = true;
            for i = 1:nPacketchainStates
                index = packetChainStates(i);
                
                % any failure in the chain marks the entire chain as fail
                if (this.transitionHistory(index) == dcf_transition_type.TxFailure)
                    chainSuccess = false;
                end
                % progress until we hit the end of the current chain
                if (deltaPacketchains(i))
                    endChainIndex = index;
                    
                    % Check if the next state (should be transmit) failed
                    if (index+1 <= nTransitionHistory)
                        if (find(transmitStates == index+1))
                            if (this.transitionHistory(index+1) == dcf_transition_type.TxFailure)
                                chainSuccess = false;
                            end
                        end
                    end
                    
                    % we need to mark the entire chain as a failure
                    if (~chainSuccess)
                        for j = beginChainIndex:endChainIndex
                            this.transitionHistory(j) = dcf_transition_type.TxFailure;
                        end
                    end
                    
                    % setup for next chain
                    beginChainIndex = packetChainStates(i+1);
                    chainSuccess = true;
                else
                    % continue moving along the packetchain
                end
            end
        end
        
        function Log(this, isTransmitting)
            this.nStepsTaken = 1 + this.nStepsTaken;
            this.indexHistory( this.nStepsTaken ) = this.currentStateIndex;
            
            this.packetWaitHistory( this.currentPacketIndex ) = 1 + this.packetWaitHistory( this.currentPacketIndex );
            if (isTransmitting)
                this.currentPacketIndex = 1 + this.currentPacketIndex;
            end
        end
        
        function CalculateTransitionHistory(this)
            nTransitions = size(this.indexHistory,2) - 1;
            this.transitionHistory = zeros(1, nTransitions+1);
            
            for i=1:nTransitions
                this.transitionHistory(i) = this.txTypes( this.indexHistory(i), this.indexHistory(i+1) );
            end
            
            % put a dummy transition at the end just so it's easier to
            % index into with the same size as the other logs
            this.transitionHistory(nTransitions+1) = dcf_transition_type.Null;
        end
        
        function CalculateStateHistory(this)
            nStates = size(this.indexHistory,2);
            this.stateTypeHistory = zeros(1,nStates);
            this.stateTypeHistory = this.stateTypes( this.indexHistory );
        end

        function count = CountStateTypes(this, compareTypes)
            % For every state type, check if it's one of compareTypes
            count = 0;
            for i=1:size(compareTypes, 2)
                found = find( this.stateTypeHistory==compareTypes(i) );
                count = count + size(found,2);
            end
        end
        
        function count = CountTransitions(this, compareTypes)
            % For every transition type, check if it's one of compareTypes
            count = 0;
            for i=1:size(compareTypes, 2)
                found = find( this.transitionHistory==compareTypes(i) );
                count = count + size(found,2);
            end
        end
    end
end
