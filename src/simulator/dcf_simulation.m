classdef dcf_simulation < handle
    %DCF_SIMULATION Set up a simulation run which will run through all
    % combinations of variables

    % These are the params which we will loop over
    % Timesteps are kept separate because we won't create a new simulation
    % object, we can just Reset() to call with different timesteps
    properties
        nTimesteps = 100;
        
        params@dcf_simulation_params;
        cartesianParams@cartesian_params;
    end
    
    properties
        name;
        
        % if true, delete all previous run data for this setup
        cleanCache = false;
        
        loadSetupCache = true;
        loadStepsCache = true;
        loadResultsCache = true;
        
        saveSetupCache = true;
        saveStepsCache = true;
        saveResultsCache = true;
        
        displayFigures = true;
        
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
        nodegensSize;
        nExpectedVariations;
        
        ngSizes;
        ngCurrIndices;
        
        cacheFolder;
        
        elapsedSetup;
        elapsedNewSim;
        elapsedRun;
        elapsedTotal;
        
        simResults = {};
    end
    
    methods
        function obj = dcf_simulation(nameIn)
            obj = obj@handle();
            
            obj.params = dcf_simulation_params();
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
        
        function uid = UID(this, timesteps)
            if (isempty(timesteps))
                steps = this.nTimesteps;
                current = false;
            else
                steps = timesteps;
                current = true;
            end
            
            paramUID = this.cartesianParams.UID(current, ' ');
            
            mainUID = sprintf(...
                'DCF_SIMULATION:%s\n%s\n nTimesteps=%d\n nNodegens=%d', ...
                this.name, paramUID, mat2str(steps), this.nodegensSize );
            
            nodegenString = '';
            for i=1:this.nodegensSize
                nodegen = this.nodegens{i};
                nodegenString = sprintf('%s NODEGEN #%d: %s', nodegenString, i, nodegen.UID(false, '  '));
            end
            
            uid = sprintf('%s\n%s', mainUID, nodegenString);
        end
        
        function nVariations = NumVariations(this)
            
            
            nVariations = this.nTimestepsSize * this.cartesianParams.NumVariations() * prod(this.ngSizes);
        end
        
        function PreCalc(this)
            this.cartesianParams = cartesian_params();
            this.cartesianParams.values = this.params;
            this.cartesianParams.PreCalc();
            
            this.nTimestepsSize = size(this.nTimesteps, 2);
            
            this.nodegensSize = size(this.nodegens, 2);
            this.ngSizes = zeros(1, this.nodegensSize);
            
            for i = 1:this.nodegensSize;
                nodegen = this.nodegens{i};
                
                nodegen.PreCalc();
                this.ngSizes(i) = nodegen.NumVariations();
            end
            
            this.nExpectedVariations = this.NumVariations();
            
            this.elapsedSetup = 0;
            this.elapsedNewSim = zeros(1, this.nExpectedVariations / this.nTimestepsSize);
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
            simUID = this.UID([]);
            hash = string2hash( simUID, 2 );
            this.cacheFolder = sprintf('%s%s%s-%.16X-%.16X', this.cacheBaseFolder, filesep(), this.name, hash(1), hash(2));
            
            if( this.cleanCache )
                [~, ~, ~] = rmdir(this.cacheFolder, 's');
            end
            
            [~, ~, ~] = mkdir(this.resultsFolder);
            [~, ~, ~] = mkdir(this.cacheBaseFolder);
            [~, ~, ~] = mkdir(this.cacheFolder);
            
            % Make sure all the caches look like they're up to date
            [simcacheValid, simcacheExists] = this.VerifyCacheUID(this.cacheFolder, simUID, 'simulation.uid.mat');
            if (simcacheExists && ~simcacheValid)
                fprintf('WARN: Simulation cache exists but is not valid (probably out of date)\n');
            end
            
            for i=1:this.nodegensSize
                node = this.nodegens{i};
                nodegenUID = node.UID(false, '  ');
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
            
            if (this.loadResultsCache && this.LoadSimulationRunResults())
                fprintf(' =Loaded simulation run, skipping operations\n');
            else
                this.SimulationRun();
            end
            
            
            
            fprintf(' =Plotting Figures\n');
            this.PlotFigures(this.displayFigures);
            
            this.elapsedTotal = toc(totalTime);
            fprintf(' =Total execution (%s): %f seconds\n', this.name, this.elapsedTotal);
            
            this.SaveRunData();
        end
        
        function SimulationRun(this)
            % loop over all of our possible variables
            fprintf(' =Running %d variations\n', this.nExpectedVariations);
            nVariations = 0;
            nSimulators = 0;
            nParamVariations = this.cartesianParams.NumVariations();
            this.simResults = cell(1, nParamVariations);
            
            for iParamVariation = 1:nParamVariations
                this.NodegenResetCartesianIndices();
                currentSimValues = this.cartesianParams.CurrentValues();
                this.cartesianParams.IncrementCartesianIndices();
                
                % loop over every nodegen variation combination
                for iNodegenVariation = 1:prod( this.ngSizes )
                    nSimulators = 1 + nSimulators;
                    
                    time = tic();
                    simulator = dcf_simulator(currentSimValues);
                    this.AddNodes(simulator);
                    this.NodegenIncrementCartesianIndices();
                    this.elapsedNewSim(nSimulators) = toc(time);
                    fprintf('  +Generating new simulator: %f seconds\n', this.elapsedNewSim(nSimulators));
                    
                    for thisNTimesteps = this.nTimesteps
                        nVariations = 1 + nVariations;
                        
                        time = tic();
                        this.RunSimInstance(simulator, thisNTimesteps, nVariations);
                        simulator.Reset();
                        this.elapsedRun(nVariations) = toc(time);

                        fprintf('   -Running Variation %d of %d (size=%d): %f seconds\n', ...
                            nVariations, this.nExpectedVariations, simulator.simSize, this.elapsedRun(nVariations));
                    end %nTimesteps
                end
            end
            
            if (this.saveResultsCache)
                this.SaveSimulationRunResults();
            end
        end % run()

        function SaveRunData(this)
            setupTime = this.elapsedSetup;
            newSimTime = this.elapsedNewSim;
            runTime = this.elapsedRun;
            totalTime = this.elapsedTotal;
            
            assert(~isempty(setupTime));
            assert(~isempty(newSimTime));
            assert(~isempty(runTime));
            assert(~isempty(totalTime));
            
            filename = fullfile(this.cacheFolder, 'rundata.mat');
            save( filename, 'setupTime', 'newSimTime', 'runTime', 'totalTime' );
        end
        
        function AddNodes(this, simulator)
            for i=1:this.nodegensSize
                nodegen = this.nodegens{i};
                nodegen.AddCurrentVariation(simulator);
            end
        end
        
        function NodegenResetCartesianIndices(this)
            this.ngCurrIndices = ones(1, this.nodegensSize);
            for i = 1:this.nodegensSize
                nodegen = this.nodegens{i};
                nodegen.Reset();
            end
        end
        
        function NodegenIncrementCartesianIndices(this)
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
            cachePrefix = fullfile( this.cacheFolder, sprintf('variation-%d', index) );
            uidfile = strcat( cachePrefix, '.uid.mat' );
            
            uid = this.UID(thisNTimesteps);
            assert(~isempty(uid));
            save(uidfile, 'uid'); % TODO: The pSuccess is null when this happens
            
            % Run the simulation
            sim.Setup(cachePrefix, this.loadSetupCache, this.saveSetupCache, this.verboseSetup);
            sim.Steps(thisNTimesteps, cachePrefix, this.loadStepsCache, this.saveStepsCache, this.verboseExecute);
            
            % Dump out results to screen
            if (this.printResults)
                sim.PrintResults(this.verbosePrint);
            end
            
            % Save results to file
            sim.SaveResults(cachePrefix, this.loadResultsCache, this.saveResultsCache);
            this.simResults{index} = sim.GetResults(index);
        end
        
        function isLoaded = LoadSimulationRunResults(this)
            filename = fullfile( this.cacheFolder, 'results.mat' );
            
            results = [];
            isLoaded = false;
            if( exist(filename, 'file')==2 )
                try
                    load(filename);
                    isLoaded = true;
                catch err
                    err
                    isLoaded = false;
                end
            end
            
            if (isempty(results))
                isLoaded = false;
            end
            
            if (isLoaded)
                this.simResults = results;
            end
        end
        
        function SaveSimulationRunResults(this)
            filename = fullfile( this.cacheFolder, 'results.mat' );
            
            results = this.simResults;
            assert( ~isempty(results) );
            save(filename, 'results');
        end
        
        function PlotFigures(this, display)
            
        end
    end
end