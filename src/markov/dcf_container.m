classdef dcf_container < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        % key: dimensioned index
        % value: handle to dcf_state object
        states@containers.Map = containers.Map('KeyType',int32, 'ValueType',dcf_state);   
    end
    
    methods
        % Return the probability of state->state transition (src->dst)
        % srcKey: dimensioned index
        % dstKey: dimensioned index
        function p = P(this, srcKey, dstKey)
            p = 0;
            
            if (this.states.isKey(srcKey) && this.states.isKey(dstKey))
                srcState = this.states(srcKey);
                
                if (srcState.P.isKey(dstKey))
                    p = srcState.P(dstKey);
                end
            end
        end
        
        % Set the probability of state->state transition (src->dst)
        % srcKey: dimensioned index
        % dstKey: dimensioned index
        % p: probability [0,1]
        function setP(this, srcKey, dstKey, p)
            assert(this.states.isKey(srcKey));
            
            srcState = this.states(srcKey);
            srcState.P(dstKey) = p;
        end
        
        % Flatten all of the states and give them a 1d index
        function flatten(this)
            % TODO: Sort this so it comes out in a logical order
            valueSet = values(this.states);
            nStates = size(valueSet,1);
            
            for i=1:nStates
                valueSet(i).IF = i;
            end
        end
        
        % Convert the states into a transition table
        function t = transitionTable(this)
            valueSet = values(this.states);
            nStates = size(valueSet, 1);
            t = zeros(nStates, nStates);
            
            % For all source states
            for i=1:nStates
                src = valueSet(i);
                dstSet = values(src.P);
                nDst = size(dstSet, 1);
                
                % For all destination states from this srouce
                for j=1:nDst
                    dst = dstSet(j);
                    
                    % Set the probability in the 2d transition table
                    t(src.IF, dst.IF) = src.P(dst);
                end
            end
        end
    end 
end