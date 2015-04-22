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
        
        name;
        % if true, delete all previous run data for this setup
        cleanCache = false;
        
        loadSetupCache = true;
        loadStepsCache = true;
        
        saveSetupCache = true;
        saveStepsCache = true;
        
        resultsFolder = './../results';
        cacheBaseFolder = './../results/cache';
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
        nExpectedVariations;
        
        ngVariations;
        ngSizes;
        ngCurrIndices;
        
        cacheFolder;
    end
    
    methods
        function obj = dcf_simulation(nameIn)
            obj = obj@handle();
            obj.nodegensSize = 0;
            obj.name = nameIn;
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
        
        function uid = UID(this)
            arrayStrings = sprintf(...
                'DCF_SIMULATION:%s\n timesteps=%s\n pSingleSuccess=%s\n pMultiSuccess%s\n physicalType=%s\n physicalSpeed=%s\n physicalPayload=%s\n nNodegens=%d', ...
                this.name, mat2str(this.nTimesteps), mat2str(this.pSingleSuccess), mat2str(this.pMultiSuccess),  mat2str(this.physical_type), mat2str(this.physical_speed), mat2str(this.physical_payload), this.nodegensSize);
            
            nodegenString = '';
            for i=1:this.nodegensSize
                nodegen = this.nodegens{i};
                nodegenString = sprintf('%s NODEGEN #%d: %s', nodegenString, i, nodegen.UID());
            end
            
            uid = sprintf('%s\n%s', arrayStrings, nodegenString);
        end
        
        function PreCalc(this)
            this.nodegensSize = size(this.nodegens, 2);
            
            for i = 1:this.nodegensSize;
                nodegen = this.nodegens{i};
                this.ngSizes(i) = nodegen.NumVariations();
            end
            
            this.nExpectedVariations = this.NumVariations();
        end
        
        function SetupCache(this)
            % setup folders
            uid = this.UID();
            hash = string2hash( uid, 2 );
            this.cacheFolder = sprintf('%s%s%.16X-%.16X', this.cacheBaseFolder, filesep(), hash(1), hash(2));
            
            [~, ~, ~] = mkdir(this.resultsFolder);
            [~, ~, ~] = mkdir(this.cacheBaseFolder);
            [~, ~, ~] = mkdir(this.cacheFolder);
            
            % make sure we're dealing with the same cache
            uidFileName = fullfile(this.cacheFolder, 'uid.mat');
            if( exist(uidFileName, 'file')==2 )
                fileUID = '';
                load(uidFileName);
                assert( strcmp(fileUID, uid) );
            end
            
            if( this.cleanCache )
                [~, ~, ~] = rmdir(this.cacheFolder, 's');
                [~, ~, ~] = mkdir(this.cacheFolder);
            end
            
            % matlab thinks fileUID is an unused variable, so 'use' it
            fileUID = uid;
            assert( size(fileUID,2) > 1 );
            save(uidFileName, 'fileUID');
        end
        
        function Run(this)
            this.PreCalc();
            this.SetupCache();
            
            % loop over all of our possible variables
            for thisPSingleSuccess = this.pSingleSuccess
            for thisPMultiSuccess = this.pMultiSuccess
            for thisPhysical_type = this.physical_type
            for thisPhysical_speed = this.physical_speed
            for thisPhysical_payload = this.physical_payload

            % loop over every nodegen variation combination
            nVariations = 0;
            while (nVariations < this.nExpectedVariations)
                simulator = dcf_simulator(thisPSingleSuccess, thisPMultiSuccess, thisPhysical_type, thisPhysical_payload, thisPhysical_speed);
                
                this.AddNodes(simulator);
                this.IncrementCartesianIndices();
                
                for thisNTimesteps = this.nTimesteps
                    this.RunSimInstance(simulator, thisNTimesteps, nVariations);
                    simulator.Reset();
                    
                    nVariations = 1 + nVariations;
                end %nTimesteps
            end

            end %physical_payload
            end %physical_speed
            end %physical_type
            end %pMultiSuccess
            end %pSingleSuccess
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
        
        function RunSimInstance(this, sim, thisNTimesteps, index)
            setupCache = fullfile(this.cacheFolder, sprintf('%d%s', index, '.setup.mat'));
            stepsCache = fullfile(this.cacheFolder, sprintf('%d%s', index, '.steps'));
            
            sim.Setup(setupCache, this.loadSetupCache, this.saveSetupCache, this.verboseSetup);
            sim.Steps(thisNTimesteps, stepsCache, this.loadStepsCache, this.saveStepsCache, this.verboseExecute);
            
            if (this.printResults)
                sim.PrintResults(this.verbosePrint);
            end
            
            % TODO: Plot Figures
        end
    end
end