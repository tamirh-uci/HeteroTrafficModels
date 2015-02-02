classdef dcf_container < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        % key: dimensioned index
        % value: handle to dcf_state object
        states@containers.Map = containers.Map();    
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
    end 
end