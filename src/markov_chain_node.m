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
        
        % Number of times we count each [src,dst] transition happen
        transitionCount;
        
        % History of all previous states
        indexHistory;
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
        
        function Log(this)
            this.indexHistory( 1 + size(this.indexHistory, 2) ) = this.currentStateIndex;
            
            prevTC = this.transitionCount(this.prevStateIndex, this.currentStateIndex);
            this.transitionCount(this.prevStateIndex, this.currentStateIndex) = 1 + prevTC;
        end

        function count = CountTransitions(this, compareTypes)
            count = 0;
            nStates = size(this.txTypes,2);
            
            % For every transition type, check if it's one of compareTypes
            for src = 1:nStates
                for dst = 1:nStates
                    if ( ismember(this.txTypes(src,dst), compareTypes) )
                        count = count + this.transitionCount(src, dst);
                    end
                end
            end
        end
    end
end

