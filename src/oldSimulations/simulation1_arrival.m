% Simulation parameters
timeSteps = 1000; 
numNormals = 2;
numMedias = 0;
numberOfNodes = numNormals + numMedias;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 1.0;
nMaxPackets = 1;
nInterarrival = 2;
Wmin = 2;
Wmax = 16;

[simulator] = create_simulation(numNormals, numMedias, pSuccess, pArrive, pEnter, Wmin, Wmax, nMaxPackets, nInterarrival);
simulator.Steps(timeSteps, false);
simulator.PrintResults(false);

fid = fopen('simulaton1_arrival.out', 'w');
if (fid == -1)
    disp('Error: could not open the file for output.');
    exit;
end

% write the simulation parameters and results for each node to the file
fprintf(fid, '%d,%d,%f,%f,%f,%d,%d\n', timeSteps, numberOfNodes, pSuccess, pArrive, pEnter, Wmin, Wmax);
for i = 1:numberOfNodes
    node = simulator.GetNode(i);
    fprintf(fid, '%d,%d,%d\n', node.CountSuccesses(), node.CountFailures(), node.CountWaits());
end
fprintf(fid, '%f,%f,%f,%d,%d,%d\n', simulator.GetSuccess() * 100.0, simulator.GetTransmit() * 100.0, simulator.GetFailures() * 100.0, simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());

% flush and cleanup
fclose(fid);
