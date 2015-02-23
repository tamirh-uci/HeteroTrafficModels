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
            this.nodes{nNodes+1} = dcf_sim_node(dcfmatrix, this.pSuccess, this.pFail);
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
            
            % Log metrics for all nodes
            for i=1:nNodes
                node = this.nodes{i};
                node.Log();
            end
        end
        
        % Count up success transitions
        function successes = CountSuccesses(this)
            nNodes = size(this.nodes, 2);
            successes = 0;

            for i=1:nNodes
                node = this.nodes{i};
                successes = successes + node.CountSuccesses();
            end
        end
        
        % Count up failure transitions
        function failures = CountFailures(this)
            nNodes = size(this.nodes, 2);
            failures = 0;
            
            for i=1:nNodes
                node = this.nodes{i};
                failures = failures + node.CountFailures();
            end
        end
        
        % Count up wait (backoff) transitions
        function waits = CountWaits(this)
            nNodes = size(this.nodes, 2);
            waits = 0;
            
            for i=1:nNodes
                node = this.nodes{i};
                waits = waits + node.CountWaits();
            end
        end
    end %methods
end
