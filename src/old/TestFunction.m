function TestFunction(  )

verboseSetup = false;
verboseExecute = false;
verbosePrint = false;

timeSteps = 10;
wMin = 2;
wMax = 4;
pSuccess = 0.0;
pArrive = 1.0;
pEnter = 0.0;
nMaxPackets = 4;
nInterarrival = 0;

[m, ~] = dcf_matrix_collapsible.CalculateDimensions(wMin, wMax);

% Separate simulation for each node type
simulator = dcf_simulator_oo(pSuccess, 0.0);

dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = wMin;
dcf_matrix.nPkt = nMaxPackets;
dcf_matrix.nInterarrival = nInterarrival;
dcf_matrix.pEnterInterarrival = pEnter;
dcf_matrix.pRawArrive = pArrive;
dcf_matrix.bFixedPacketchain = true;

nodeName = sprintf('node %d', 1);
simulator.add_dcf_matrix(nodeName, dcf_matrix);

fName = sprintf('./results/test.csv');
fprintf('Setting up: %s\n', fName);
simulator.Setup(verboseSetup);

fprintf('\n+Running %s simulation\n', fName);
simulator.Steps(timeSteps, verboseExecute);

fprintf('Dumping out results...\n');
simulator.PrintResults(verbosePrint);

fprintf('Writing results to file...\n');

fid = fopen(fName, 'w');
if (fid == -1)
    disp('Error: could not open some file for output.');
    return;
end

node = simulator.GetNode(1);

% Dump the basic summary data
%success = node.CountSuccesses();
%failure = node.CountFailures();
%waiting = node.CountWaits();
%fprintf(fid, '%s,%s,%s,%s,%s,%s\n', 'timeSteps', 'wMin', 'wMax', 'success', 'failure', 'wait');
%fprintf(fid, '%d,%d,%d,%d,%d,%d\n\n', timeSteps, wMin, wMax, success, failure, waiting);


% Dump the history logs
fprintf(fid, '%s,%s,%s\n', 'state_index', 'state_type', 'transition_type');
markov = node.mainChain;

for i=1:timeSteps
    index = ( markov.indexHistory(i));
    state = char( dcf_state_type( markov.stateTypeHistory(i) ));
    trans = char( dcf_transition_type( markov.transitionHistory(i) ));
    
    fprintf(fid, '%d,%s,%s\n', index, state, trans);
    
    fprintf('%d\t%s\t%s\n', index, state, trans);
end

fprintf('Done!\n');
fclose(fid);

end

