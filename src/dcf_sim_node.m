classdef dcf_sim_node < handle
    %DCF_SIM_NODE - Simulates a single node which will interact with other
    % nodes in a wireless transmission simulation. Nodes are simplified to
    % generate traffic of a single type
    
    properties
        % Main DCF chain which determines when a transmit occurs
        mainChain@markov_chain_node;
        
        % Human readable identifier for this node, only used in print/debug
        name@char;
        
        % Secondary Markov Chain which determines what kind of transmit
        % Advances to this chain only occur on transmission
        secondaryChain@markov_chain_node;
        markovSecondary;
        piSecondary;
        secondaryEndStates;
        
        % Successful transmission: when no other node is transmitting at the same time
        pSuccessSingleTransmit;
        piSingleTransmit;
        markovSingleTransmit;
        
        % Failed transmission: when at least one other node is transmitting at the same time
        pSuccessMultiTransmit;
        piMultiTransmit;
        markovMultiTransmit;

        
        % Array of states which we consider to be successful transmissions
        txSuccessTypes@dcf_transition_type;
        
        % Array of states which we consider to be failed transmissions
        txFailTypes@dcf_transition_type;
        
        % Array of states which we consider to be waiting periods
        txWaitTypes@dcf_transition_type;
        
        % Array of states which we should never see
        txInvalidTypes@dcf_transition_type;
    end
    
    methods
        function obj = dcf_sim_node(nameIn, dcfIn, secondaryChainIn, pSuccessSingleTransmitIn, pSuccessMultiTransmitIn)
            obj = obj@handle();
            obj.name = nameIn;
            obj.mainChain = markov_chain_node(dcfIn);
            
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
            
            if (~isempty(secondaryChainIn))
                obj.secondaryChain = markov_chain_node(secondaryChainIn);
                obj.secondaryEndStates = [dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            end
            
            obj.txSuccessTypes = [dcf_transition_type.TxSuccess, dcf_transition_type.PacketSize, dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            obj.txFailTypes = [dcf_transition_type.TxFailure];
            obj.txWaitTypes = [dcf_transition_type.Backoff, dcf_transition_type.Interarrival, dcf_transition_type.Postbackoff];
            obj.txInvalidTypes = [dcf_transition_type.Null, dcf_transition_type.Collapsible];
        end
        
        function Setup(this)
            this.markovSingleTransmit = this.mainChain.chain.CreateMarkovChain(this.pSuccessSingleTransmit);
            [this.piSingleTransmit, this.mainChain.txTypes, this.mainChain.stateTypes] = this.markovSingleTransmit.TransitionTable();
            
            this.markovMultiTransmit = this.mainChain.chain.CreateMarkovChain(this.pSuccessMultiTransmit);
            [this.piMultiTransmit, ~, ~] = this.markovMultiTransmit.TransitionTable();
            
            assert(size(this.piSingleTransmit, 2) == size(this.piMultiTransmit, 2));
            this.mainChain.Setup(this.markovSingleTransmit, this.piSingleTransmit);
            
            if (~isempty(this.secondaryChain))
                this.markovSecondary = this.secondaryChain.chain.CreateMarkovChain();
                [this.piSecondary, this.secondaryChain.txTypes, this.secondaryChain.stateTypes] = this.markovSecondary.TransitionTable();
                
                this.secondaryChain.Setup(this.markovSecondary, this.piSecondary);
            end
        end
        
        function bTransmitting = IsTransmitting(this)
            bTransmitting = ismember( this.mainChain.CurrentTransition(), this.txSuccessTypes );
        end
        
        function Step(this)
            % find the next state, assumin we'll succeed
            this.mainChain.Step(this.piSingleTransmit, false);
        end
        
        function ForceFailure(this)
            assert(this.IsTransmitting());
            
            % find next state knowing we previously thought we successfully
            % transmitted, but now we want to force a failed state
            this.mainChain.Step(this.piMultiTransmit, true);
        end
        
        % After we know what state we've moved to, figure out if we have
        % anything else to do. If we're transmitting, we may need to
        % determine what exactly it is we're transmitting
        function PostStep(this)
            if (~isempty(this.secondaryChain))
                % Keep track of secondary chain only when it needs to
                % change
                if (this.IsTransmitting())
                    this.secondaryChain.StepUntil(this.piSecondary, this.secondaryEndStates);
                    this.secondaryChain.Log();
                end
            end
            
            % Keep track of every state transition
            this.mainChain.Log();
        end
        
        % We need to look for packetsize chains which failed
        % Then we need to propegate those failures backwards for the whole
        % chain
        function PostSimulationProcessing(this, bDoPacketchainBacktrack)
            this.mainChain.PostSimulation(bDoPacketchainBacktrack);
        end
        
        % An entire packet successfully transmitted
        function count = CountSuccesses(this)
            count = this.mainChain.CountTransitions(this.txSuccessTypes);
        end
        
        % Something happened in a packet transmission and it will need
        % retransmission now
        function count = CountFailures(this)
            count = this.mainChain.CountTransitions(this.txFailTypes);
        end
        
        % Node is either waiting to transmit, or waiting for new data to
        % arrive so it can transmit eventually
        function count = CountWaits(this)
            count = this.mainChain.CountTransitions(this.txWaitTypes);
        end
        
        % This should always be zero
        function count = CountInvalidStates(this)
            count = this.mainChain.CountTransitions(this.txInvalidTypes);
        end
    end % methods    
end % classdef dcf_sim_node
