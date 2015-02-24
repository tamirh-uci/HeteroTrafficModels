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
        
        function Step(this, pi, bPrevAsCurrent)
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

