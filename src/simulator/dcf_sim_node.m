classdef dcf_sim_node < handle
    %DCF_SIM_NODE - Simulates a single node which will interact with other
    % nodes in a wireless transmission simulation. Nodes are simplified to
    % generate traffic of a single type
    
    properties
        VERSION = '1.0';
        
        % Human readable identifier for this node, only used in print/debug
        name@char;
        
        % Main DCF chain which determines when a transmit occurs
        dcfHist@markov_history;
        dcfChainBuilder@dcf_markov_model;
        dcfChainSingleTx@markov_chain;
        dcfChainMultiTx@markov_chain;
        
        % Secondary Markov Chain which determines what kind of transmit
        % Advances to this chain only occur on transmission
        % Interface is fairly generic, doesn't have to be mpeg4
        secHist@markov_history;
        secChainBuilder@mpeg4_frame_model;
        secChain@markov_chain;
        
        % Secondary chain which activates only between the endstates
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
    
    methods (Static)
        function pi = makepi(hist, chain)
            [rawPI, hist.txTypes, hist.stateTypes] = chain.TransitionTable();
            
            nStates = size(rawPI, 2);
            pi = cell(1, nStates);
            for i = 1:nStates
                pi{i} = weighted_sample( rawPI(i,:) );
            end
        end
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
        
        function fName = MakeCacheFilename(this)
            pPart = [ num2str(this.pSuccessSingleTransmit) num2str(this.pSuccessMultiTransmit) ];
            dcfPart = [this.dcfHist.MakeCacheFilename() this.dcfChainBuilder.MakeCacheFilename()];
            
            if(this.HasSecondary())
                secPart = [this.secHist.MakeCacheFilename() this.secChainBuilder.MakeCacheFilename()];
            else
                secPart = 'nosec';
            end
            
            longName = [this.name pPart dcfPart secPart];
            
            % hash to get a reasonable sized string
            hash = string2hash(longName);
            fName = ['./../cache/' num2str(hash, '%X')];
        end
        
        function setupComplete = SetupFromCache(this)
            setupComplete = false;
            
            fName = this.MakeCacheFilename();
            if (exist(fName, 'file') == 2)
                % Do loading here
                setupComplete = false;
            end
        end
        
        function SaveToCache(~)
            %fName = this.MakeCacheFilename();
            % Do saving here
        end
        
        function Setup(this, bVerbose)
            % Attempt to load from cache, if it fails then compute chains
            if (~this.SetupFromCache())
                this.dcfChainSingleTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessSingleTransmit, false, bVerbose);
                this.piSingleTransmit = dcf_sim_node.makepi(this.dcfHist, this.dcfChainSingleTx);

                this.dcfChainMultiTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessMultiTransmit, true, bVerbose);
                this.piMultiTransmit = dcf_sim_node.makepi(this.dcfHist, this.dcfChainMultiTx);

                this.dcfHist.Setup(this.dcfChainSingleTx, this.piSingleTransmit, 0);

                if (this.HasSecondary())
                    this.secChain = this.secChainBuilder.CreateMarkovChain(false);
                    this.piSecondary = dcf_sim_node.makepi(this.secHist, this.secChain);                
                    this.secHist.Setup(this.secChain, this.piSecondary, 1);
                end

                this.SaveToCache();
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
