run_set_path;
close all;

% Load in a real video file to test against
fullStartFrame = 150;
nTotalFrames = 250; % 250 is about 10 seconds
framesPerChunk = 30;
nChunks = ceil(nTotalFrames/framesPerChunk);
fullEndFrame = fullStartFrame + nTotalFrames - 1;

vuTotalPackets = 0;
vuAvgBps = 0;
vuCells = cell(1, nChunks);
for i=1:nChunks
    startFrame = fullStartFrame + (i-1)*framesPerChunk;
    endFrame = min(fullEndFrame, startFrame + framesPerChunk - 1);
    
    vu = video_util();
    vu.frameStart = startFrame;
    vu.nFrames = endFrame - startFrame + 1;
    vu.prep();
    
    vuTotalPackets = vuTotalPackets + vu.nPacketsSrcC;
    vuAvgBps = vuAvgBps + (vu.bpsSrcC / nChunks);
    
    vuCells{i} = vu;
end

plotTrafficSum = true;
cleanCache = true;
doVideoMangle = true;
slotsPerVPacket = 15;
qualityThresholdMicrosec = 75000; % 75 miliseconds
nTxBins = 100;
movAvgWindow = 4;

% max number of nodes in system
nMaxVidNodes = 1;
nMaxDataNodes = 1;

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();

simParams.physical_type = phys80211_type.B;
wMin = 8;
wMax = 16;

simParams.pSingleSuccess = 1.0;
varLabels = cell(1,1);
varLabels{1} = 'p=1.0';

%simParams.pSingleSuccess = [0.60, 0.80, 1.0];
%varLabels = cell(1,3);
%varLabels{1} = 'p=0.6';
%varLabels{2} = 'p=0.8';
%varLabels{3} = 'p=1.0';
nVariations = size(varLabels,2); % TODO: Calculate this from simParams

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vuTotalPackets; % how many packets we'll need for our video (assume pretty good conditions)

% File node stuff
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 2.0;
fileWaityness = 20.0;

vidParams = traffic_video_stream(1, wMin, wMax, vuAvgBps, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

nSoftMaxVidNodes = max(nMaxVidNodes, 1);
nSoftMaxDataNodes = max(nMaxDataNodes, 1);

nSimulations = nSoftMaxVidNodes * nSoftMaxDataNodes;
results = cell( 1, nSimulations );

nNodes = zeros(1, nSimulations);
nodeLabels = cell(1 , nSimulations);

overThresholdCount = zeros( nSimulations, nVariations );
overThresholdTime = zeros( nSimulations, nVariations );
txHistory = cell( nSimulations, nVariations );
txBinnedHistory = cell( nSimulations, nVariations );

allMangledPsnr = cell(nSimulations, nVariations);
allMangledSnr = cell(nSimulations, nVariations);

meanMangledPsnr = zeros(nSimulations, nVariations);
meanMangledSnr = zeros(nSimulations, nVariations);
medMangledPsnr = zeros(nSimulations, nVariations);
medMangledSnr = zeros(nSimulations, nVariations);

simIndex = 1;

for vi = 1:nSoftMaxVidNodes
    if (nMaxVidNodes==0)
        nVidNodes = 0;
    else
        nVidNodes = vi;
    end

    for di = 0:nSoftMaxDataNodes
        if (nMaxDataNodes==0)
            nDataNodes = 0;
        else
            nDataNodes = di;
        end
        
        sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vuCells, qualityThresholdMicrosec, nVidNodes, nDataNodes );
        sim.cleanCache = cleanCache;
        sim.Run(doVideoMangle);
        
        if (di==0)
            resultsBaseline = sim.simResults{1};
        else
            results{simIndex} = sim.simResults;
            results{simIndex} = sim.simResults;
            nodeLabels{simIndex} = sim.NodeLabels();
            nNodes(simIndex) = nVidNodes + nDataNodes;
            simIndex = simIndex + 1;
        end
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

        allMangledPsnr{i, j} = variationResults.allMangledPsnr;
        allMangledPsnr{i, j}( ~isfinite(allMangledPsnr{i, j}) ) = 0;
        
        meanMangledPsnr(i, j) = mean( allMangledPsnr{i, j} );
        medMangledPsnr(i, j) = median( allMangledPsnr{i, j} );
    end
