classdef simulation_single_node < handle
    properties
        verboseSetup = false;
        verboseExecute = false;
        verbosePrint = false;
        
        doFiles = false;
        doWebtx = false;
        doRando = false;
        doVideo = true;
        
        timeSteps = 10000;
        wMin = 2;
        wMax = 16;
        
        %pSuccessOptions = [0.4, 0.6, 0.8, 1.0];
        pSuccessOptions = [1.0];
        
        % FILE DOWNLOAD
        files_pArrive = 1.0;
        files_pEnter = 1.0;
        files_nMaxPackets = 2;
        files_nInterarrival = 1;

        % WEB TRAFFIC
        %TODO: Fix postbackoff
        %webtx_pArrive = 0.5;
        webtx_pArrive = 1.0;
        webtx_pEnter = 0.5;
        webtx_nMaxPackets = 1;
        webtx_nInterarrival = 5;

        % RANDOM TRAFFIC
        rando_pArrive = 1.0;
        rando_pEnter = 0.0;
        rando_nMaxPackets = 4;
        rando_nInterarrival = 0;

        % MULTIMEDIA STREAMING
        video_bps_options = 1000000 * [4]; % 4MBits/second
        video_payloadSize = 1500*8;
    end
    
    methods (Static)
        function [fname, fncsv] = fnames(name, pSuccess, pArrive, pEnter, nMaxPackets, nInterarrival, bps, payloadSize)
            if (bps > 0)
                fname = sprintf('./../results/simulation_single_node_%s-s%.2f-b%.2f-p%.2f.log', name, pSuccess, bps, payloadSize);
                fncsv = sprintf('./../results/simulation_single_node_%s-s%.2f-b%.2f-p%.2f.csv', name, pSuccess, bps, payloadSize);
            else
                fname = sprintf('./../results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.log', name, pSuccess, pArrive, pEnter, nMaxPackets, nInterarrival);
                fncsv = sprintf('./../results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.csv', name, pSuccess, pArrive, pEnter, nMaxPackets, nInterarrival);
            end
        end
    end
    
    methods
        function obj = simulation_single_node()
            obj = obj@handle;
        end
        
        function runSim(this, doSim, sim, fname)
            if (~doSim)
                return;
            end
            
            fprintf('Setting up: %s\n', fname);
            sim.Setup(this.verboseSetup);

            fprintf('\n+Running %s simulation\n', fname);
            sim.Steps(this.timeSteps, this.verboseExecute);

            fprintf('Dumping out results...\n');
            sim.PrintResults(this.verbosePrint);
        end
        
        function recordSim(this, doSim, sim, fname, fncsv, bps)
            if (~doSim)
                return;
            end
            
            fid = fopen(fname, 'w');
            if (fid == -1)
                disp('Error: could not open output file: %s', fname);
                return;
            end
            
            csv = fopen(fncsv, 'w');
            if (csv == -1)
                disp('Error: could not open csv output file: %s', fncsv);
                return;
            end
            
            node = sim.GetNode(1);
            dcfHist = node.dcfHist;
            secHist = node.secHist;
            
            % Dump the basic summary data
            success = node.CountSuccesses();
            failure = node.CountFailures();
            waiting = node.CountWaits();
            fprintf(fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
            fprintf(fid, '%d,%d,%d,%d,%d,%d\n\n', this.timeSteps, this.wMin, this.wMax, success, failure, waiting);
            
            % Dump history logs
            if (bps == 0)
                fprintf(fid, '%s,%s,%s\n', 'state_index', 'state_type', 'transition_type');
                for i=1:this.timeSteps
                    fprintf(fid, '%d,%d,%d\n', dcfHist.indexHistory(i), dcfHist.stateTypeHistory(i), dcfHist.transitionHistory(i));
                    fprintf(csv, '%d,%d,%d\n', dcfHist.indexHistory(i), dcfHist.stateTypeHistory(i), dcfHist.transitionHistory(i));
                end
            else
                fprintf(fid, '%s,%s,%s,%s\n', 'state_index', 'state_type', 'transition_type', 'frame_type');
                for i=1:this.timeSteps
                    fprintf(fid, '%d,%d,%d\n', dcfHist.indexHistory(i), dcfHist.stateTypeHistory(i), dcfHist.transitionHistory(i), secHist.stateTypeHistory(i));
                    fprintf(csv, '%d,%d,%d\n', dcfHist.indexHistory(i), dcfHist.stateTypeHistory(i), dcfHist.transitionHistory(i), secHist.stateTypeHistory(i));
                end
            end
            
            fclose(fid);
            fclose(csv);
        end
        
        function hist = subplotVid(~, vidHist, txsHist, height1, height2, ok1, ok2)
            hist = zeros(size(vidHist));
            
            % 'new' transmissions will stand out as peaks
            hist(vidHist==ok1) = height1;
            hist(vidHist==ok2) = height2;
            
            % when there's a failure, null out the history value
            hist(txsHist==dcf_transition_type.TxFailure | txsHist==dcf_transition_type.Backoff) = 0;
        end
        
        function plotVid(this, node, pSuccess, video_bps, index)
            vidHist = node.secHist.stateTypeHistory;
            txsHist = node.dcfHist.transitionHistory;
            
            % Separate out the data into individual frame parts
            iHist = this.subplotVid(vidHist, txsHist, 0.95, 0.95, dcf_state_type.IFrameNew, dcf_state_type.IFrameContinue);
            pHist = this.subplotVid(vidHist, txsHist, 0.95, 0.95, dcf_state_type.PFrameNew, dcf_state_type.PFrameContinue);
            bHist = this.subplotVid(vidHist, txsHist, 0.95, 0.95, dcf_state_type.BFrameNew, dcf_state_type.BFrameContinue);
            
            backoff = zeros(size(vidHist));
            backoff(txsHist==dcf_transition_type.Backoff) = 0.15;
            
            fails = zeros(size(vidHist));
            fails(txsHist==dcf_transition_type.TxFailure) = 0.10;
            
            data = [iHist', pHist', bHist', (backoff+fails)'];
            
            %sub = subplot(rows, cols, index);
            fig = figure(index);
            set(fig, 'WindowStyle', 'docked');
            %set(fig, 'Visible','off');
            bar(data, 'stacked', 'BarWidth', 1.0, 'EdgeColor', 'none');
            legend('I-Frame', 'P-Frame', 'B-Frame', 'backoff');
            title(sprintf('Single multimedia node with pSuccess=%.2f, bps=%d', pSuccess, video_bps));
            
            saveas(fig, sprintf('./../results/fig-singlenode_mm_sim%.2f.eps', pSuccess));
        end
        
        function run(this)
            %t = 0:this.timeSteps;
            %colors = { [0, 1, 1], [1, 0, 0], [0, 1, 0], [0.5, 1, 0], [0.5, 0, 1], [1, 0.5, 0], [1, 0, 1] };
            
            [m, ~] = dcf_matrix_collapsible.CalculateDimensions(this.wMin, this.wMax);

            %cols = 2;
            %rows = size(this.pSuccessOptions, 2) / cols;
            
            i = 0;
            for video_bps = this.video_bps_options
            for pSuccess = this.pSuccessOptions
                i = i + 1;
                % Separate simulation for each node type
                files_simulator = dcf_simulator(pSuccess, 0.0);
                webtx_simulator = dcf_simulator(pSuccess, 0.0);
                rando_simulator = dcf_simulator(pSuccess, 0.0);
                video_simulator = dcf_simulator(pSuccess, 0.0);

                add_file_download_node( files_simulator, m, this.wMin, 1, this.files_pArrive, this.files_pEnter, this.files_nMaxPackets, this.files_nInterarrival);
                add_web_traffic_node(   webtx_simulator, m, this.wMin, 2, this.webtx_pArrive, this.webtx_pEnter, this.webtx_nMaxPackets, this.webtx_nInterarrival);
                add_random_node(        rando_simulator, m, this.wMin, 3, this.rando_pArrive, this.rando_pEnter, this.rando_nMaxPackets, this.rando_nInterarrival);
                
                add_multimedia_node(    video_simulator, m, this.wMin, 4, video_bps, this.video_payloadSize);
                add_file_download_node( video_simulator, m, this.wMin, 5, this.files_pArrive, this.files_pEnter, this.files_nMaxPackets, this.files_nInterarrival);

                [files_fName, files_fNcsv] = simulation_single_node.fnames('files', pSuccess, this.files_pArrive, this.files_pEnter, this.files_nMaxPackets, this.files_nInterarrival, 0, 0);
                [webtx_fName, webtx_fNcsv] = simulation_single_node.fnames('webtx', pSuccess, this.webtx_pArrive, this.webtx_pEnter, this.webtx_nMaxPackets, this.webtx_nInterarrival, 0, 0);
                [rando_fName, rando_fNcsv] = simulation_single_node.fnames('rando', pSuccess, this.rando_pArrive, this.rando_pEnter, this.rando_nMaxPackets, this.rando_nInterarrival, 0, 0);
                [video_fName, video_fNcsv] = simulation_single_node.fnames('video', pSuccess, 0, 0, 0, 0, video_bps, this.video_payloadSize);
                
                fprintf('Running simulations...\n');
                this.runSim(this.doFiles, files_simulator, files_fName);
                this.runSim(this.doWebtx, webtx_simulator, webtx_fName);
                this.runSim(this.doRando, rando_simulator, rando_fName);
                this.runSim(this.doVideo, video_simulator, video_fName);

                fprintf('Writing results to file...\n');
                this.recordSim(this.doFiles, files_simulator, files_fName, files_fNcsv, 0);
                this.recordSim(this.doWebtx, webtx_simulator, webtx_fName, webtx_fNcsv, 0);
                this.recordSim(this.doRando, rando_simulator, rando_fName, rando_fNcsv, 0);
                this.recordSim(this.doVideo, video_simulator, video_fName, video_fNcsv, video_bps);

                % Plot the frame transmissions
                fprintf('Plotting...\n');
                this.plotVid(video_simulator.GetNode(1), pSuccess, video_bps, i);
                
                fprintf('Done with pSuccess=%f + video_bps=%d\n', pSuccess, video_bps);
            end % for pSuccess
            end % for video_bps
        end %function run()
    end %methods
end %classdef