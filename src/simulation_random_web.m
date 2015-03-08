timeSteps = 10000; 
Wmin = 2;
Wmax = 16;
pSuccess = 1.0;

% Precompute variables for the DCF model
[m, W] = dcf_matrix_collapsible.CalculateDimensions(Wmin, Wmax);

[pArrive1, pEnter1, nPackets1, nInterarrival1] = create_random_parameters();
[pArrive2, pEnter2, nPackets2, nInterarrival2] = create_web_traffic_parameters();

[t1, numArrive1] = size(pArrive1);
[t2, numEnter1] = size(pEnter1);
[t3, numPackets1] = size(nPackets1);
[t4, numInterarrival1] = size(nInterarrival1);
[t5, numArrive2] = size(pArrive2);
[t6, numEnter2] = size(pEnter2);
[t7, numPackets2] = size(nPackets2);
[t8, numInterarrival2] = size(nInterarrival2);

throughput1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
success1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
failure1 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);

throughput2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
success2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
failure2 = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);

allthroughput = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
allsuccess = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);
allfailure = zeros(numArrive1, numEnter1, numPackets1, numInterarrival1, numArrive2, numEnter2, numPackets2, numInterarrival2);

% Cover all combinations
for i1 = 1:numArrive1
    for i2 = 1:numEnter1
        for i3 = 1:numPackets1
            for i4 = 1:numInterarrival1
                for j1 = 1:numArrive2
                    for j2 = 1:numEnter2
                        for j3 = numPackets2 
                            for j4 = numInterarrival2
                                
                                simulator = dcf_simulator_oo(pSuccess, 1.0);
                                
                                randomNode = add_random_node(simulator, m, Wmin, 1, pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4));
                                webNode = add_web_traffic_node(simulator, m, Wmin, 2, pArrive2(j1), pEnter2(j2), nPackets2(j3), nInterarrival2(j4));
                                
                                fName = sprintf('simulation_random_web-%d_%d_%d_%d_%d_%d_%d_%d.sim', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), pArrive2(j1), pEnter2(j2), nPackets2(j3), nInterarrival2(j4));
                                fprintf('\n------------\nrunning test: %s\n', fName);
                                fid = fopen(fName, 'w');
                                if (fid == -1)
                                    disp('Error: could not open the file for output.');
                                    exit;
                                end
                                
                                simulator.Setup(true);
                                simulator.Steps(timeSteps, true);
                                simulator.PrintResults(true);

                                fprintf(fid, '%d,%d,%d\n', timeSteps, Wmin, Wmax);
                                fprintf(fid, '%d,%d,%d\n', simulator.GetNode(1).CountSuccesses(), simulator.GetNode(1).CountFailures(), simulator.GetNode(1).CountWaits());
                                fprintf(fid, '%d,%d,%d\n', simulator.GetNode(2).CountSuccesses(), simulator.GetNode(2).CountFailures(), simulator.GetNode(2).CountWaits());
                                fprintf(fid, '%d,%d,%d\n', simulator.CountSuccesses(), simulator.CountFailures(), simulator.CountWaits());
                                
                                throughput1(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(1).GetTransmit(timeSteps);
                                success1(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(1).GetSuccess();
                                failure1(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(1).GetFailures();
                                
                                throughput2(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(2).GetTransmit(timeSteps);
                                success2(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(1).GetSuccess();
                                failure2(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetNode(1).GetFailures();
                                
                                allthroughput(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetTransmit();
                                allsuccess(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetSuccess();
                                allfailure(i1, i2, i3, i4, j1, j2, j3, j4) = simulator.GetFailures();
                            end
                        end
                    end
                end
            end
        end
    end
end

% Plot variance in each parameter
figureId = 1;
for i1 = 1:numArrive1
    for i2 = 1:numEnter1
        for i3 = 1:numPackets1
            for i4 = 1:numInterarrival1
                
                % Inverarrival variation
                if numInterarrival2 > 1
                for j1 = 1:numArrive2
                    for j2 = 1:numEnter2
                        for j3 = numPackets2 
                            figure(figureId)
                            figureId = figureId + 1; 

                            x = nInterarrival2;
                            throughputValues1 = zeros(1, numInterarrival2);
                            throughputValues2 = zeros(1, numInterarrival2);
                            averageThroughputValues = zeros(1, numInterarrival2);
                            for j4 = 1:numInterarrival2
                                throughputValues1(1, j4) = throughput1(i1, i2, i3, i4, j1, j2, j3, j4);
                                throughputValues2(1, j4) = throughput2(i1, i2, i3, i4, j1, j2, j3, j4);
                                averageThroughputValues(1, j4) = allthroughput(i1, i2, i3, i4, j1, j2, j3, j4);
                            end
                            
                            plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                            title(sprintf('Interarrival Variance'));
                            xlabel('Interarrival Length');
                            ylabel('Throughput');
                            legend('random throughput', 'web node throughput', 'average throughput');

                            fileName = sprintf('simulation_random_web-interarival-%d_%d_%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), pArrive2(j1), pEnter2(j2), nPackets2(j3));
                            saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                        end
                    end
                end
                end
                
                % Arrival variation
                if numArrive2 > 1
                for j2 = 1:numEnter2
                    for j3 = numPackets2 
                        for j4 = numInterarrival2
                            figure(figureId)
                            figureId = figureId + 1; 

                            x = pArrive2;
                            throughputValues1 = zeros(1, numArrive2);
                            throughputValues2 = zeros(1, numArrive2);
                            averageThroughputValues = zeros(1, numArrive2);
                            for j1 = 1:numArrive2
                                throughputValues1(1, j1) = throughput1(i1, i2, i3, i4, j1, j2, j3, j4);
                                throughputValues2(1, j1) = throughput2(i1, i2, i3, i4, j1, j2, j3, j4);
                                averageThroughputValues(1, j1) = allthroughput(i1, i2, i3, i4, j1, j2, j3, j4);
                            end
                            
                            plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                            title(sprintf('pArrival Variance'));
                            xlabel('pArrival');
                            ylabel('Throughput');
                            legend('random throughput', 'web node throughput', 'average throughput');

                            fileName = sprintf('simulation_random_web-parrival-%d_%d_%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), pEnter2(j2), nPackets2(j3), nInterarrival2(j4));
                            saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                        end
                    end
                end
                end
                
                % Enter variation
                if numEnter2 > 1
                for j3 = numPackets2 
                    for j4 = numInterarrival2
                        for j1 = 1:numArrive2
                            figure(figureId)
                            figureId = figureId + 1; 

                            x = pEnter2;
                            throughputValues1 = zeros(1, numEnter2);
                            throughputValues2 = zeros(1, numEnter2);
                            averageThroughputValues = zeros(1, numEnter2);
                            for j2 = 1:numEnter2
                                throughputValues1(1, j2) = throughput1(i1, i2, i3, i4, j1, j2, j3, j4);
                                throughputValues2(1, j2) = throughput2(i1, i2, i3, i4, j1, j2, j3, j4);
                                averageThroughputValues(1, j2) = allthroughput(i1, i2, i3, i4, j1, j2, j3, j4);
                            end
                            
                            plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                            title(sprintf('pEnter Variance'));
                            xlabel('pEnter');
                            ylabel('Throughput');
                            legend('random throughput', 'web node throughput', 'average throughput');

                            fileName = sprintf('simulation_random_web-penter-%d_%d_%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), pArrive2(j1), nPackets2(j3), nInterarrival2(j4));
                            saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                        end
                    end
                end
                end
                
                % Max size variation
                if numPackets2 > 1
                for j4 = numInterarrival2
                    for j1 = 1:numArrive2
                        for j2 = 1:numEnter2
                            figure(figureId)
                            figureId = figureId + 1; 

                            x = nPackets2;
                            throughputValues1 = zeros(1, numPackets2);
                            throughputValues2 = zeros(1, numPackets2);
                            averageThroughputValues = zeros(1, numPackets2);
                            for j3 = 1:numPackets2
                                throughputValues1(1, j3) = throughput1(i1, i2, i3, i4, j1, j2, j3, j4);
                                throughputValues2(1, j3) = throughput2(i1, i2, i3, i4, j1, j2, j3, j4);
                                averageThroughputValues(1, j3) = allthroughput(i1, i2, i3, i4, j1, j2, j3, j4);
                            end
                            
                            plot(x, throughputValues1, x, throughputValues2, x, averageThroughputValues);

                            title(sprintf('Max Packet Size Variance'));
                            xlabel('Max Packet Size');
                            ylabel('Throughput');
                            legend('random throughput', 'web node throughput', 'average throughput');

                            fileName = sprintf('simulation_random_web-maxpackets-%d_%d_%d_%d_%d_%d_%d.fig', pArrive1(i1), pEnter1(i2), nPackets1(i3), nInterarrival1(i4), pArrive2(j1), pEnter2(j2), nInterarrival2(j4));
                            saveas(gcf,['.', filesep, fileName], 'fig');  % gca?
                        end
                    end
                end
                end
            end
        end
    end
end


