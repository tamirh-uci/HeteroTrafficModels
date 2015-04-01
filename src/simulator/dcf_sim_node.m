classdef dcf_sim_node < handle
    %DCF_SIM_NODE - Simulates a single node which will interact with other
    % nodes in a wireless transmission simulation. Nodes are simplified to
    % generate traffic of a single type
    
    properties
        % Human readable identifier for this node, only used in print/debug
        name@char;
        
        % Main DCF chain which determines when a transmit occurs
        dcfHist@markov_history;
        dcfChainBuilder@dcf_matrix_collapsible;
        dcfChainSingleTx@markov_chain;
        dcfChainMultiTx@markov_chain;
        
        % Secondary Markov Chain which determines what kind of transmit
        % Advances to this chain only occur on transmission
        secHist@markov_history;
        secChainBuilder@markov_video_frames;
        secChain@markov_chain;
        
        piSecondary;
        secondaryEndStates;
        
        % Successful transmission: when no other node is transmitting at the same time
        pSuccessSingleTransmit;
        piSingleTransmit;
        
        % Failed transmission: when at least one other node is transmitting at the same time
        pSuccessMultiTransmit;
        piMultiTransmit;

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
        function obj = dcf_sim_node(nameIn, dcfChainBuilderIn, secondaryChainBuilderIn, pSuccessSingleTransmitIn, pSuccessMultiTransmitIn)
            obj = obj@handle();
            obj.name = nameIn;
            
            obj.dcfChainBuilder = dcfChainBuilderIn;
            obj.dcfHist = markov_history();
            
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
            
            if (~isempty(secondaryChainBuilderIn))
                obj.secChainBuilder = secondaryChainBuilderIn;
                obj.secHist = markov_history();
                obj.secondaryEndStates = [dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            end
            
            obj.txSuccessTypes = [dcf_transition_type.TxSuccess, dcf_transition_type.PacketSize, dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            obj.txFailTypes = [dcf_transition_type.TxFailure];
            obj.txWaitTypes = [dcf_transition_type.Backoff, dcf_transition_type.Interarrival, dcf_transition_type.Postbackoff];
            obj.txInvalidTypes = [dcf_transition_type.Null, dcf_transition_type.Collapsible];
        end
        
        function b = HasSecondary(this)
            b = ~isempty(this.secChainBuilder);
        end
        
        function Setup(this, bVerbose)
            this.dcfChainSingleTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessSingleTransmit, false, bVerbose);
            [pi, this.dcfHist.txTypes, this.dcfHist.stateTypes] = this.dcfChainSingleTx.TransitionTable();
            
            this.piSingleTransmit = cell(1,size(pi,2));
            for i=1:size(pi,2)
                this.piSingleTransmit{i} = weighted_sample(pi(i,:));
            end
            
            this.dcfChainMultiTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessMultiTransmit, true, bVerbose);
            [pi, ~, ~] = this.dcfChainMultiTx.TransitionTable();
            this.piMultiTransmit = cell(1,size(pi,2));
            for i=1:size(pi,2)
                this.piMultiTransmit{i} = weighted_sample(pi(i,:));
            end
            
            this.dcfHist.Setup(this.dcfChainSingleTx, this.piSingleTransmit, 0);
            
            if (this.HasSecondary())
                this.secChain = this.secChainBuilder.CreateMarkovChain(false);
                [pi, this.secHist.txTypes, this.secHist.stateTypes] = this.secChain.TransitionTable();
                this.piSecondary = cell(1,size(pi,2));
                for i=1:size(pi,2)
                    this.piSecondary{i} = weighted_sample(pi(i,:));
                end
                
                this.secHist.Setup(this.secChain, this.piSecondary, 1);
            end
        end
        
        function bTransmitting = IsTransmitting(this)
            bTransmitting = sum(this.dcfHist.CurrentTransition() == this.txSuccessTypes) > 0;
        end
        
        function Step(this)
            % find the next state, assumin we'll succeed
            this.dcfHist.Step(this.piSingleTransmit, false);
        end
        
        function ForceFailure(this)
            assert(this.IsTransmitting());
            
            % find next state knowing we previously thought we successfully
            % transmitted, but now we want to force a failed state
            this.dcfHist.Step(this.piMultiTransmit, true);
        end
        
        function SetupSteps(this, nStepsTotal)
            this.dcfHist.SetupSteps(nStepsTotal);
            
            if (this.HasSecondary())
                this.secHist.SetupSteps(nStepsTotal);
            end
        end
        
        % After we know what state we've moved to, figure out if we have
        % anything else to do. If we're transmitting, we may need to
        % determine what exactly it is we're transmitting
        function PostStep(this)
            if (this.HasSecondary())
                % Step the secondary chain to get new frame type
                if (this.IsTransmitting())
                    this.secHist.StepUntil(this.piSecondary, this.secondaryEndStates);
                end
                
                this.secHist.Log();
            end
            
            % Keep track of every state transition
            this.dcfHist.Log();
        end
        
        % We need to look for packetsize chains which failed
        % Then we need to propegate those failures backwards for the whole
        % chain
        function PostSimulationProcessing(this, bDoPacketchainBacktrack, bVerbose)
            this.dcfHist.PostSimulation(bDoPacketchainBacktrack, bVerbose);
            
            if (this.HasSecondary())
                this.secHist.PostSimulation(false, bVerbose);
            end
        end
        
        % An entire packet successfully transmitted
        function count = CountSuccesses(this)
            count = this.dcfHist.CountTransitions(this.txSuccessTypes);
        end
        
        % Something happened in a packet transmission and it will need
        % retransmission now
        function count = CountFailures(this)
            count = this.dcfHist.CountTransitions(this.txFailTypes);
        end
        
        % Node is either waiting to transmit, or waiting for new data to
        % arrive so it can transmit eventually
        function count = CountWaits(this)
            count = this.dcfHist.CountTransitions(this.txWaitTypes);
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
            count = this.dcfHist.CountTransitions(this.txInvalidTypes);
        end
    end % methods    
end % classdef dcf_sim_node
