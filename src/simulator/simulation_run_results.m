classdef simulation_run_results < handle
    %SIMULATION_RUN_RESULTS Plottable results from a simulation run
    properties
        variation;
        nSteps;
        
        simSuccessCount;
        simFailureCount;
        simWaitCount;
        simInvalidCount;
        
        nNodes;
        nodeSuccessCount;
        nodeFailureCount;
        nodeWaitCount;
        nodeInvalidCount;
        
        nodeDcfHistory;
        nodeSecHistory;
    end
    
    methods
        function obj = simulation_run_results()
            obj = obj@handle();
        end
    end
end

