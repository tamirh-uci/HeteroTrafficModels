classdef dcf_simulation < handle
    %DCF_SIMULATION Set up a simulation run which will run through all
    % combinations of variables
    
    % Any value here can be an array which will be looped over
    % Values here will be shared over all nodes
    properties
        nTimesteps = 100;
        pSingleSuccess = 1.0;
        pMultiSuccess = 0.0;
        physical_type = phys80211_type.B;
        physical_speed = 1.0;
        physical_payload = 8*1500;
        
        % the nodegen will create some number of variations on node
        % specific configurations
        nodegens = [];
    end
    
    % Debug options
    properties
        verboseSetup = false;
        verboseExecute = false;
        verbosePrint = false;
        printResults = false;
    end
    
    properties (SetAccess = protected)
    end
    
    methods
        function obj = dcf_simulation()
            obj = obj@handle();
        end
        
        function run(this)
            nThisNTimesteps = size(this.nTimesteps, 2);
            nThisPSingleSuccess = size(this.pSingleSuccess, 2);
            nThisPMultiSuccess = size(this.pMultiSuccess, 2);
            nThisPhysical_type = size(this.physical_type, 2);
            nThisPhysical_speed = size(this.physical_speed, 2);
            nThisPhysical_payload = size(this.physical_payload, 2);
            
            nTotalNodgenOptions = 0;
            for nodegen = this.nodegens
                nTotalNodgenOptions = nTotalNodgenOptions + nodegen.NumVariations();
            end
            
            varIndex = 1;
            nVariations = nThisNTimesteps * nThisPSingleSuccess * nThisPMultiSuccess * nThisWMin * nThisWMax * nThisPhysical_type * nThisPhysical_speed * nThisPhysical_payload * nTotalNodgenOptions;
            for thisNTimesteps = this.nTimesteps
            for thisPSingleSuccess = this.pSingleSuccess
            for thisPMultiSuccess = this.pMultiSuccess
            for thisPhysical_type = this.physical_type
            for thisPhysical_speed = this.physical_speed
            for thisPhysical_payload = this.physical_payload
            for nodegen = nodegens
                nodegenVariations = nodegen.NumVariations();
                for i=1:nodegenVariations
                    nodegenVar = nodegen.GetVariation(i);
                    
                    s = dcf_simulator(thisPSingleSuccess, thisPMultiSuccess, thisPhysical_type, thisPhysical_payload, thisPhysical_speed);
                    nodegenVar.addNodes(s);
                    this.runSim(thisNTimesteps);
                    
                    varIndex = 1 + varIndex;
                end
            end %nodegens
            end %physical_payload
            end %physical_speed
            end %physical_type
            end %pMultiSuccess
            end %pSingleSuccess
            end %nTimesteps
        end % run()
        
        function runSim(this, sim, thisNTimesteps)
            sim.Setup(this.verboseSetup);
            sim.Steps(thisNTimesteps, this.verboseExecute);
            
            if (this.printResults)
                sim.PrintResults(this.verbosePrint);
            end
            
            % TODO: Dump results to CSV
        end
    end
end