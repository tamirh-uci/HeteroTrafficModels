verboseSetup = false;
verboseExecute = false;
verbosePrint = false;

timeSteps = 50000;
wMin = 2;
wMax = 16;

[m, W] = dcf_matrix_collapsible.CalculateDimensions(wMin, wMax);

% Test all types of nodes individually to see how they perform
pSuccessOptions = [0.1, 0.4, 0.7, 1.0];

% FILE DOWNLOAD
files_pArrive = 1.0;
files_pEnter = 1.0;
files_nMaxPackets = 10;
files_nInterarrival = 10;

% WEB TRAFFIC
%TODO: Fix postbackoff
%webtx_pArrive = 0.5;
webtx_pArrive = 1.0;
webtx_pEnter = 0.5;
webtx_nMaxPackets = 5;
webtx_nInterarrival = 5;

% RANDOM TRAFFIC
rando_pArrive = 1.0;
rando_pEnter = 0.0;
rando_nMaxPackets = 4;
rando_nInterarrival = 0;

% MULTIMEDIA STREAMING
video_bps = 4 * 1000000; % 4MBits/second
video_payloadSize = 1500*8;

for pSuccess = pSuccessOptions
    % Separate simulation for each node type
    files_simulator = dcf_simulator_oo(pSuccess, 0.0);
    webtx_simulator = dcf_simulator_oo(pSuccess, 0.0);
    rando_simulator = dcf_simulator_oo(pSuccess, 0.0);
    video_simulator = dcf_simulator_oo(pSuccess, 0.0);
    
    add_file_download_node( files_simulator, m, wMin, 1, files_pArrive, files_pEnter, files_nMaxPackets, files_nInterarrival);
    add_web_traffic_node(   webtx_simulator, m, wMin, 2, webtx_pArrive, webtx_pEnter, webtx_nMaxPackets, webtx_nInterarrival);
    add_random_node(        rando_simulator, m, wMin, 3, rando_pArrive, rando_pEnter, rando_nMaxPackets, rando_nInterarrival);
    add_multimedia_node(    video_simulator, m, wMin, 4, video_bps, video_payloadSize);
    
    files_fName = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.log', 'files', pSuccess, files_pArrive, files_pEnter, files_nMaxPackets, files_nInterarrival);
    files_fNcsv = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.csv', 'files', pSuccess, files_pArrive, files_pEnter, files_nMaxPackets, files_nInterarrival);
    
    webtx_fName = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.log', 'webtx', pSuccess, webtx_pArrive, webtx_pEnter, webtx_nMaxPackets, webtx_nInterarrival);
    webtx_fNcsv = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.csv', 'webtx', pSuccess, webtx_pArrive, webtx_pEnter, webtx_nMaxPackets, webtx_nInterarrival);
    
    rando_fName = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.log', 'rando', pSuccess, rando_pArrive, rando_pEnter, rando_nMaxPackets, rando_nInterarrival);
    rando_fNcsv = sprintf('./results/simulation_single_node_%s-s%.2f-a%.2f-e%.2f-m%.2f-i%.2f.csv', 'rando', pSuccess, rando_pArrive, rando_pEnter, rando_nMaxPackets, rando_nInterarrival);
    
    video_fName = sprintf('./results/simulation_single_node_%s-s%.2f-b%.2f-p%.2f.log', 'video', pSuccess, video_bps, video_payloadSize);
    video_fNcsv = sprintf('./results/simulation_single_node_%s-s%.2f-b%.2f-p%.2f.csv', 'video', pSuccess, video_bps, video_payloadSize);
    
    fprintf('Setting up: %s\n', files_fName);
    files_simulator.Setup(verboseSetup);
    
    fprintf('Setting up: %s\n', webtx_fName);
    webtx_simulator.Setup(verboseSetup);
    
    fprintf('Setting up: %s\n', rando_fName);
    rando_simulator.Setup(verboseSetup);
    
    fprintf('Setting up: %s\n', video_fName);
    video_simulator.Setup(verboseSetup);
    
    fprintf('\n+Running %s simulation\n', files_fName);
    files_simulator.Steps(timeSteps, verboseExecute);
    
    fprintf('\n+Running %s simulation\n', webtx_fName);
    webtx_simulator.Steps(timeSteps, verboseExecute);
    
    fprintf('\n+Running %s simulation\n', rando_fName);
    rando_simulator.Steps(timeSteps, verboseExecute);
    
    fprintf('\n+Running %s simulation\n', video_fName);
    video_simulator.Steps(timeSteps, verboseExecute);
    
    fprintf('Dumping out results...\n');
    files_simulator.PrintResults(verbosePrint);
    webtx_simulator.PrintResults(verbosePrint);
    rando_simulator.PrintResults(verbosePrint);
    video_simulator.PrintResults(verbosePrint);

    fprintf('Writing results to file...\n');
    
    files_fid = fopen(files_fName, 'w');
    webtx_fid = fopen(webtx_fName, 'w');
    rando_fid = fopen(rando_fName, 'w');
    video_fid = fopen(video_fName, 'w');
    if (files_fid == -1 || webtx_fid == -1 || rando_fid == -1 || video_fid == -1)
        disp('Error: could not open some file for output.');
        return;
    end
    
    files_csv = fopen(files_fNcsv, 'w');
    webtx_csv = fopen(webtx_fNcsv, 'w');
    rando_csv = fopen(rando_fNcsv, 'w');
    video_csv = fopen(video_fNcsv, 'w');
    if (files_csv == -1 || webtx_csv == -1 || rando_csv == -1 || video_csv == -1)
        disp('Error: could not open some file for output.');
        return;
    end
    
    files_node = files_simulator.GetNode(1);
    webtx_node = webtx_simulator.GetNode(1);
    rando_node = rando_simulator.GetNode(1);
    video_node = video_simulator.GetNode(1);
    
    % Dump the basic summary data
    files_success = files_node.CountSuccesses();
    files_failure = files_node.CountFailures();
    files_waiting = files_node.CountWaits();
    fprintf(files_fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
    fprintf(files_fid, '%d,%d,%d,%d,%d,%d\n\n', timeSteps, wMin, wMax, files_success, files_failure, files_waiting);
    
    webtx_success = webtx_node.CountSuccesses();
    webtx_failure = webtx_node.CountFailures();
    webtx_waiting = webtx_node.CountWaits();
    fprintf(webtx_fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
    fprintf(webtx_fid, '%d,%d,%d,%d,%d,%d\n\n', timeSteps, wMin, wMax, webtx_success, webtx_failure, webtx_waiting);
    
    rando_success = rando_node.CountSuccesses();
    rando_failure = rando_node.CountFailures();
    rando_waiting = rando_node.CountWaits();
    fprintf(rando_fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
    fprintf(rando_fid, '%d,%d,%d,%d,%d,%d\n\n', timeSteps, wMin, wMax, rando_success, rando_failure, rando_waiting);
    
    video_success = video_node.CountSuccesses();
    video_failure = video_node.CountFailures();
    video_waiting = video_node.CountWaits();
    fprintf(video_fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
    fprintf(video_fid, '%d,%d,%d,%d,%d,%d\n\n', timeSteps, wMin, wMax, video_success, video_failure, video_waiting);
    
    
    % Dump the history logs
    fprintf(files_fid, '%s,%s,%s\n', 'state_index', 'state_type', 'transition_type');
    fprintf(webtx_fid, '%s,%s,%s\n', 'state_index', 'state_type', 'transition_type');
    fprintf(rando_fid, '%s,%s,%s\n', 'state_index', 'state_type', 'transition_type');
    fprintf(video_fid, '%s,%s,%s,%s\n', 'state_index', 'state_type', 'transition_type', 'frame_type');
    
    files_markov = files_node.mainChain;
    webtx_markov = webtx_node.mainChain;
    rando_markov = rando_node.mainChain;
    video_markov = video_node.mainChain;

    for i=1:timeSteps
        fprintf(files_fid, '%d,%d,%d\n',    files_markov.indexHistory(i), files_markov.stateTypeHistory(i), files_markov.transitionHistory(i));
        fprintf(files_csv, '%d,%d,%d\n',    files_markov.indexHistory(i), files_markov.stateTypeHistory(i), files_markov.transitionHistory(i));
        
        fprintf(webtx_fid, '%d,%d,%d\n',    webtx_markov.indexHistory(i), webtx_markov.stateTypeHistory(i), webtx_markov.transitionHistory(i));
        fprintf(webtx_csv, '%d,%d,%d\n',    webtx_markov.indexHistory(i), webtx_markov.stateTypeHistory(i), webtx_markov.transitionHistory(i));
        
        fprintf(rando_fid, '%d,%d,%d\n',    rando_markov.indexHistory(i), rando_markov.stateTypeHistory(i), rando_markov.transitionHistory(i));
        fprintf(rando_csv, '%d,%d,%d\n',    rando_markov.indexHistory(i), rando_markov.stateTypeHistory(i), rando_markov.transitionHistory(i));
        
        fprintf(video_fid, '%d,%d,%d\n',    video_markov.indexHistory(i), video_markov.stateTypeHistory(i), video_markov.transitionHistory(i));
        fprintf(video_csv, '%d,%d,%d\n',    video_markov.indexHistory(i), video_markov.stateTypeHistory(i), video_markov.transitionHistory(i));
    end
    
    fprintf('Done!\n');
    fclose(files_fid);
    fclose(files_csv);
    fclose(webtx_fid);
    fclose(webtx_csv);
    fclose(rando_fid);
    fclose(rando_csv);
    fclose(video_fid);
    fclose(video_csv);
end % for pSuccess