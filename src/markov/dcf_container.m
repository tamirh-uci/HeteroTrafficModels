classdef dcf_container < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        % key: dimensioned index as string
        % value: handle to dcf_state object
        S@containers.Map = containers.Map('KeyType', 'char', 'ValueType', 'any');
        
        % Current number of states held
        nStates@int32 = int32(0);
    end
    
    methods
        % Default Empty Constructor for dcf_container
        function obj = dcf_container()
            obj = obj@handle();
        end
        
        % Insert a new state into the set
        function NewState(this, state)
            this.nStates = this.nStates + 1;
            state.IF = this.nStates;
            
            % TODO: Do some analysis on the key so we know max dimensions
            this.S(state.Key) = state;
        end
        
        % Return the probability of state->state transition (src->dst)
        % srcKey: dimensioned index
        % dstKey: dimensioned index
        function p = P(this, srcKey, dstKey)
            srcKey = dcf_state.MakeKey(srcKey);
            dstKey = dcf_state.MakeKey(dstKey);
            
            p = 0;
            if (this.S.isKey(srcKey) && this.S.isKey(dstKey))
                srcState = this.S(srcKey);
                
                if (srcState.P.isKey(dstKey))
                    p = srcState.P(dstKey);
                end
            end
        end
        
        % Set the probability of state->state transition (src->dst)
        % srcKey: dimensioned index
        % dstKey: dimensioned index
        % p: probability from [0,1]
        function SetP(this, srcKey, dstKey, p)
            srcKey = dcf_state.MakeKey(srcKey);
            dstKey = dcf_state.MakeKey(dstKey);
            
            assert(this.S.isKey(srcKey));
            
            srcState = this.S(srcKey);
            srcState.P(dstKey) = p;
        end
        
        % Convert the states into a transition table
        function t = TransitionTable(this)
            valueSet = values(this.S);
            assert( size(valueSet,1)==this.nStates );
            
            t = zeros(this.nStates, this.nStates);
            
            % For all source states
            for i=1:this.nStates
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