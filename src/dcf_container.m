classdef dcf_container < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        % key: dimensioned index as string
        % value: handle to dcf_state object
        S@containers.Map;
        
        % Current number of states held
        nStates@int32 = int32(0);
    end %properties
    
    methods
        % Default Empty Constructor for dcf_container
        function obj = dcf_container()
            obj = obj@handle();
            obj.S = containers.Map('KeyType', 'char', 'ValueType', 'any');
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
        
        % Return the type of the given state, for use in simulation
        % stateKey: dimensioned index
        function t = Type(this, stateKey)
            stateKey = dcf_state.MakeKey(stateKey);
            
            assert(this.S.isKey(stateKey));
            t = this.S(stateKey).Type;
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
            
            %fprintf('setting %s => %s to %f\n', srcKey, dstKey, p);
        end
        
        % Convert the states into a transition table
        function t = TransitionTable(this)
            srcStates = this.S.values();
            assert( size(srcStates,2)==this.nStates );
            
            t = zeros(this.nStates, this.nStates);
            
            % For all source states
            for i=1:this.nStates
                src = srcStates{i};
                dstKeys = src.P.keys();
                nDst = size(dstKeys, 2);
                
                % For all destination keys from this srouce
                for j=1:nDst
                    dstKey = dstKeys{j};
                    
                    % Find the actual state object
                    assert(this.S.isKey(dstKey));
                    dst = this.S(dstKey);
                    
                    % Set the probability in the 2d transition table
                    t(src.IF, dst.IF) = src.P(dstKey);
                    
                    %fprintf('keys: %s => %s, index: %d => %d, prob: %f\n', src.Key, dstKey, src.IF, dst.IF, src.P(dstKey));
                end
            end
        end
        
        % Generate the steady state matrix
        function m = SteadyState(this, threshold, maxIter)
            m = this.TransitionTable();
            
            diff = threshold;
            iter = 1;
            while(diff >= threshold && iter <= maxIter)
                mPrev = m;
                m = m * m;
                
                iter = iter + 1;
                diff = norm(mPrev - m);
            end
        end
        
        % Verify transitions are valid
        % Currently just sums up rows and checks to see if it's 1
        function valid = Verify(this)
            epsilonThreshold = 0.0001;
            valid = true;
            
            srcStates = this.S.values();
            assert( size(srcStates,2)==this.nStates );
            
            % For all source states
            for i=1:this.nStates
                src = srcStates{i};
                rowsum = sum( cell2mat(src.P.values()) );
                
                if ( src.Type == dcf_state_type.Null )
                    if ( abs(0-rowsum) > epsilonThreshold )
                        valid = false;
                    end
                else
                    if ( abs(1-rowsum) > epsilonThreshold )
                        valid = false;
                    end    
                end
            end
        end
        
    end %methods
end %classdef