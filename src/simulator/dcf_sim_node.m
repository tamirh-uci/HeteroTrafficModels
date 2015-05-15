classdef dcf_sim_node < handle
    %DCF_SIM_NODE - Simulates a single node which will interact with other
    % nodes in a wireless transmission simulation. Nodes are simplified to
    % generate traffic of a single type
    
    properties
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
        hasSecondary;
        
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
        
        % Results
        simSize;
        cachedSuccessCount;
        cachedFailureCount;
        cachedWaitCount;
        cachedInvalidCount;
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
            Reset(obj);
            
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
            
            if (~isempty(secondaryChainBuilderIn))
                obj.hasSecondary = true;
                obj.secChainBuilder = secondaryChainBuilderIn;
                obj.secondaryEndStates = [dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            else
                obj.hasSecondary = false;
            end
            
            obj.txSuccessTypes = [dcf_transition_type.TxSuccess, dcf_transition_type.PacketSize, dcf_transition_type.TxIFrame, dcf_transition_type.TxBFrame, dcf_transition_type.TxPFrame];
            obj.txFailTypes = [dcf_transition_type.TxFailure];
            obj.txWaitTypes = [dcf_transition_type.Backoff, dcf_transition_type.Interarrival, dcf_transition_type.Postbackoff];
            obj.txInvalidTypes = [dcf_transition_type.Null, dcf_transition_type.Collapsible];
        end
        
        function Reset(this)
            this.dcfHist = markov_history();
            this.secHist = markov_history();
            
            this.cachedSuccessCount = -1;
            this.cachedFailureCount = -1;
            this.cachedWaitCount = -1;
            this.cachedInvalidCount = -1;
        end
        
        function GetResults(this, results, index)
            results.nodeSuccessCount(index) = this.cachedSuccessCount;
            results.nodeFailureCount(index) = this.cachedFailureCount;
            results.nodeWaitCount(index) = this.cachedWaitCount;
            results.nodeInvalidCount(index) = this.cachedInvalidCount;
            results.nodeDcfHistory{index} = this.dcfHist;
            results.nodeSecHistory{index} = this.secHist;
        end
        
        function PlotFigures(this, cache, figureId, displayFigures)
            fileThroughput = sprintf('%s.throughput.fig', cache);
            fileSuccess = sprintf('%s.success.fig', cache);
            fileFailure = sprintf('%s.failure.fig', cache);
            
            % TODO: Plot stuff
            fig = figure(figureId);
        end
        
        function SaveResults(this, cache, loadCache, saveCache)
            filename = sprintf('%s.results.mat', cache);
            successCount = [];
            failureCount = [];
            waitCount = [];
            invalidCount = [];
            isLoaded = loadCache;
            
            if (loadCache && exist(filename, 'file')==2)
                try
                    load(filename);
                catch err
                    err
                    isLoaded = false;
                end
                
                if (isempty(successCount))
                    isLoaded = false;
                end
                
                if (isempty(failureCount))
                    isLoaded = false;
                end
                
                if (isempty(waitCount))
                    isLoaded = false;
                end
                
                if (isempty(invalidCount))
                    isLoaded = false;
                end
            else
                isLoaded = false;
            end
            
            if (~isLoaded)
                successCount = this.CountSuccesses();
                failureCount = this.CountFailures();
                waitCount = this.CountWaits();
                invalidCount = this.CountInvalidStates();
            end
            
            this.cachedSuccessCount = successCount;
            this.cachedFailureCount = failureCount;
            this.cachedWaitCount = waitCount;
            this.cachedInvalidCount = invalidCount;
            if (saveCache)
                save(filename, 'successCount', 'failureCount', 'waitCount', 'invalidCount');
            end 
        end
        
        function Setup(this, cache, loadCache, saveCache, bVerbose)
            isLoaded = false;
            loadedFromCache = false;
            filename = sprintf('%s.setup.mat', cache);
            
            if (loadCache && exist(filename, 'file')==2)
                isLoaded = this.SetupFromCache(filename, bVerbose);
                loadedFromCache = isLoaded;
            end
            
            if (~isLoaded)
                this.SetupWithoutCache(bVerbose);
            end
            
            if (saveCache && ~loadedFromCache)
                this.SaveSetupCache(filename, bVerbose);
            end
        end
        
        function SaveSetupCache(this, cache, ~)
            simnode = this;
            assert( ~isempty(simnode) );
            save(cache, 'simnode');
        end
        
        function isLoaded = SetupFromCache(this, cache, ~)
            isLoaded = true;
            
            try
                load(cache, 'simnode');
            catch err
                err
                isLoaded = false;
            end
            
            if (isLoaded)
                if (~strcmp(this.name, simnode.name))
                    fprintf('WARN: You are trying to load data from a cache that has become out of date\n');
                    fprintf('WARN: Ignoring old cache\n');
                    isLoaded = false;
                else
                    % copy over all of the values
                    p = properties(this);
                    for i = 1:length(p)
                        this.(p{i}) = simnode.(p{i});
                    end
                end
            end
        end
        
        function SetupWithoutCache(this, bVerbose)
            this.dcfChainSingleTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessSingleTransmit, false, bVerbose);
            this.piSingleTransmit = dcf_sim_node.makepi(this.dcfHist, this.dcfChainSingleTx);
            this.simSize = size(this.piSingleTransmit, 2);

            this.dcfChainMultiTx = this.dcfChainBuilder.CreateMarkovChain(this.pSuccessMultiTransmit, true, bVerbose);
            this.piMultiTransmit = dcf_sim_node.makepi(this.dcfHist, this.dcfChainMultiTx);

            this.dcfHist.Setup(this.dcfChainSingleTx, this.piSingleTransmit, 0);

            if (this.hasSecondary)
                this.secChain = this.secChainBuilder.CreateMarkovChain(false);
                this.piSecondary = dcf_sim_node.makepi(this.secHist, this.secChain);                
                this.secHist.Setup(this.secChain, this.piSecondary, 1);
            end
        end
        
        function isLoaded = StepsFromCache(this, cache)
            dcf = [];
            sec = [];
            
            try
                load(cache, 'dcf', 'sec');
                isLoaded = true;
            catch err
                err
                isLoaded = false;
                return;
            end
            
            if (isLoaded && ~isempty(dcf) && ~isempty(dcf))
                this.dcfHist = dcf;
                this.secHist = sec;
            end
        end
        
        function SaveStepsToCache(this, cache)
            dcf = this.dcfHist;
            sec = this.secHist;
            
            assert( ~isempty(dcf) );
            assert( ~isempty(sec) );
            
            save(cache, 'dcf', 'sec');
        end
        
        function bTransmitting = IsTransmitting(this)
            bTransmitting = sum(this.dcfHist.CurrentTransition() == this.txSuccessTypes) > 0;
        end
        
        function Step(this)
            % find the next state, assumin we'll succeed
            this.dcfHist.Step(this.piSingleTransmit, false);
        end
        
        function ForceFailure(this)
            %assert(this.IsTransmitting());
            
            % find next state knowing we previously thought we successfully
            % transmitted, but now we want to force a failed state
            this.dcfHist.Step(this.piMultiTransmit, true);
        end
        
        function SetupSteps(this, nStepsTotal)
            this.dcfHist.SetupSteps(nStepsTotal);
            
            if (this.hasSecondary)
                this.secHist.SetupSteps(nStepsTotal);
            end
        end
        
        % After we know what state we've moved to, figure out if we have
        % anything else to do. If we're transmitting, we may need to
        % determine what exactly it is we're transmitting
        function PostStep(this, isTransmitting)            
            if (this.hasSecondary)
                % Step the secondary chain to get new frame type
                if (isTransmitting)
                    this.secHist.StepUntil(this.piSecondary, this.secondaryEndStates);
                end
                
                this.secHist.Log(isTransmitting);
            end
            
            % Keep track of every state transition
            this.dcfHist.Log(isTransmitting);
        end
        
        % We need to look for packetsize chains which failed
        % Then we need to propegate those failures backwards for the whole
        % chain
        function PostSimulationProcessing(this, bDoPacketchainBacktrack, bVerbose)
            this.dcfHist.PostSimulation(bDoPacketchainBacktrack, bVerbose);
            
            if (this.hasSecondary)
                this.secHist.PostSimulation(false, bVerbose);
            end
        end
        
        % An entire packet successfully transmitted
        function count = CountSuccesses(this)
            if (this.cachedSuccessCount < 0)
                this.cachedSuccessCount = this.dcfHist.CountTransitions(this.txSuccessTypes);
            end
            
            count = this.cachedSuccessCount;
        end
        
        % Something happened in a packet transmission and it will need
        % retransmission now
        function count = CountFailures(this)
            if (this.cachedFailureCount < 0)
                this.cachedFailureCount = this.dcfHist.CountTransitions(this.txFailTypes);
            end
            
            count = this.cachedFailureCount;
        end
        
        % Node is either waiting to transmit, or waiting for new data to
        % arrive so it can transmit eventually
        function count = CountWaits(this)
            if (this.cachedWaitCount < 0)
                this.cachedWaitCount = this.dcfHist.CountTransitions(this.txWaitTypes);
            end
            
            count = this.cachedWaitCount;
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
            if (this.cachedInvalidCount < 0)
                this.cachedInvalidCount = this.dcfHist.CountTransitions(this.txInvalidTypes);
            end
            
            count = this.cachedInvalidCount;
        end
    end % methods    
end % classdef dcf_sim_node
