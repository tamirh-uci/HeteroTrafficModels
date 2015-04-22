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
        
        elapsedSetup;
        elapsedNewSim;
        elapsedRun;
        elapsedTotal;
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
            
            this.elapsedSetup = 0;
            this.elapsedNewSim = zeros(1, this.nExpectedVariations / size(this.nTimesteps,2));
            this.elapsedRun = zeros(1, this.nExpectedVariations);
            this.elapsedTotal = 0;
        end
        
        function [valid, exists] = VerifyCacheUID(~, folder, uid, filename)
            valid = false;
            exists = false;
            
            fullFilename = fullfile(folder, filename);
            if( exist(fullFilename, 'file')==2 )
                exists = true;
                
                fileUID = '';
                load(fullFilename);
                if ( strcmp(fileUID, uid) )
                    valid = true;
                end
            end
            
            fileUID = uid;
            assert( ~isempty(fileUID) );
            save(fullFilename, 'fileUID');
        end
        
        function SetupCache(this)
            % setup folders
            simUID = this.UID();
            hash = string2hash( simUID, 2 );
            this.cacheFolder = sprintf('%s%s%.16X-%.16X', this.cacheBaseFolder, filesep(), hash(1), hash(2));
            
            [~, ~, ~] = mkdir(this.resultsFolder);
            [~, ~, ~] = mkdir(this.cacheBaseFolder);
            [~, ~, ~] = mkdir(this.cacheFolder);
            
            if( this.cleanCache )
                [~, ~, ~] = rmdir(this.cacheFolder, 's');
                [~, ~, ~] = mkdir(this.cacheFolder);
            end
            
            % Make sure all the caches look like they're up to date
            [simcacheValid, simcacheExists] = this.VerifyCacheUID(this.cacheFolder, simUID, 'simulation.uid.mat');
            if (simcacheExists && ~simcacheValid)
                fprintf('WARN: Simulation cache exists but is not valid (probably out of date)\n');
            end
            
            for i=1:this.nodegensSize
                node = this.nodegens{i};
                nodegenUID = node.UID();
                nodegenUIDFilename = sprintf('nodegen.%d.uid.mat', i);
                
                [nodegencacheValid, nodegencacheExists] = this.VerifyCacheUID(this.cacheFolder, nodegenUID, nodegenUIDFilename);
                if (nodegencacheExists && ~nodegencacheValid)
                    fprintf('WARN: Nodegen cache %d exists but is not valid\n', i);
                    
                    if (simcacheValid)
                        fprintf('ERROR: This is bad, the overall simcache was thought to be valid but one of the nodegen caches was invalid\n');
                    end
                end
            end
        end
        
        function Run(this)
            fprintf('Setting up simulation for: %s\n', this.name);

            time = tic();
            totalTime = time;
            this.PreCalc();
            this.SetupCache();
            this.elapsedSetup = toc(time);
            fprintf(' =Setup: %f seconds\n', this.elapsedSetup);
            
            % loop over all of our possible variables
            fprintf(' =Running %d variations\n', this.nExpectedVariations);
            for thisPSingleSuccess = this.pSingleSuccess
            for thisPMultiSuccess = this.pMultiSuccess
            for thisPhysical_type = this.physical_type
            for thisPhysical_speed = this.physical_speed
            for thisPhysical_payload = this.physical_payload

            % loop over every nodegen variation combination
            nVariations = 0;
            nSimulators = 0;
            while (nVariations < this.nExpectedVariations)
                nSimulators = 1 + nSimulators;
                
                time = tic();
                simulator = dcf_simulator(thisPSingleSuccess, thisPMultiSuccess, thisPhysical_type, thisPhysical_payload, thisPhysical_speed);
                this.AddNodes(simulator);
                this.IncrementCartesianIndices();
                this.elapsedNewSim(nSimulators) = toc(time);
                fprintf('  +Generating new simulator: %f seconds\n', this.elapsedNewSim(nSimulators));
                
                for thisNTimesteps = this.nTimesteps
                    time = tic();
                    this.RunSimInstance(simulator, thisNTimesteps, nVariations);
                    simulator.Reset();
                    nVariations = 1 + nVariations;
                    this.elapsedRun(nVariations) = toc(time);
                    
                    fprintf('   -Running Variation %d of %d: %f seconds\n', nVariations, this.nExpectedVariations, this.elapsedRun(nVariations));
                end %nTimesteps
            end

            end %physical_payload
            end %physical_speed
            end %physical_type
            end %pMultiSuccess
            end %pSingleSuccess
            
            this.elapsedTotal = toc(totalTime);
            fprintf(' =Total execution (%s): %f seconds\n', this.name, this.elapsedTotal);
            
            this.SaveTimingData();
        end % run()

        function SaveTimingData(this)
            setup = this.elapsedSetup;
            newSim = this.elapsedNewSim;
            run = this.elapsedRun;
            total = this.elapsedTotal;
            
            assert(~isempty(setup));
            assert(~isempty(newSim));
            assert(~isempty(run));
            assert(~isempty(total));
            
            filename = fullfile(this.cacheFolder, 'elapsed.mat');
            save( filename, 'setup', 'newSim', 'run', 'total' );
        end
        
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
                if ( this.ngCurrIndices(i) > this.ngSizes(i) )
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
            setupCache = fullfile( this.cacheFolder, sprintf('variation-%d', index) );
            stepsCache = fullfile( this.cacheFolder, sprintf('variation-%d', index) );
            
            sim.Setup(setupCache, this.loadSetupCache, this.saveSetupCache, this.verboseSetup);
            sim.Steps(thisNTimesteps, stepsCache, this.loadStepsCache, this.saveStepsCache, this.verboseExecute);
            
            if (this.printResults)
                sim.PrintResults(this.verbosePrint);
            end
            
            % TODO: Plot Figures
        end
    end
end