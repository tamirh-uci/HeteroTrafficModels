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
        
        function Setup(this, bVerbose)
            %name = this.name

            this.markovSingleTransmit = this.mainChain.chain.CreateMarkovChain(this.pSuccessSingleTransmit, false, bVerbose);
            [this.piSingleTransmit, this.mainChain.txTypes, this.mainChain.stateTypes] = this.markovSingleTransmit.TransitionTable();
            %successTable = this.piSingleTransmit
            %txtypes = this.mainChain.txTypes
            %statetypes = this.mainChain.stateTypes
            fprintf('\n-----------\n');
            this.markovMultiTransmit = this.mainChain.chain.CreateMarkovChain(this.pSuccessMultiTransmit, true, bVerbose);
            [this.piMultiTransmit, ~, ~] = this.markovMultiTransmit.TransitionTable();
            %failureTable = this.piMultiTransmit
            
            this.mainChain.Setup(this.markovSingleTransmit, this.piSingleTransmit, 0);
            
            if (~isempty(this.secondaryChain))
                this.markovSecondary = this.secondaryChain.chain.CreateMarkovChain(false);
                [this.piSecondary, this.secondaryChain.txTypes, this.secondaryChain.stateTypes] = this.markovSecondary.TransitionTable();
                
                this.secondaryChain.Setup(this.markovSecondary, this.piSecondary, 1);
            end
        end
        
        function bTransmitting = IsTransmitting(this)
            bTransmitting = sum(this.mainChain.CurrentTransition() == this.txSuccessTypes) > 0;
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
                % Step the secondary chain to get new frame type
                if (this.IsTransmitting())
                    this.secondaryChain.StepUntil(this.piSecondary, this.secondaryEndStates);
                end
            end
            
            % Keep track of every state transition
            this.mainChain.Log();
            this.secondaryChain.Log();
        end
        
        % We need to look for packetsize chains which failed
        % Then we need to propegate those failures backwards for the whole
        % chain
        function PostSimulationProcessing(this, bDoPacketchainBacktrack, bVerbose)
            this.mainChain.PostSimulation(bDoPacketchainBacktrack, bVerbose);
            this.secondaryChain.PostSimulation(false, bVerbose);
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
        
        function success = GetSuccess(this)
            success = this.CountSuccesses()/(this.CountSuccesses()+this.CountFailures());
        end

        function transmit = GetTransmit(this, nSteps)
            transmit = this.CountSuccesses()/nSteps;
        end

        function failure = GetFailures(this)
            failure = this.CountFailures()/(this.CountSuccesses()+this.CountFailures());
        end
        
        % This should always be zero
        function count = CountInvalidStates(this)
            count = this.mainChain.CountTransitions(this.txInvalidTypes);
        end
    end % methods    
end % classdef dcf_sim_node
