run_set_path

% Shared params
simParams = dcf_simulation_params();
timesteps = [100];
simParams.pSingleSuccess = [0.15, 1.0];

% Video node stuff
nVideoNodes = 1;
bps = 800000;

% File node stuff
nFileNodes = 1;
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 1.0;
fileWaityness = 1.0;
wMin = 8;
wMax = 16;

videonode = traffic_video_stream(nVideoNodes, wMin, wMax, bps, [], []);
datanode = traffic_file_downloads(nFileNodes, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness); 

sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = timesteps;
sim1.params = simParams;

sim1.AddNodegen( videonode );
sim1.AddNodegen( datanode );

sim1.Run();

%sim2 = dcf_simulation('cachetest');
%sim2.nTimesteps = [100 200];
%sim2.AddNodegen( datanode );
%sim2.AddNodegen( videonode );
%sim2.Run();
