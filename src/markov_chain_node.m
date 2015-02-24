classdef markov_chain_node < handle
    %MARKOV_CHAIN_NODE Keep track of position and history of markov chain
    
    properties
        % The markov chain itself
        chain;
        
        % List of all possible state indices
        sampleIndices;

        % State index of previous time slot
        prevState;
        
        % State index for current time slot
        currentState;
        
        % Matrix indexed by [src,dst] of possible state->state transitions
        txTypes;
        
        % Number of times we count each [src,dst] transition happen
        transitionCount;
        
        % History of all previous states
        history;
    end
    
    methods
        function obj = markov_chain_node(chainIn)
            obj = obj@handle;
            obj.chain = chainIn;
        end
        
        function Setup(this, markovModel, pi)
            epsilon = 0.0001;
            steadyStateMaxRepeat = 10000;
            
            nValidStates = size(pi, 2);
            
            this.sampleIndices  = 1:nValidStates;
            this.transitionCount = zeros(nValidStates, nValidStates);
            
            startState = markovModel.WeightedRandomState(epsilon, steadyStateMaxRepeat);
            this.prevState = startState;
            this.currentState = startState;
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
                done = ismember( this.txTypes(this.prevState, this.currentState), endTypes );
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
                pCur = pi(this.prevState, :);
            else
                this.prevState = this.currentState;
                pCur = pi(this.currentState, :);
            end
            
            % choose one of the states randomly based on weights
            this.currentState = randsample(this.sampleIndices, 1, true, pCur);
        end
        
        function Log(this)
            this.history( 1 + size(this.history, 2) ) = this.currentState;
            
            prevTC = this.transitionCount(this.prevState, this.currentState);
            this.transitionCount(this.prevState, this.currentState) = 1 + prevTC;
        end

        function count = CountTransitions(this, compareTypes)
            count = sum( this.transitionCount(ismember(this.txTypes, compareTypes)) );
        end
    end
end

