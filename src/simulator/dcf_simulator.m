classdef dcf_simulator < handle
    %DCF Simulator using OO classes
    
    properties (SetAccess = protected)
        % Probability of success when one node transmits
        pSuccessSingleTransmit = 1.0;
        
        % Probability of success when >1 node transmits
        pSuccessMultiTransmit = 0.0;
        
        % Do we look for failures in packetchains and then backtrack to
        % mark all previous states in that chain a failure?
        bDoPacketchainBacktrack = true;
        
        % What is the precision of our indexing into random indices
        piPrecision = 32768;
        
        % simulation nodes
        nodes;
        simSize;
        
        % Boolean array which switches on/off depending on if a node is
        % currently transmitting
        transmittingNodes;
        
        % Count number of steps taken
        nSteps;
        
        % How is our channel defined
        physical_type;
        physical_payload;
        physical_speed;
        
        % Cache overall data
        cachedSuccess;
        cachedFailure;
        cachedWait;
        cachedInvalid;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator(params)
            obj = obj@handle();
            
            obj.pSuccessSingleTransmit = params.pSingleSuccess;
            obj.pSuccessMultiTransmit = params.pMultiSuccess;
            obj.physical_type = params.physical_type;
            obj.physical_payload = params.physical_payload;
            obj.physical_speed = params.physical_speed;
            obj.piPrecision = params.piPrecision;
            
            obj.cachedSuccess = -1;
            obj.cachedFailure = -1;
            obj.cachedWait = -1;
            obj.cachedInvalid = -1;

            if (obj.pSuccessMultiTransmit > 0.5)
                fprintf('Are you sure you wanted the chance of success with multiple nodes transmitting at the SAME TIME to be so high?\n');
                fprintf('In other words, pSuccessMultiTransmit is the chance of SUCCESS with multiple transmits (usually its zero)\n');
                %assert(obj.pSuccessMultiTransmit < 0.9);
            end
        end
        
        function add_plain_node(this, name, sleepProps, dcf_model)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(name, sleepProps, dcf_model, [], this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        function add_video_node(this, name, sleepProps, dcf_model, video_model)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(name, sleepProps, dcf_model, video_model, this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        function filename = NodeFilename(~, cachePrefix, index)
            filename = sprintf('%s.node-%d', cachePrefix, index);
        end
        
        function Reset(this)
            nNodes = size(this.nodes, 2);
            this.nSteps = 0;
            this.cachedSuccess = -1;
            this.cachedFailure = -1;
            this.cachedWait = -1;
            this.cachedInvalid = -1;
            
            % Setup node data
            for i=1:nNodes
                node = this.nodes{i};
                node.Reset();
            end
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this, cachePrefix, loadCache, saveCache, bVerbose)
            nNodes = size(this.nodes, 2);
            this.nSteps = 0;
            this.simSize = zeros(1, nNodes);
            
            % Setup node data
            for i=1:nNodes
                node = this.nodes{i};
                filename = this.NodeFilename(cachePrefix, i);
                node.Setup(filename, loadCache, saveCache, this.piPrecision, bVerbose);
                this.simSize(i) = node.simSize;
            end
            
            this.LoadCachedRunData(cachePrefix);
        end
        
        % Simulate multipler timer transitions for all nodes
        function Steps(this, nStepsTotal, cachePrefix, loadCache, saveCache, bVerbose)
            assert(this.nSteps == 0);
            
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                node.SetupSteps(nStepsTotal);
            end
            
            isLoaded = false;
            loadedFromCache = false;
            if (loadCache)
                isLoaded = this.StepsFromCache(cachePrefix);
                loadedFromCache = isLoaded;
            end
            
            if (~isLoaded)
                this.StepsWithoutCache(nStepsTotal, bVerbose);
            end
            
            if (saveCache && ~loadedFromCache)
                this.SaveStepsToCache(cachePrefix);
            end
        end
        
        function PostSimulationProcessing(this, bVerbose)
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                node.PostSimulationProcessing(this.bDoPacketchainBacktrack, bVerbose);
            end
        end
        
        function nodecache = NodeCacheName(~, cache, i)
            nodecache = sprintf('%s.node-%d.steps.mat', cache, i);
        end
        
        function isLoaded = StepsFromCache(this, cachePrefix)
            nNodes = size(this.nodes, 2);
            nodecache = cell(1, nNodes);
            isLoaded = false;

            % Check if all node cache files exist
            canLoad = true;
            for i=1:nNodes
                nodecache{i} = this.NodeCacheName(cachePrefix, i);
                if ( exist(nodecache{i}, 'file')~=2 )
                    canLoad = false;
                    break;
                end
            end
            
            % Attempt to load node cache files
            nodesLoaded = 0;
            if (canLoad)
                for i=1:nNodes
                    node = this.nodes{i};
                    if (~node.StepsFromCache( nodecache{i} ))
                        break;
                    end
                    
                    nodesLoaded = 1 + nodesLoaded;
                end
                
                % It's all or nothing for loading the history data
                if ( nodesLoaded < nNodes )
                    for i=1:nNodes
                        node = this.nodes{i};
                        node.Reset();
                    end
                else
                    isLoaded = true;
                end
            end
        end
        
        function SaveStepsToCache(this, cachePrefix)
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                node.SaveStepsToCache( this.NodeCacheName(cachePrefix, i) );
            end
        end
        
        function StepsWithoutCache(this, nStepsTotal, bVerbose)
            for i=1:nStepsTotal
                this.Step();
            end
            
            this.PostSimulationProcessing(bVerbose);
        end

        % Simulate single timer transition for all nodes
        function Step(this)
            nNodes = size(this.nodes, 2);
            this.nSteps = this.nSteps + 1;
            
            % Step each node forward in time
            for i=1:nNodes
                node = this.nodes{i};
                node.Step();
                this.transmittingNodes(i) = node.IsTransmitting();
            end
            
            % Handle multiple nodes trying to transmit at once
            nTransmitting = sum(this.transmittingNodes);
            if (nTransmitting > 1)
                % Force all of these into failure states by using the
                % transition table for when there are 100% failures
                for i = find(this.transmittingNodes)
                    node = this.nodes{i};
                    node.ForceFailure();
                    
                    % TODO: Verify this works (when a double transmitting node
                    % succeeds for instance            
                    this.transmittingNodes(i) = node.IsTransmitting();
                end
            end
            
            % Node may have some work to do after the finalized state has
            % been reached (logging, or transmission type steps)
            for i=1:nNodes
                node = this.nodes{i};
                node.PostStep(this.transmittingNodes(i));
            end
        end
        
        function SaveResults(this, cachePrefix, loadCache, saveCache)
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                filename = this.NodeFilename(cachePrefix, i);
                node.SaveResults(filename, loadCache, saveCache);
            end
            
            % Save overall results
            this.SaveCachedRunData(cachePrefix);
        end
        
        function LoadCachedRunData(this, prefix)
            filename = sprintf('%s.results.mat', prefix);
            if ( exist(filename, 'file')~=2 )
                return;
            end
            
            success = [];
            failure = [];
            wait = [];
            invalid = [];
            
            load(filename);
            
            if ( ~isempty(success) )
                this.cachedSuccess = success;
            end
            
            if ( ~isempty(failure) )
                this.cachedFailure = failure;
            end
            
            if ( ~isempty(wait) )
                this.cachedWait = wait;
            end
            
            if ( ~isempty(invalid) )
                this.cachedInvalid = invalid;
            end
        end
        
        function SaveCachedRunData(this, prefix)
            filename = sprintf('%s.results.mat', prefix);
            
            success = this.CountSuccesses();
            failure = this.CountFailures();
            wait = this.CountWaits();
            invalid = this.CountInvalid();
            
            assert( ~isempty(success) );
            assert( ~isempty(failure) );
            assert( ~isempty(wait) );
            assert( ~isempty(invalid) );
            
            save(filename, 'success', 'failure', 'wait', 'invalid');
        end
        
        function results = GetResults(this, variation)
            results = simulation_run_results();
            results.variation = variation;
            results.nSteps = this.nSteps;
            
            results.simSuccessCount = this.cachedSuccess;
            results.simFailureCount = this.cachedFailure;
            results.simWaitCount = this.cachedWait;
            results.simInvalidCount = this.cachedInvalid;
            
            results.nNodes = size(this.nodes, 2);
            results.nodeSuccessCount = zeros(1, results.nNodes);
            results.nodeFailureCount = zeros(1, results.nNodes);
            results.nodeWaitCount = zeros(1, results.nNodes);
            results.nodeInvalidCount = zeros(1, results.nNodes);
            
            results.nodeDcfHistory = cell(1, results.nNodes);
            results.nodeSecHistory = cell(1, results.nNodes);
            
            for i=1:results.nNodes
                node = this.nodes{i};
                node.GetResults(results, i);
            end
        end
        
        % Print out some useful information about this run
        function PrintResults(this, bVerbose)
            fprintf('===Node Results===\n');
            nNodes = size(this.nodes, 2);
            totalSuccess = 0;
            totalFail = 0;
            totalPackets = 0;
            totalPacketWaitHistory = [];
            
            for i=1:nNodes
                node = this.nodes{i};
                nSuccess = node.CountSuccesses();
                nFail = node.CountFailures();
                
                nPackets = node.dcfHist.currentPacketIndex;
                waitHistory = node.dcfHist.packetWaitHistory(1:nPackets);
                
                fprintf(' +%s+\n', node.name);
                this.PrintTransmitStats(nSuccess, nFail);
                this.PrintPacketStats(nPackets, waitHistory);

                totalSuccess = totalSuccess + nSuccess;
                totalFail = totalFail + nFail;
                totalPackets = totalPackets + nPackets;
                totalPacketWaitHistory = [totalPacketWaitHistory waitHistory];
                
                fprintf('\n');
                if (bVerbose)
                    transitionHistory = dcf_transition_type( node.mainChain.transitionHistory )
                    stateTypeHistory = dcf_state_type( node.mainChain.stateTypeHistory )
                end
            end

            assert(totalSuccess == this.CountSuccesses());
            assert(totalFail == this.CountFailures());
            
            fprintf('\n===Overall===\n');
            this.PrintTransmitStats(this.CountSuccesses(), this.CountFailures());
            this.PrintPacketStats(totalPackets, totalPacketWaitHistory);
        end
        
        function PrintPacketStats(this, nPacketsSent, waitHistory)
            txTimeUs = phys80211.TransactionTime(this.physical_type, this.physical_payload, this.physical_speed);
            txTimeMs = txTimeUs / 1000;
            
            medianWait = median(waitHistory);
            minWait = min(waitHistory);
            maxWait = max(waitHistory);
            avgWait = this.nSteps / nPacketsSent;
            
            fprintf('packets sent = %d\n', nPacketsSent);
            fprintf('min/max wait = %.3fms/%.3fms (%d/%d)\n', txTimeMs*minWait, txTimeMs*maxWait, minWait, maxWait);
            fprintf('median wait = %.3fms (%d)\n', txTimeMs*medianWait, medianWait);
            fprintf('avg wait = %.3fms (%.3f)\n', txTimeMs*avgWait, avgWait);
        end
        
        function PrintTransmitStats(this, successes, failures)
            successPercent = successes/(successes+failures);
            successTransmitTimePercent = successes/this.nSteps;
            
            fprintf('success = %.3f%%\t', 100*successPercent);
            fprintf('transmit = %.3f%%\n', 100*successTransmitTimePercent);
        end
        
        function success = GetSuccess(this)
            success = this.CountSuccesses()/(this.CountSuccesses()+this.CountFailures());
        end

        function transmit = GetTransmit(this)
            transmit = this.CountSuccesses()/this.nSteps;
        end

        function failure = GetFailures(this)
            failure = this.CountFailures()/(this.CountSuccesses()+this.CountFailures());
        end
        
        % Retrieve the node at the specified location
        function node = GetNode(this, index)
           node = this.nodes{index};
        end
        
        % Count up state types from all node
        function count = CountStates(this, sFn)
            nNodes = size(this.nodes, 2);
            count = 0;
            
            fn = str2func(sFn);
            for i=1:nNodes
                node = this.nodes{i};
                count = count + fn(node);
            end
        end
        
        % Count up success transitions
        function count = CountSuccesses(this)
            if (this.cachedSuccess < 0)
                this.cachedSuccess = this.CountStates('CountSuccesses');
            end
            
            count = this.cachedSuccess;
        end
        
        % Count up failure transitions
        function count = CountFailures(this)
            if (this.cachedFailure < 0)
                this.cachedFailure = this.CountStates('CountFailures');
            end
            
            count = this.cachedFailure;
        end
        
        % Count up wait (backoff) transitions
        function count = CountWaits(this)
            if (this.cachedWait < 0)
                this.cachedWait = this.CountStates('CountWaits');
            end
            
            count = this.cachedWait;
        end
        
        % Count up how many times we ended up in invalid states
        function count = CountInvalid(this)
            if (this.cachedInvalid < 0)
                this.cachedInvalid = this.CountStates('CountInvalidStates');
            end
            
            count = this.cachedInvalid;
        end
    end %methods
end
