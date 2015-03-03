% Simulation parameters
timeSteps = 100; 
numNormals = 2;
numMultiMedia = 0;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 0;

for i = 1:numberOfNodes
    simulator = create_simulation(numNormals, numMedias, pSuccess, pArrive, pEnter);

    simulator.Steps(timeSteps);
    simulator.PrintResults(true);

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

