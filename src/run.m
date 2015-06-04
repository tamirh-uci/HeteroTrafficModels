run_set_path

% max number of nodes in system
nDatanodes = 0;
nVidnodes = 10;

% Shared params
simName = 'interference';
simParams = dcf_simulation_params();
timesteps = 1000;
simParams.pSingleSuccess = [0.20, 0.60, 1.0];

% Video node stuff
bps = 800000;

% File node stuff
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 1.0;
fileWaityness = 1.0;
wMin = 8;
wMax = 16;

vidParams = traffic_video_stream(1, wMin, wMax, bps, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

nSimulations = max(nDatanodes, 1) * max(nVidnodes, 1);
results = cell( 1, nSimulations );
[results{1}, plotColors] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, max(0,nDatanodes), 1 );
nVariations = size(results{1,1}, 2);
nNodes = zeros(1, nSimulations);
labels = cell(1, nVariations);

overThresholdCount = zeros( nSimulations, nVariations );
overThresholdTime = zeros( nSimulations, nVariations );
transferCount = zeros( nSimulations, nVariations, timesteps );

r = results{1};
for i=1:nVariations
    labels{i} = r{i}.label;
end

simIndex = 1;
if (nDatanodes > 0)
    for vi=1:nVidnodes
        for di=1:nDatanodes
            nNodes(simIndex) = vi + di;
            [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, di, vi);
            simIndex = simIndex + 1;
        end
    end
else
    for vi=1:nVidnodes
        nNodes(simIndex) = vi;
        [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, 0, vi );
        simIndex = simIndex + 1;
    end
end

for i=1:nSimulations
    allResults = results{i};
    
    for j=1:nVariations
        variationResults = allResults{j};
        
        overThresholdCount(i, j) = variationResults.nodeSlowWaitCount(1);
        overThresholdTime(i, j) = variationResults.nodeSlowWaitQuality(1);
        transferCount(i, j, :) = variationResults.nodeTxHistory{1};
    end
end

plot_rundata( 1, '', 'Time spent waiting over threshold', ...
    'Time (microseconds)', labels, plotColors, nVariations, nSimulations, overThresholdTime );

plot_rundata( 2, '', 'Packets waiting over threshold', ...
    'Packet Count', labels, plotColors, nVariations, nSimulations, overThresholdCount );

%figure(3);
%ax = axes;
%hold(ax, 'on');
%plot(0);
%for j=1:nVariations
%    simTransferCount= transferCount(:,j);
%    plot(simTransferCount, 'Color', plotColors(j,:));
%end
%hold(ax, 'off');
%title('Total data transferred by main node');
%xlabel('Number of nodes');
%ylabel('Packet Count');
