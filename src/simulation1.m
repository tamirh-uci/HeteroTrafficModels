% Simulation parameters
timeSteps = 10000; 
numberOfNodes = 1;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 0;

% PHY layer parameters -- using FHSS (frequency hopping spread spectrum)
Wmin = 8;
Wmax = 32;

% Precompute variables for the DCF model
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% Run the different series of simulations
for i = 1:numberOfNodes
    fprintf('\n---- Simulating %d nodes ----\n', i);
    
    simulator = dcf_simulator_oo(pSuccess, 0);
    for j = 1:i
        node = dcf_matrix_factory(pArrive, pEnter, m, Wmin, 1, 0);
        nodeName = sprintf('node%d', j);
        simulator.add_dcf_matrix(nodeName, node);
    end
    simulator.Setup();
    simulator.Steps(timeSteps, true);
    simulator.PrintResults(false);
    
    % open the output results file
    fName = sprintf('sim_data_%d', i);
    fid = fopen(fName, 'w');
    if (fid == -1)
        disp('Error: could not open the file for output.');
        exit;
    end
    
    % write the simulation parameters and results for each node to the file
    fprintf(fid, '%d,%d,%f,%f,%f,%d,%d\n', timeSteps, i, pSuccess, pArrive, pEnter, Wmin, Wmax);
    for j = 1:i
        node = simulator.GetNode(j);
        fprintf(fid, '%d,%d,%d\n', node.CountSuccesses(), node.CountFailures(), node.CountWaits());
    end
    fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());
    
    % flush and cleanup
    fclose(fid);
end
