run_set_path

% Load in a real video file to test against
vu = video_util();
vu.setup();
vu.nFrames = 800; % a bit over 30 seconds
vu.prep();

doVideoMangle = false;
slotsPerVPacket = 1;
qualityThresholdMicrosec = 50000; % 50 miliseconds
nTxBins = 250;

% max number of nodes in system
nVidnodes = 0;
nDatanodes = 1;

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
%simParams.pSingleSuccess = [0.60, 0.80, 1.0];
simParams.pSingleSuccess = 1.0;
simParams.pMultiSuccess = 1.0;
simParams.physical_type = phys80211_type.B;
wMin = 8;
wMax = 16;

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)

% File node stuff
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 4.0;
fileWaityness = 2.0;

vidParams = traffic_video_stream(1, wMin, wMax, vu.bpsSrcC, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

nSimulations = max(nDatanodes, 1) * max(nVidnodes, 1);
results = cell( 1, nSimulations );

sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, qualityThresholdMicrosec, 1, max(0,nDatanodes) );
sim.Run(doVideoMangle);

results{1} = sim.simResults;
plotColors = sim.plotColors;

nVariations = size(results{1,1}, 2);
nNodes = zeros(1, nSimulations);
labels = cell(1, nVariations);

overThresholdCount = zeros( nSimulations, nVariations );
overThresholdTime = zeros( nSimulations, nVariations );
txHistory = cell( nSimulations, nVariations );
txBinnedHistory = cell( nSimulations, nVariations );

allMangledPsnr = cell(nSimulations, nVariations);
allMangledSnr = cell(nSimulations, nVariations);
allMangledSSIM = cell(nSimulations, nVariations);

meanMangledPsnr = zeros(nSimulations, nVariations);
meanMangledSnr = zeros(nSimulations, nVariations);
medMangledPsnr = zeros(nSimulations, nVariations);
medMangledSnr = zeros(nSimulations, nVariations);
medMangledSSIM = zeros(nSimulations, nVariations);

r = results{1};
for i=1:nVariations
    labels{i} = r{i}.label;
end

simIndex = 1;
if (nDatanodes > 0)
    for vi=1:nVidnodes
        for di=1:nDatanodes
            nNodes(simIndex) = vi + di;
            
            sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, vi, di );
            sim.Run(doVideoMangle);
            results{simIndex} = sim.simResults;
            
            simIndex = simIndex + 1;
        end
    end
else
    for vi=1:nVidnodes
        nNodes(simIndex) = vi;
        
        sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, vi, 0 );
        sim.Run(doVideoMangle);
        results{simIndex} = sim.simResults;
        
        simIndex = simIndex + 1;
    end
end

for i=1:nSimulations
    allResults = results{i};
    
    for j=1:nVariations
        variationResults = allResults{j};
        
        overThresholdCount(i, j) = variationResults.nodeSlowWaitCount(1);
        overThresholdTime(i, j) = variationResults.nodeSlowWaitQuality(1);
        
        tx = variationResults.nodeTxHistory;
        txHistory{i, j} = tx;
        
        nNodes = size( tx, 2 );
        binned = zeros(nNodes, nTxBins);
        for k=1:nNodes
            nodeHistory = tx{k};
            sizeHistory = size(nodeHistory, 2);
            binSize = ceil( sizeHistory / nTxBins );
            
            for binIndex=1:nTxBins
                startIndex = 1 + (binIndex-1)*binSize;
                endIndex = startIndex + binSize - 1;
                if (endIndex > sizeHistory)
                    endIndex = sizeHistory;
                end
                binned(k, binIndex) = sum( nodeHistory(startIndex:endIndex) );
            end
            
            txBinnedHistory{i,j} = binned;
        end