end

baselinePsnr = resultsBaseline.allMangledPsnr;
baselinePsnr( ~isfinite(baselinePsnr) ) = 0;


if (~exist('./../results/figures/', 'dir'))
    mkdir('./../results/figures/');
end

channelBps = phys80211.EffectiveMaxDatarate(simParams.physical_type, simParams.physical_payload, simParams.physical_speed, 1);
maxSinglenodeBps = (channelBps/wMin);

dataBps = ( fileBigness / (0.5*fileWaityness+wMin) ) * channelBps;
elapsedMicroseconds = timesteps * phys80211.TransactionTime(simParams.physical_type, simParams.physical_payload, simParams.physical_speed);

fprintf('Timesteps = %d, time=%f s\n', timesteps, (elapsedMicroseconds/1000000));
fprintf('%s Channel Speed: %.2fMbps\n', phys80211.Name(simParams.physical_type), (channelBps/1000000));
fprintf('Max Node Speed: %.2fMbps\n', (maxSinglenodeBps/1000000));
fprintf('Desired Video Speed: %.2fMbps\n', nVidNodes*(vuAvgBps/1000000));
fprintf('Desired Data Speed: %.2fMbps\n', nDataNodes*(dataBps/1000000));

% Late packets
nPlots = 1;
plotColors = distinguishable_colors(nVariations);
plot_rundata( nPlots, [2 1], 1, 'Time spent waiting over threshold (lower better)', ...
    'Time (microseconds)', varLabels, plotColors, nVariations, nSimulations, overThresholdTime );
plot_rundata( nPlots, [2 1], 2, 'Packets waiting over threshold (lower better)', ...
    'Packet Count', varLabels, plotColors, nVariations, nSimulations, overThresholdCount );
savefig( sprintf('./../results/figures/VN%d Late Packets.fig', nVidNodes) );


% Data transfer
if (plotTrafficSum)
    for i=1:nSimulations
        summedLabels = cell(1, 2);
        summedLabels{1} = 'video node';
        summedLabels{2} = sprintf('%dx data nodes', i);
        
        nPlots = 1 + nPlots;
        plotIndex = 0;
        
        for j=1:nVariations
            binned = txBinnedHistory{i, j};
            summedBin = zeros( 2, size(binned,2) );
            % Copy over the 1st row, that's our video data history
            summedBin(1,:) = binned(1,:);
            
            % Sum up the rest of the rows, that's our other data
            summedBin(2,:) = sum( binned(2:end,:), 1 );
            
            plotIndex = 1 + plotIndex;
            nNodes = size(summedBin, 1);

            plotColors = distinguishable_colors(nNodes);
            plot_timedata( nPlots, [nVariations 1], plotIndex, sprintf('Data Transfer %s', varLabels{j}), ...
                'transfers', summedLabels, plotColors, nNodes, nTxBins, summedBin);
        end
    end
else
    % Regular, non-summed version
    for i=1:nSimulations
        nPlots = 1 + nPlots;
        plotIndex = 0;

        for j=1:nVariations
            plotIndex = 1 + plotIndex;
            binned = txBinnedHistory{i,j};
            nNodes = size(binned, 1);

            plotColors = distinguishable_colors(nNodes);
            plot_timedata( nPlots, [nVariations 1], plotIndex, sprintf('Data Transfer %s', varLabels{j}), ...
                'transfers', nodeLabels{i}, plotColors, nNodes, nTxBins, binned);
        end
    end
end

if (doVideoMangle)
    timedataLabels = cell(1, nSimulations);
    for i=1:nSimulations
        timedataLabels{i} = sprintf('%dx data nodes', i);
    end
end
