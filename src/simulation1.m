% Simulation parameters
timeSteps = 10000; 
numNormals = 5;
numMedias = 0;
numberOfNodes = numNormals + numMedias;
pSuccess = 1.0; 
pArrive = 1.0;
pEnter = 0;
Wmin = 2;
Wmax = 16;

for i = 1:numberOfNodes
    numN = 0;
    numM = 0;
    if (i < numNormals) 
        numN = i;
    else 
        numN = numNormals;
        numMedias = i - numNormals;
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
    for j = 1:i
        node = simulator.GetNode(j);
        fprintf(fid, '%d,%d,%d\n', node.CountSuccesses(), node.CountFailures(), node.CountWaits());
    end
    fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());
    
    % flush and cleanup
    fclose(fid);
    
    figureId = 0;
 Generate a plot for each one
 figureId = 1;
 for messageIndex = 1:numMessages
     for childIndex = 1:numChildren
         for p1Index = 1:numP1probs
             temp = zeros(numP2probs, numNodes);
             for p2Index = 1:numP2probs
                for n = 1:numNodes
                   temp(p2Index, n) = mean(times(messageIndex, childIndex, p1Index, p2Index, n,:));  the second element is the average time
                end
             end
             figure(figureId);
             figureId = figureId + 1; 
             plot(temp);
             set(gca,'XTickLabel',{'0.1', '0.2', '0.3', '0.4', '0.5', '0.6', '0.7','0.8', '0.9', '1.0'});
             title([sprintf('Metrics for %d %d Nodes', numN, numN);
             xlabel('Authentication Probability');
             ylabel('Average Re-Key Time (epochs)');
             
             fileName = sprintf('fig-%d.fig', figureId);
             saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
         end
     end
 end
end

