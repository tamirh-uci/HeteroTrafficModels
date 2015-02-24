classdef dcf_simulator_oo < handle
    %DCF Simulator using OO classes
    
    properties (SetAccess = protected)
        % Probability of success when one node transmits
        pSuccessSingleTransmit = 1.0;
        
        % Probability of success when >1 node transmits
        pSuccessMultiTransmit = 0.0;
        
        % simulation nodes
        nodes;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator_oo(pSuccessSingleTransmitIn, pSuccessMultiTransmitIn)
            obj = obj@handle();
            obj.pSuccessSingleTransmit = pSuccessSingleTransmitIn;
            obj.pSuccessMultiTransmit = pSuccessMultiTransmitIn;
        end
        
        function add_dcf_matrix(this, dcfmatrix)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(dcfmatrix, [], this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        function add_multimedia_matrix(this, dcfmatrix, multimediamodel)
            nNodes = size(this.nodes, 2);
            this.nodes{nNodes+1} = dcf_sim_node(dcfmatrix, multimediamodel, this.pSuccessSingleTransmit, this.pSuccessMultiTransmit);
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this)
            nNodes = size(this.nodes, 2);
            
            % Setup node data
            for i=1:nNodes
                this.nodes{i}.Setup();
            end
        end
        
        % Simulate multipler timer transitions for all nodes
        function Steps(this, nSteps)
            for i=1:nSteps
                this.Step();
            end
        end

        % Simulate single timer transition for all nodes
        function Step(this)
            nNodes = size(this.nodes, 2);
            
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
        function PrintResults(this)
            successes = this.CountSuccesses();
            failures = this.CountFailures();
            waits = this.CountWaits();
            
            successPercent = successes/(successes+failures);
            successTransmitTimePercent = successes/(successes+failures+waits);
            
            fprintf('success = %.2f%%\t', 100*successPercent);
            fprintf('transmit = %.2f%%\n', 100*successTransmitTimePercent);
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
