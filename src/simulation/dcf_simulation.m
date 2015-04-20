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
        
        % if true, delete previous run data. if false, skip simulation if
        % previous run data already exists
        cleanRun = false;
    end
    
    % Debug options
    properties
        verboseSetup = false;
        verboseExecute = false;
        verbosePrint = false;
        printResults = false;
    end
    
    properties (SetAccess = protected)
        % the nodegen will create some number of variations on node
        % specific configurations
        nodegens = {};
        
        nTimestepsSize;
        pSingleSuccessSize;
        pMultiSuccessSize;
        physical_typeSize;
        physical_speedSize;
        physical_payloadSize;
        nodegensSize;
        
        ngVariations;
        ngSizes;
        ngCurrIndices;
    end
    
    methods
        function obj = dcf_simulation()
            obj = obj@handle();
            obj.nodegensSize = 0;
        end
        
        function AddNodegen(this, nodegen)
            this.nodegensSize = 1 + this.nodegensSize;
            this.nodegens{ this.nodegensSize } = nodegen;
        end
        
        function RemoveAllNodegens(this)
            this.nodegens = {};
            this.nodegensSize = 0;
        end
        
        function nVariations = NumVariations(this)
            this.nTimestepsSize = size(this.nTimesteps, 2);
            this.pSingleSuccessSize = size(this.pSingleSuccess, 2);
            this.pMultiSuccessSize = size(this.pMultiSuccess, 2);
            this.physical_typeSize = size(this.physical_type, 2);
            this.physical_speedSize = size(this.physical_speed, 2);
            this.physical_payloadSize = size(this.physical_payload, 2);
            
            this.ngSizes = 1:this.nodegensSize;
            this.ngCurrIndices = ones(1, size(this.nodegens, 2));
            this.ngVariations = prod(this.ngSizes);
            
            nVariations = this.nTimestepsSize * this.pSingleSuccessSize * this.pMultiSuccessSize * this.physical_typeSize * this.physical_speedSize * this.physical_payloadSize * this.ngVariations;
        end
        
        function Run(this)
            this.nodegensSize = size(this.nodegens, 2);
            for i = 1:this.nodegensSize;
                nodegen = this.nodegens{i};
                this.ngSizes(i) = nodegen.NumVariations();
            end
            
            nVariations = 0;
            nExpectedVariations = this.NumVariations();

            % loop over all of our possible variables
            for thisPSingleSuccess = this.pSingleSuccess
            for thisPMultiSuccess = this.pMultiSuccess
            for thisPhysical_type = this.physical_type
            for thisPhysical_speed = this.physical_speed
            for thisPhysical_payload = this.physical_payload

            % loop over every nodegen variation combination
            i = 1;
            while (i <= nExpectedVariations)
                simulator = dcf_simulator(thisPSingleSuccess, thisPMultiSuccess, thisPhysical_type, thisPhysical_payload, thisPhysical_speed);
                
                this.AddNodes(simulator);
                this.IncrementCartesianIndices();
                
                for thisNTimesteps = this.nTimesteps
                    this.RunSimInstance(simulator, thisNTimesteps);
                    simulator.Reset();
                    
                    i = i + 1;
                    nVariations = 1 + nVariations;
                end %nTimesteps
            end

            end %physical_payload
            end %physical_speed
            end %physical_type
            end %pMultiSuccess
            end %pSingleSuccess
            
            assert(nVariations==nExpectedVariations);
        end % run()

        function AddNodes(this, simulator)
            for i=1:this.nodegensSize
                nodegen = this.nodegens{i};
                nodegen.AddCurrentVariation(simulator);
            end
        end
        
        function IncrementCartesianIndices(this)
            % Increment index of rightmost index
            this.ngCurrIndices(this.nodegensSize) = 1 + this.ngCurrIndices(this.nodegensSize);
            nodegen = this.nodegens{this.nodegensSize};
            nodegen.IncrementCartesianIndices();
            
            % Propegate any overflow from right to left
            for i = this.nodegensSize:-1:2
                if ( this.ngCurrIndices(i) >= this.ngSizes(i) )
                    % Set the overflowed nodegen back to zero
                    nodegen = this.nodegens{i};
                    nodegen.Reset();
                    this.ngCurrIndices(i) = 1;
                    
                    % Increment the next nodegen one now
                    this.ngCurrIndices(i-1) = 1 + this.ngCurrIndices(i-1);
                    nodegen = this.nodegens{i-1};
                    nodegen.IncrementCartesianIndices();
                end
            end
        end
        
        function RunSimInstance(this, sim, thisNTimesteps)
            sim.Setup(this.verboseSetup);
            sim.Steps(thisNTimesteps, this.verboseExecute);
            
            if (this.printResults)
                sim.PrintResults(this.verbosePrint);
            end
            
            % TODO: Dump results to CSV
            sim.DumpCSV('foobar');
        end
    end
end