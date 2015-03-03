% Simulation parameters
timeSteps = 1000; 
numNormals = 5;
numMedias = 5;
numberOfNodes = numNormals + numMedias;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 0;
Wmin = 2;
Wmax = 16;

throughputValues = zeros(1, numberOfNodes);
successValues = zeros(1, numberOfNodes);
failureValues = zeros(1, numberOfNodes);

for i = 1:numberOfNodes
    numN = 0;
    numM = 0;
    if (i <= numNormals) 
        numN = i;
    else 
        numN = numNormals;
        numM= i - numNormals;
    end
    [simulator] = create_simulation(numN, numM, pSuccess, pArrive, pEnter, Wmin, Wmax);

    simulator.Steps(timeSteps, false);
    simulator.PrintResults(false);

    fName = sprintf('sim_data_%d', i);
    fid = fopen(fName, 'w');
    if (fid == -1)
        disp('Error: could not open the file for output.');
        exit;
    end
    
    % write the simulation parameters and results for each node to the file
    fprintf(fid, '%d,%d,%f,%f,%f,%d,%d\n', timeSteps, i, pSuccess, pArrive, pEnter, Wmin, Wmax);
%     for j = 1:i
%         node = simulator.GetNode(j);
%         fprintf(fid, '%d,%d,%d\n', node.CountSuccesses(), node.CountFailures(), node.CountWaits());
%     end
    fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());
    
    % flush and cleanup
    fclose(fid);
    
    % Accumulate values
    throughputValues(1, i) = simulator.GetTransmit();
    successValues(1, i) = simulator.GetSuccess();
    failureValues(1, i) = simulator.GetFailures();
end

figureId = 1;
figure(figureId)
figureId = figureId + 1; 

x = zeros(1, numberOfNodes);
for i = 1:numberOfNodes
    x(1, i) = i;
end
plot(x, throughputValues, x, successValues, x, failureValues);

title([sprintf('Metrics for %d %d Nodes', numN, numM)]);
xlabel('Number of Nodes');
ylabel('Metric Value');

fileName = sprintf('fig-%d.fig', figureId);
saveas(gcf,['.', filesep, fileName], 'fig');  % gca?


