classdef markov_chain_node < handle
    %MARKOV_CHAIN_NODE Keep track of position and history of markov chain
    
    properties
        % The markov chain itself
        chain;
        
        % List of all possible state indices
        sampleIndices;

        % State index of previous time slot
        prevStateIndex;
        
        % State index for current time slot
        currentStateIndex;
        
        % Matrix indexed by [src,dst] of possible state->state transitions
        txTypes;
        
        % Array of src indicies to state type
        stateTypes;
        
        % Number of times we count each [src,dst] transition happen
        transitionCount;
        
        % History of all previous states
        % (their index values from the transition table)
        % Appended at every step
        indexHistory;
        
        % History of all previous state types
        % Created after all steps taken
        stateTypeHistory;
        
        % History of all state transitions from i->i+1
        % Created after all steps taken
        transitionHistory;
    end
    
    methods
        function obj = markov_chain_node(chainIn)
            obj = obj@handle;
            obj.chain = chainIn;
        end
        
        function tx = CurrentTransition(this)
            tx = this.txTypes(this.prevStateIndex, this.currentStateIndex);
        end
        
        function Setup(this, markovModel, pi)
            epsilon = 0.0001;
            steadyStateMaxRepeat = 10000;
            
            nValidStates = size(pi, 2);
            
            this.sampleIndices  = 1:nValidStates;
            this.transitionCount = zeros(nValidStates, nValidStates);
            
            startStateIndex = markovModel.WeightedRandomState(epsilon, steadyStateMaxRepeat);
            this.prevStateIndex = startStateIndex;
            this.currentStateIndex = startStateIndex;
        end
        
        function SetupSteps(this, nSteps)
            assert( size(this.indexHistory,2)==0 );
            this.indexHistory = zeros(1, nSteps);
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
                done = ismember( this.CurrentTransition(), endTypes );
            end
        end
        
        % Advance one single state in the markov chain
        % pi : the transition table to use
        % bPrevAsCurrent=true : travel from previous state
        % bPrevAsCurrent=false: travel from current state (normal)
        function Step(this, pi, bPrevAsCurrent)
            assert(size(pi,1)==size(this.txTypes,1));
            assert(size(pi,2)==size(this.txTypes,2));
            
            % find the probability to go to all other states from this one
            if (bPrevAsCurrent)
                pCur = pi(this.prevStateIndex, :);
            else
                this.prevStateIndex = this.currentStateIndex;
                pCur = pi(this.currentStateIndex, :);
            end
            
            % choose one of the states randomly based on weights
            this.currentStateIndex = randsample(this.sampleIndices, 1, true, pCur);
        end
        
        function PostSimulation(this)
            this.CalculateStateHistory();
            this.CalculateTransitionHistory();
            
            historySize = size(this.indexHistory, 2);
            prev = this.indexHistory(1);
            
            for i=2:historySize
                curr = this.indexHistory(i);
                this.transitionCount(prev, curr) = 1 + this.transitionCount(prev, curr);
                prev = curr;
            end
        end
        
        
        function Log(this)
            this.indexHistory( 1 + size(this.indexHistory, 2) ) = this.currentStateIndex;
        end
        
        function CalculateTransitionHistory(this)
            nTransitions = size(this.indexHistory,2) - 1;
            this.transitionHistory = zeros(1, nTransitions);
            
            for i=1:nTransitions
                this.transitionHistory(i) = this.txTypes( this.indexHistory(i), this.indexHistory(i+1) );
            end
        end
        
        function CalculateStateHistory(this)
            nStates = size(this.indexHistory,2);
            this.stateTypeHistory = zeros(1,nStates);
            for i=1:nStates
                this.stateTypeHistory(i) = this.stateTypes( this.indexHistory(i) );
            end
        end

        function count = CountTransitions(this, compareTypes)
            % For every transition type, check if it's one of compareTypes
            matching = ismember(this.txTypes, compareTypes);
            counts = matching .* this.transitionCount;
            count = sum( sum( counts ) );
        end
    end
end

