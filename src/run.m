run_set_path

timesteps = [100 200];
pSuccess = [0.85 1.0];

nFileNodes = 1;
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 1.0;
fileWaityness = 1.0;
wMin = 8;
wMax = 16;

datanode = traffic_file_downloads(nFileNodes, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness); 

sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = timesteps;
sim1.params.pSingleSuccess = pSuccess;
sim1.AddNodegen( datanode );
sim1.Run();

%sim2 = dcf_simulation('cachetest');
%sim2.nTimesteps = [100 200];
%sim2.AddNodegen( datanode );
%sim2.AddNodegen( videonode );
%sim2.Run();
