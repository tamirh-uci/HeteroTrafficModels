run_set_path

datanode = nodegen_data_nodes();
videonode = nodegen_mpeg4_nodes();
videonode.bps = [ 1000000 5000000 ];

sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = [100 200];
sim1.cleanCache = false;
sim1.AddNodegen( datanode );
sim1.AddNodegen( videonode );
sim1.Run();

%sim2 = dcf_simulation('cachetest');
%sim2.nTimesteps = [100 200];
%sim2.AddNodegen( datanode );
%sim2.AddNodegen( videonode );
%sim2.Run();