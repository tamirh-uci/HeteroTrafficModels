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

% Shared params
simName = 'mp4-interference';
simParams = dcf_simulation_params();
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
fileBigness = 1.0;
fileWaityness = 1.0;

vidParams = traffic_video_stream(1, wMin, wMax, vu.bpsSrcC, [], []);
dataParams = traffic_file_downloads(1, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness);

fprintf('Running simulation with one data node, one video node\n');
[results, ~] = run_single_sim( simName, timesteps, simParams, dataParams, vidParams, vu, doVideoMangle, qualityThresholdMicrosec, 1, 1 );

txHistory = results{1}.nodeTxHistory;
nNodes = size(txHistory, 2);

txHistory{1}(3:5) = 1;
fprintf('Dumping out history to file\n');

bytesPerPacket = simParams.physical_payload / 8;
deltaTime = phys80211.TransactionTime(simParams.physical_type, simParams.physical_payload, simParams.physical_speed);
time = 0;

csvFilename = './../results/trace.csv';
csvRow = 1;

for i=1:nNodes
    d = [0, txHistory{i}, 0];

    packetStarts = strfind(d, [0 1]);
    packetEnds = strfind(d, [1 0]);
    packetSizes = packetEnds - packetStarts;
    
    nPackets = size(packetStarts,2);
    for j=1:nPackets
        packetIndex = packetStarts(j);
        packetSize = bytesPerPacket * packetSizes(j);
        time = deltaTime * packetIndex;
        
        csvData(csvRow, 1) = int32(i);
        csvData(csvRow, 2) = int32(packetIndex);
        csvData(csvRow, 3) = time;
        csvData(csvRow, 4) = int32(packetSize);
        
        csvRow = csvRow + 1;
    end
end

% Col 1: 'Node #';
% Col 2: 'Packet Index';
% Col 3: 'Time (microseconds)';
% Col 4: 'Packet Size (bytes)';
csvwrite(csvFilename, csvData);
fid = fopen(csvFilename, 'r+');
if (fid > 0)
    frewind(fid);
    fprintf(fid, '%s,%s,%s,%s\n', ...
        'Node #', ...
        'Packet Index', ...
        'Time (microseconds)', ...
        'Packet Size (bytes)');
    
    fclose(fid);
end
