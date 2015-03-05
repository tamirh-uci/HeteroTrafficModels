classdef dcf_simulator_oo < handle
    %DCF Simulator using OO classes
    
    properties (SetAccess = protected)
        % Probability of success when one node transmits
        pSuccessSingleTransmit = 1.0;
        
        % Probability of success when >1 node transmits
        pSuccessMultiTransmit = 0.0;
        
        % Do we look for failures in packetchains and then backtrack to
        % mark all previous states in that chain a failure?
        bDoPacketchainBacktrack = true;
        
        % simulation nodes
        nodes;
        
        % Count number of steps taken
        nSteps;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator_oo(pSuccessSingleTransmitIn, pSuccessMultiTransmitIn)
            obj = obj@handle();
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
        end
        
        function add_dcf_matrix(this, name, dcfmatrix)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(name, dcfmatrix, [], this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        function add_multimedia_matrix(this, name, dcfmatrix, multimediamodel)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(name, dcfmatrix, multimediamodel, this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this)
            nNodes = size(this.nodes, 2);
            this.nSteps = 0;
            
            % Setup node data
            for i=1:nNodes
                this.nodes{i}.Setup();
            end
        end
        
        % Simulate multipler timer transitions for all nodes
        function Steps(this, nSteps, bVerbose)
            if (bVerbose)
                % Percentage indicating progress
                progressDiv = 1.0 / 25;
                progressStep = progressDiv;
                
                for i=1:nSteps
                    this.Step();
                    
                    progress = i/nSteps;
                    if (progress > progressStep)
                        progressStep = progressStep + progressDiv;
                        fprintf('Progress: %.1f%%\n', 100*progress);
                    end
                end
            else
                for i=1:nSteps
                    this.Step();
                end
            end
            
            this.PostSimulationProcessing();
        end
        
        function PostSimulationProcessing(this)
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                node.PostSimulationProcessing(this.bDoPacketchainBacktrack);
            end
        end

        % Simulate single timer transition for all nodes
        function Step(this)
            nNodes = size(this.nodes, 2);
            this.nSteps = this.nSteps + 1;
            
            % Step each node forward in time
            nTransmitting = 0;
            for i=1:nNodes
                node = this.nodes{i};
                node.Step();
                nTransmitting = nTransmitting + node.IsTransmitting();
            end
            
            % Handle multiple nodes trying to transmit at once
            if (nTransmitting > 1)
               for i=1:nNodes
                    node = this.nodes{i};
                    % Force all of these into failure states by using the
                    % transition table for when there are 100% failures
                    if (node.IsTransmitting())
                        node.ForceFailure();
                    end
               end
            end
            
            % Node may have some work to do after the finalized state has
            % been reached (logging, or transmission type steps)
            for i=1:nNodes
                node = this.nodes{i};
                node.PostStep();
            end
        end
        
        % Print out some useful information about this run
        function PrintResults(this, verbose)
            fprintf('===Node Results===\n');
            nNodes = size(this.nodes, 2);
            for i=1:nNodes
                node = this.nodes{i};
                fprintf(' +%s+\n', node.name);
                this.PrintStats(node.CountSuccesses(), node.CountFailures());
                fprintf('\n');
                if (verbose)
                    node.mainChain.transitionHistory
                    node.mainChain.stateTypeHistory
                end
            end
            
            fprintf('\n===Overall===\n');
            this.PrintStats(this.CountSuccesses(), this.CountFailures());
        end
        
        function PrintStats(this, successes, failures)
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
            count = this.CountStates('CountSuccesses');
        end
        
        % Count up failure transitions
        function count = CountFailures(this)
            count = this.CountStates('CountFailures');
        end
        
        % Count up wait (backoff) transitions
        function count = CountWaits(this)
            count = this.CountStates('CountWaits');
        end
        
        % Count up how many times we ended up in invalid states
        function count = CountInvalid(this)
            count = this.CountStates('CountInvalidStates');
        end
    end %methods
end
