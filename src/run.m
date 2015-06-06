run_set_path

% Load in a real video file to test against
vu = video_util();
vu.setup();
vu.nFrames = 800; % a bit over 30 seconds
vu.prep();

% max number of nodes in system
nDatanodes = 0;
nVidnodes = 3;

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
%simParams.pSingleSuccess = [0.20, 0.60, 1.0];
simParams.pSingleSuccess = [1.0];

% Video node stuff
% Grab values from our actual loaded file
timesteps = 10 * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)
bps = vu.bpsSrcC;

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
allMangledPsnr = cell(nSimulations, nVariations);
allMangledSnr = cell(nSimulations, nVariations);
meanMangledPsnr = zeros(nSimulations, nVariations);
meanMangledSnr = zeros(nSimulations, nVariations);
medMangledPsnr = zeros(nSimulations, nVariations);
medMangledSnr = zeros(nSimulations, nVariations);

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
        
        badPacketIndices = variationResults.nodeSlowWaitIndices{1};
        [allMangledPsnr{i, j}, allMangledSnr{i, j}] = vu.testMangle(badPacketIndices, 'sC', 'dC');
        
        cleanPsnr = allMangledPsnr{i, j}( isfinite(allMangledPsnr{i, j}) );
        cleanSnr = allMangledSnr{i, j}( isfinite(allMangledSnr{i, j}) );
        
        meanMangledPsnr(i, j) = mean(cleanPsnr);
        meanMangledSnr(i, j) = mean(cleanSnr);
        medMangledPsnr(i, j) = median(cleanPsnr);
        medMangledSnr(i, j) = median(cleanSnr);
    end
end

plot_rundata( 1, '', 'Time spent waiting over threshold', ...
    'Time (microseconds)', labels, plotColors, nVariations, nSimulations, overThresholdTime );

plot_rundata( 2, '', 'Packets waiting over threshold', ...
    'Packet Count', labels, plotColors, nVariations, nSimulations, overThresholdCount );

plot_rundata( 3, '', 'Mean PSNR after dropped packets', ...
    'PSNR', labels, plotColors, nVariations, nSimulations, meanMangledPsnr);

plot_rundata( 4, '', 'Median SNR after dropped packets', ...
    'PSNR', labels, plotColors, nVariations, nSimulations, medMangledPsnr);

plot_rundata( 5, '', 'Mean SNR after dropped packets', ...
    'SNR', labels, plotColors, nVariations, nSimulations, meanMangledSnr );

plot_rundata( 6, '', 'Median SNR after dropped packets', ...
    'SNR', labels, plotColors, nVariations, nSimulations, medMangledSnr );
