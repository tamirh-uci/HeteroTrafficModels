classdef markov_chain < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        % key: dimensioned index as string
        % value: handle to dcf_state object
        S@containers.Map;
        
        % Current number of states held (including collapsible)
        nTotalStates@int32 = int32(0);
        
        % Current number of states held (excluding collapsible)
        nValidStates@int32 = int32(0);
    end %properties
    
    methods
        % Default Empty Constructor for markov_chain
        function obj = markov_chain()
            obj = obj@handle();
            obj.S = containers.Map('KeyType', 'char', 'ValueType', 'any');
        end
        
        % Insert a new state into the set
        function NewState(this, state)
            this.nTotalStates = this.nTotalStates + 1;
            
            if (state.Type >= dcf_state_type.Collapsible)
                state.IF = int32(-1);
            else
                this.nValidStates = this.nValidStates + 1;
                state.IF = this.nValidStates;
            end
            
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
        function SetP(this, srcKey, dstKey, p, txLabel)
            srcKey = dcf_state.MakeKey(srcKey);
            dstKey = dcf_state.MakeKey(dstKey);
            
            assert(this.S.isKey(srcKey));
            assert(this.S.isKey(dstKey));
            
            %dst = this.S(dstKey);
            srcState = this.S(srcKey);
            srcState.P(dstKey) = p;
            srcState.TX(dstKey) = int32(txLabel);
            
            %fprintf('setting %s => %s to %f\n', srcKey, dstKey, p);
        end
        
        % Collapse all 'instant' states down and calculate the final state
        % probabilities
        function Collapse(this)
            nCollapsePasses = 0;
            while (this.HasUncollapsedStates() > 0 && nCollapsePasses < 16)
                % Make sure we don't infinite loop somehow
                nCollapsePasses = nCollapsePasses + 1;
                assert(nCollapsePasses < 16);
                
                % Look at all of the source states
                srcStates = this.S.values();
                for i=1:this.nTotalStates
                    src = srcStates{i};
                    
                    % For all dst states in the original src
                    dstKeys = src.P.keys();
                    nDst = size(dstKeys, 2);
                    for j=1:nDst
                        dstKey = dstKeys{j};
                        dst = this.S(dstKey);
                        
                        % Perform collapse pass on this state
                        if (dst.Type >= dcf_state_type.Collapsible)
                            % Our probability to go to collapsible state
                            pBase = src.P(dstKey);
                            
                            % The transition we are taking into the
                            % collapsible state
                            enterTransition = src.TX(dstKey);
                            
                            % For all states reachable from collapsible
                            dstFromCollapsibleKeys = dst.P.keys();
                            nDstFromCollapsible = size(dstFromCollapsibleKeys, 2);
                            for k=1:nDstFromCollapsible
                                dstFromCollapsibleKey = dstFromCollapsibleKeys{k};
                                
                                % multiply this probability out and add it
                                % to the original source probabilities to
                                % this current state
                                pCurrent = this.P(src.Key, dstFromCollapsibleKey);
                                pCurrent = pCurrent + (pBase * dst.P(dstFromCollapsibleKey));
                                
                                % Prioritize using enter transition
                                % otherwise, choose the non-collapsible
                                exitTransition = dst.TX(dstFromCollapsibleKey);
                                if (enterTransition < dcf_transition_type.Collapsible)
                                    transition = enterTransition;
                                else
                                    transition = exitTransition;
                                end
                                
                                this.SetP(src.Key, dstFromCollapsibleKey, pCurrent, transition);
                                
                                % We should end up with a 'real' transition
                                % if we're done collapsing
                                if (dst.Type < dcf_state_type.Collapsible)
                                    assert(transition < dcf_transition_type.Collapsible);
                                end
                            end
                            
                            % Remove the transition to this collapsible
                            % state because we have already 'traveled' it
                            src.P.remove(dstKey);
                            src.TX.remove(dstKey);
                        end
                    end
                end
            end
        end
        
        function nCollapsible = HasUncollapsedStates(this)
            nCollapsible = 0;
            
            % Look at all of the source states
            srcStates = this.S.values();
            assert(size(srcStates,2) == this.nTotalStates);
            for i=1:this.nTotalStates
                src = srcStates{i};
                
                % We only care about non-collapsible sources
                if (src.Type >= dcf_state_type.Collapsible)
                    continue;
                end
                
                % For all destination keys from this source
                dstKeys = src.P.keys();
                nDst = size(dstKeys, 2);
                for j=1:nDst
                    dstKey = dstKeys{j};
                    dst = this.S(dstKey);

                    % We only carea about collapsible destinations
                    if (dst.Type >= dcf_state_type.Collapsible)
                        % Must have non-zero probability of transition
                        if (src.P(dstKey) > 0)
                            % We have a non-collapsed transition still
                            nCollapsible = nCollapsible + 1;
                        end
                    end
                end
            end
        end
        
        % Print out the mapping from indicies to keys
        function PrintMapping(this)
            srcStates = this.S.values();
            assert( size(srcStates,2)==this.nTotalStates );
            
            mappings = cell(this.nValidStates, 1);
            
            % For all source states
            for i=1:this.nTotalStates
                src = srcStates{i};
                
                % Ignore collapsible states
                if (src.Type >= dcf_state_type.Collapsible)
                    continue; 
                end
                
                srcIndex = int32(src.IF);
                assert(srcIndex > 0);
                
                srcKey = ( eval(src.Key) );
                s = sprintf('%s\t(%s)\n', src.Key, char( dcf_state_type(srcKey(1)) ) );
                mappings{ srcIndex } = s;
            end
            
            % Print
            for i=1:this.nValidStates
                fprintf('KEY: %d\t = %s', i, mappings{i});
            end
        end
        
        % Print transitions from all source states to destination states
        % Include collapsible
        function PrintAllTransitions(this)
            srcStates = this.S.values();
            
            % For all source states
            for i=1:this.nTotalStates
                src = srcStates{i};
                
                dstKeys = src.P.keys();
                nDst = size(dstKeys, 2);
                
                fprintf('\nFrom: %s\n', src.Key);
                % For all destination keys from this source
                for j=1:nDst
                    dstKey = dstKeys{j};
                    type = char( dcf_transition_type( src.TX(dstKey) ) );
                    p = src.P(dstKey);
                    fprintf(' to: %s = %f (%s)\n', dstKey, p, type);
                end
            end
        end
        
        % Convert the states into a transition table
        % pi: transition probabilities
        % tx: transition labels
        % states: state types
        function [pi, tx, states] = TransitionTable(this)
            srcStates = this.S.values();
            assert( size(srcStates,2)==this.nTotalStates );
            
            pi = zeros(this.nValidStates, this.nValidStates);
            tx = zeros(this.nValidStates, this.nValidStates);
            states = zeros(1, this.nValidStates);
            
            % For all source states
            for i=1:this.nTotalStates
                src = srcStates{i};
                
                % Ignore collapsible states
                if (src.Type >= dcf_state_type.Collapsible)
                    continue; 
                end
                
                dstKeys = src.P.keys();
                nDst = size(dstKeys, 2);
                
                srcIndex = src.IF;
                assert(srcIndex > 0);
                
                states(srcIndex) = src.Type;
                
                % For all destination keys from this source
                for j=1:nDst
                    dstKey = dstKeys{j};
                    
                    % Find the actual state object
                    assert(this.S.isKey(dstKey));
                    dst = this.S(dstKey);
                
                    % Ignore collapsible states
                    if (dst.Type >= dcf_state_type.Collapsible)
                        continue;
                    end
                    
                    dstIndex = dst.IF;
                    assert(dstIndex > 0);
                    
                    % Set the probability in the 2d transition table
                    pi(srcIndex, dstIndex) = src.P(dstKey);
                    tx(srcIndex, dstIndex) = src.TX(dstKey);
                    
                    %fprintf('keys: %s => %s, index: %d => %d, prob: %f\n', src.Key, dstKey, src.IF, dst.IF, src.P(dstKey));
                end
            end
        end
        
        % Generate the steady state matrix and reduce down to vector
        function ss = SteadyState(this, threshold, maxIter)
            [m,~,~] = this.TransitionTable();
            
            diff = threshold;
            iter = 1;
            while(diff >= threshold && iter <= maxIter)
                mPrev = m;
                m = m * m;
                
                iter = iter + 1;
                diff = norm(mPrev - m);
            end
            
            % We only need a vector, one value for each state
            ss = m(1,:);
        end
        
        % Generate a vector which holds each state type
        function st = StateTypes(this)
            st = dcf_state_type.empty(0, this.nValidStates);
            
            % For all source states
            validIndex = 0;
            srcStates = this.S.values();
            for i=1:this.nTotalStates
                src = srcStates{i};
                
                if (src.Type >= dcf_state_type.Collapsible)
                    continue;
                end
                
                validIndex = validIndex + 1;
                st(validIndex) = src.Type;
            end
        end
        
        % Return a (1d) index to a state, weighted by the steady state
        % probability given by function SteadyState()
        function state = WeightedRandomState(this, threshold, maxIter)
            steady = this.SteadyState(threshold, maxIter);
            
            % All rows should be equal at this point, just take the 1st
            state = randsample(1:this.nValidStates, 1, true, steady);
        end

        % Verify transitions are valid
        % Currently just sums up rows and checks to see if it's 1
        function valid = Verify(this)
            epsilonThreshold = 0.0001;
            valid = true;
            
            srcStates = this.S.values();
            assert( size(srcStates,2)==this.nTotalStates );
            
            % Verify the raw state transition hash table
            % For all source states
            for i=1:this.nTotalStates
                src = srcStates{i};
                rowsum = sum( cell2mat(src.P.values()) );
                
                % We only care about real states
                if ( src.Type == dcf_state_type.Null || src.Type >= dcf_state_type.Collapsible )
                    continue;
                else
                    if ( abs(1-rowsum) > epsilonThreshold )
                        valid = false;
                    end
                end
            end
            
            % Verify the transition tables also
            % If conversion went without a hitch, this should yield the
            % same results as the above checks
            [pi, tx,~] = this.TransitionTable();
            
            assert(size(pi,1)==this.nValidStates);
            assert(size(pi,2)==this.nValidStates);
            assert(size(tx,1)==this.nValidStates);
            assert(size(tx,2)==this.nValidStates);
            
            for i=1:this.nValidStates
                % all row probabilities should sum to 1
                rowsum = sum( pi(i,:) );
                if ( abs(1-rowsum) > epsilonThreshold )
                    valid = false;
                end
            end
        end
        
    end %methods
end %classdef