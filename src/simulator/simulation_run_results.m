classdef simulation_run_results < handle
    %SIMULATION_RUN_RESULTS Plottable results from a simulation run
    properties
        variation;
        nSteps;
        label;
        
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
        nodeWaitHistory;
        nodeTxHistory;
        
        nodeSlowWaitQuality;
        nodeSlowWaitCount;
    end
    
    methods
        function obj = simulation_run_results()
            obj = obj@handle();
        end
        
        function PrepData(this, microsecPerTick, qualityThresholdMicrosec)
            this.nodeWaitHistory = cell(1, this.nNodes);
            this.nodeSlowWaitQuality = zeros(1, this.nNodes);
            this.nodeSlowWaitCount = zeros(1, this.nNodes);
            this.nodeTxHistory = cell(1, this.nNodes);
            
            for i=1:this.nNodes
                history = this.nodeDcfHistory{i};
                this.nodeWaitHistory{i} = microsecPerTick * history.packetWaitHistory(1:history.currentPacketIndex);
                
                q = this.nodeWaitHistory{i};
                q( q<qualityThresholdMicrosec ) = 0;
                
                this.nodeSlowWaitCount(i) = nnz(q);
                this.nodeSlowWaitQuality(i) = sum(q);
                
                this.nodeTxHistory{i} = history.stateTypeHistory == dcf_state_type.Transmit;
            end
            
            this.label = sprintf('Var %d', this.variation);
        end
    end
end
