run_set_path

wMin = 8;
wMax = 16;

datanode = traffic_file_downloads([], [], wMin, wMax, [], []); 

sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = [100];
sim1.AddNodegen( datanode );
sim1.Run();

%sim2 = dcf_simulation('cachetest');
%sim2.nTimesteps = [100 200];
%sim2.AddNodegen( datanode );
%sim2.AddNodegen( videonode );
%sim2.Run();