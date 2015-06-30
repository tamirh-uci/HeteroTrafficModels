run_set_path;
close all;

% Shared params
simName = 'test';
simParams = dcf_simulation_params();
simParams.physical_type = phys80211_type.B;
simParams.pSingleSuccess = 1.0;
wMin = 2;
wMax = 4;

qualityThresholdMicrosec = 75000;
timesteps = 100;
webParams = traffic_web_browsing(1, wMin, wMax, 100000);

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

sim = setup_single_sim( simName, timesteps, simParams, webParams, [], vuCells, qualityThresholdMicrosec, 0, 1 );
sim.Run(false);