%         badPacketIndices = variationResults.nodeSlowWaitIndices{1};
%         [allMangledPsnr{i, j}, allMangledSnr{i, j}] = vu.testMangle(badPacketIndices, 'sC', 'dC');

        allMangledPsnr{i, j} = variationResults.allMangledPsnr;
        allMangledSnr{i, j} = variationResults.allMangledSnr;
        allMangledSSIM{i, j} = variationResults.allMangledSSIM;
                 
        cleanPsnr = allMangledPsnr{i, j}( isfinite(allMangledPsnr{i, j}) );
        cleanSnr = allMangledSnr{i, j}( isfinite(allMangledSnr{i, j}) );
        cleanSSIM = allMangledSSIM{i, j}( isfinite(allMangledSSIM{i, j}) );
         
        meanMangledPsnr(i, j) = mean(cleanPsnr);
        meanMangledSnr(i, j) = mean(cleanSnr);
        medMangledPsnr(i, j) = median(cleanPsnr);
        medMangledSnr(i, j) = median(cleanSnr);
        medMangledSSIM(i, j) = median(cleanSSIM);
    end
end

fprintf('Timesteps = %d\n', timesteps);

channelBps = phys80211.EffectiveMaxDatarate(simParams.physical_type, simParams.physical_payload, simParams.physical_speed, 1);
dataBps = (fileBigness/fileWaityness) * (channelBps/wMin);
fprintf('%s Channel Speed: %.2fMbps\n', phys80211.Name(simParams.physical_type), (channelBps/1000000));
fprintf('Desired Video Speed: %.2fMbps\n', (vu.bpsSrcC/1000000));
fprintf('Desired Data Speed: %.2fMbps\n', (dataBps/1000000));

% Late packets
nPlots = 1;
plot_rundata( nPlots, [2 1], 1, 'Time spent waiting over threshold (lower better)', ...
    'Time (microseconds)', labels, plotColors, nVariations, nSimulations, overThresholdTime );
plot_rundata( nPlots, [2 1], 2, 'Packets waiting over threshold (lower better)', ...
    'Packet Count', labels, plotColors, nVariations, nSimulations, overThresholdCount );
savefig( sprintf('./../results/figures/VN%d Late Packets.fig', nVidnodes) );


% TEMP OVERRIDE
labels{1} = 'Video Node 1';
labels{2} = 'Video Node 2';
labels{3} = 'Data Node 1';

% Data transfer
for i=1:nSimulations
    nPlots = 1 + nPlots;
    plotIndex = 0;
    
    for j=1:nVariations
        plotIndex = 1 + plotIndex;
        binned = txBinnedHistory{i,j};
        nNodes = size(binned, 1);
        
        plot_timedata( nPlots, [nVariations 1], plotIndex, 'title', ...
            'transfers', labels, plotColors(nVariations+1:nVariations+nNodes,:), nNodes, nTxBins, binned);
    end
end

% TEMP OVERRIDE
labels{1} = 'pSuccess=0.2';
labels{2} = 'pSuccess=0.6';
labels{3} = 'pSuccess=1.0';

if (doVideoMangle)
    % PSNR
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, [2 1], 1, 'Mean PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors(1:nVariations,:), nVariations, nSimulations, meanMangledPsnr);
    plot_rundata( nPlots, [2 1], 2, 'Median PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors(1:nVariations,:), nVariations, nSimulations, medMangledPsnr);
    savefig( sprintf('./../results/figures/VN%d PSNR.fig', nVidnodes) );

    % SNR
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, [2 1], 1, 'Mean SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors(1:nVariations,:), nVariations, nSimulations, meanMangledSnr );
    plot_rundata( nPlots, [2 1], 1, 'Median SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors(1:nVariations,:), nVariations, nSimulations, medMangledSnr );
    savefig( sprintf('./../results/figures/VN%d SNR.fig', nVidnodes) );

    % SSIM
    nPlots = 1 + nPlots;
    plot_rundata( nPlots, 'Median SSIM Similarity with dropped packets(lower better)', ...
        'SNR', labels, plotColors(1:nVariations,:), nVariations, nSimulations, medMangledSSIM );
    savefig( sprintf('./../results/figures/VN%d SSIM.fig', nVidnodes) );
end
