classdef dcf_sim_node < handle
    %DCF_SIM_NODE - Simulates a single node which will interact with other
    % nodes in a wireless transmission simulation. Nodes are simplified to
    % generate traffic of a single type
    
    properties
        dcf@dcf_matrix_collapsible;
        
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
        
        % Successful transmission: when no other node is transmitting at the same time
        pSuccessSingleTransmit;
        piSingleTransmit;
        markovSingleTransmit;
        
        % Failed transmission: when at least one other node is transmitting at the same time
        pSuccessMultiTransmit;
        piMultiTransmit;
        markovMultiTransmit;
    end
    
    methods
        function obj = dcf_sim_node(dcfIn, pSuccessSingleTransmitIn, pSuccessMultiTransmitIn)
            obj = obj@handle();
            obj.dcf = dcfIn;
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
        end
        
        function Setup(this)
            this.markovSingleTransmit = this.dcf.CreateMarkovChain(this.pSuccessSingleTransmit);
            [this.piSingleTransmit, this.txTypes] = this.markovSingleTransmit.TransitionTable();
            
            this.markovMultiTransmit = this.dcf.CreateMarkovChain(this.pSuccessMultiTransmit);
            [this.piMultiTransmit, ~] = this.markovMultiTransmit.TransitionTable();
            
            assert(size(this.piSingleTransmit, 2) == size(this.piMultiTransmit, 2));
            
            nValidStates = size(this.piSingleTransmit, 2);
            this.sampleIndices  = 1:nValidStates;
            this.transitionCount = zeros(nValidStates, nValidStates);
            
            % Choose randomly based on weighted average of steady state
            startState = this.markovSingleTransmit.WeightedRandomState(0.0001, 1000);
            this.prevState = startState;
            this.currentState = startState;
        end
        
        function Step(this)
            this.prevState = this.currentState;
            
            % find the probability to go to all other states from this one
            pCur = this.piSingleTransmit(this.currentState, :);
            
            % choose one of the states randomly based on weights
            this.currentState = randsample(this.sampleIndices, 1, true, pCur);
        end
        
        function bTransmitting = IsTransmitting(this)
            bTransmitting = (this.currentState == dcf_state_type.Transmit);
        end
        
        function ForceFailure(this)
            assert(this.IsTransmitting());
            
            % find the probabilit to go to all other states given that we
            % know we have failed a transmission
            pCur = this.piMultiTransmit( this.prevState, :);
            
            % recalculate what our current state would be if we had
            % correctly transitioned into a fail state
            this.currentState = randsample(this.sampleIndices, 1, true, pCur);
        end
        
        function Log(this)
            this.transitionCount(this.prevState, this.currentState) = 1 + this.transitionCount(this.prevState,this.currentState);
        end
        
        function successes = CountSuccesses(this)
            successes = sum( this.transitionCount(this.txTypes == dcf_transition_type.TxSuccess) );
        end
        
        function failures = CountFailures(this)
            failures = sum( this.transitionCount(this.txTypes == dcf_transition_type.TxFailure) );
        end
        
        function waits = CountWaits(this)
            waits = sum( this.transitionCount(this.txTypes == dcf_transition_type.Backoff) );
        end
    end
    
end
