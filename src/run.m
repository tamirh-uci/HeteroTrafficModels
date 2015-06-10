run_set_path

% Load in a real video file to test against
vu = video_util();
vu.setup();
vu.nFrames = 800; % a bit over 30 seconds
vu.prep();

doVideoMangle = false;
slotsPerVPacket = 5;

% max number of nodes in system
nDatanodes = 0;
nVidnodes = 2;

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
simParams.pSingleSuccess = [0.20, 0.60, 1.0];
simParams.physical_type = phys80211_type.B;

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)
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
[results{1}, plotColors] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, max(0,nDatanodes), 1 );
nVariations = size(results{1,1}, 2);
nNodes = zeros(1, nSimulations);
labels = cell(1, nVariations);

overThresholdCount = zeros( nSimulations, nVariations );
overThresholdTime = zeros( nSimulations, nVariations );
transferCount = zeros( nSimulations, nVariations, timesteps );

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

% TEMP OVERRIDE
labels{1} = 'pSuccess=0.2';
labels{2} = 'pSuccess=0.6';
labels{3} = 'pSuccess=1.0';

simIndex = 1;
if (nDatanodes > 0)
    for vi=1:nVidnodes
        for di=1:nDatanodes
            nNodes(simIndex) = vi + di;
            [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, di, vi );
            simIndex = simIndex + 1;
        end
    end
else
    for vi=1:nVidnodes
        nNodes(simIndex) = vi;
        [results{simIndex}, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, 0, vi );
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

nPlots = 1;
plot_rundata( nPlots, sprintf('./../results/figures/VN%d Time spent waiting over 50ms.fig', nVidnodes), 'Time spent waiting over threshold (lower better)', ...
    'Time (microseconds)', labels, plotColors, nVariations, nSimulations, overThresholdTime );

nPlots = nPlots + 1;
plot_rundata( nPlots, sprintf('./../results/figures/VN%d Packets waiting over 50ms.fig', nVidnodes), 'Packets waiting over threshold (lower better)', ...
    'Packet Count', labels, plotColors, nVariations, nSimulations, overThresholdCount );

if (doVideoMangle)
    nPlots = nPlots + 1;
    plot_rundata( nPlots, sprintf('./../results/figures/VN%d Mean PSNR with dropped packets.fig', nVidnodes), 'Mean PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors, nVariations, nSimulations, meanMangledPsnr);

    nPlots = nPlots + 1;
    plot_rundata( nPlots, sprintf('./../results/figures/VN%d Median PSNR with dropped packets.fig', nVidnodes), 'Median PSNR with dropped packets (lower better)', ...
        'PSNR', labels, plotColors, nVariations, nSimulations, medMangledPsnr);

    nPlots = nPlots + 1;
    plot_rundata( nPlots, sprintf('./../results/figures/VN%d Mean SNR with dropped packets.fig', nVidnodes), 'Mean SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, meanMangledSnr );

    nPlots = nPlots + 1;
    plot_rundata( nPlots, sprintf('./../results/figures/VN%d Median SNR with dropped packets.fig', nVidnodes), 'Median SNR with dropped packets (lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, medMangledSnr );

    nPlots = nPlots + 1;
    plot_rundata( nPlots, sprintf('./../results/figures/VN%d Median SSIM Similarity with dropped packets.fig', nVidnodes), 'Median SSIM Similarity with dropped packets(lower better)', ...
        'SNR', labels, plotColors, nVariations, nSimulations, medMangledSSIM );
end