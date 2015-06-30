run_set_path

rng('shuffle');

nVidNodes = 1;
nDataNodes = 1;
nWebNodes = 1;

videoBpsMultiplier = 0.5;
dataBpsMultiplier = 0.5;
webBpsMultiplier = 0.5;

% Load in a real video file to test against
vu = video_util();
vu.nFrames = 250;
vu.prep();

slotsPerVPacket = 10;
qualityThresholdMicrosec = 50000; % 50 miliseconds

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
simParams.pSingleSuccess = 1.0;
simParams.pMultiSuccess = 1.0; % For this trace, we're not simulating failures so everything succeeds
simParams.physical_type = phys80211_type.B;

wMin = 8;
wMax = 16;

% Video node stuff
% Grab values from our actual loaded file
timesteps = slotsPerVPacket * vu.nPacketsSrcC; % how many packets we'll need for our video (assume pretty good conditions)

vidBps = vu.bpsSrcC * videoBpsMultiplier;
dataBps = vu.bpsSrcC * dataBpsMultiplier;
webBps = vu.bpsSrcC * webBpsMultiplier;

vidParams = traffic_video_stream(1, wMin, wMax, vu.bpsSrcC);
dataParams = traffic_file_downloads(1, wMin, wMax, dataBps);
webParams = traffic_web_browsing(1, wMin, wMax, webBps);

nSims = nVidNodes + nDataNodes + nWebNodes;
nSim = 1;
simType = zeros(1, nSims);
simResults = cell(1, nSims);

for i=1:nVidNodes
    fprintf('\n==============\nSimulating video node %d of %d\n', i, nVidNodes);
    sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, qualityThresholdMicrosec, 1, 0 );
    sim.cleanCache = true;
    sim.Run(false);
    
    simType(nSim) = 20;
    simResults{nSim} = sim.simResults;
    nSim = nSim + 1;
end

for i=1:nDataNodes
    fprintf('\n==============\nSimulating data node %d of %d\n', i, nDataNodes);
    sim = setup_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, qualityThresholdMicrosec, 0, 1 );
    sim.cleanCache = true;
    sim.Run(false);
    
    simType(nSim) = 30;
    simResults{nSim} = sim.simResults;
    nSim = nSim + 1;
end

for i=1:nWebNodes
    fprintf('\n==============\nSimulating web node %d of %d\n', i, nWebNodes);
    sim = setup_single_sim( simName, timesteps, simParams, webParams, vidParams, vu, qualityThresholdMicrosec, 0, 1 );
    sim.cleanCache = true;
    sim.Run(false);
    
    simType(nSim) = 10;
    simResults{nSim} = sim.simResults;
    nSim = nSim + 1;
end

fprintf('Dumping out history to file\n');
bytesPerPacket = simParams.physical_payload / 8;
deltaTime = phys80211.TransactionTime(simParams.physical_type, simParams.physical_payload, simParams.physical_speed);
time = 0;


% Col 1: 'Simulation #'
% Col 2: 'Node Type (10=web, 20=generic video, 21=iframe, 22=pframe, 23=bframe, 30=data)'
% Col 2: 'Packet Index'
% Col 3: 'Time (microseconds)'
% Col 4: 'Packet Size (bytes)'
csvFilename = './../results/trace.csv';
clear csvData;

csvRow = 1;
for i=1:nSims
    % Assume we're just doing simulations with a single node by iteslf
    results = simResults{i};
    packetHistories = results{1}.nodePacketHistory;    
    packetHistory = packetHistories{1};
    sentPackets = find(packetHistory ~= 0);
    
    if (simType(i)==10)
        typename = 'web';
    elseif (simType(i)==20)
        typename = 'video';
    else
        typename = 'file';
    end
    
    if (simType(i)~=20) % type (web=10, video=20's, file=30)
        types = 10 * ones(1, size(sentPackets,2));
    else
        types = results{1}.nodeSecHistory{1}.stateTypeHistory( sentPackets );

        types( types==21 ) = 20;
        types( types==31 ) = 30;
        types( types==41 ) = 40;
    end
    
    clear simpleCsvData;
    dataRow = 1;
    for j=sentPackets
        time = deltaTime * j;
        packetSize = bytesPerPacket * packetHistory(j);
        
        csvData(csvRow, 1) = int32(i); % simulation #
        csvData(csvRow, 2) = int32(types(dataRow)); % IFrame(20,21) BFrame(30,31) PFrame(40,41)
        csvData(csvRow, 3) = int32(j); % packet index
        csvData(csvRow, 4) = time; % time (microseconds)
        csvData(csvRow, 5) = int32(packetSize); % packetsize (bytes)
        
        simpleCsvData(dataRow, 1) = time/1000000; % time (seconds)
        simpleCsvData(dataRow, 2) = int32(packetSize); % packetsize (bytes)
        
        csvRow = csvRow + 1;
        dataRow = dataRow + 1;
    end
    
    csvwrite(sprintf('./../results/trace_%s.csv', typename), simpleCsvData);
end

csvwrite(csvFilename, csvData);

run_wireshark_test