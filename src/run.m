run_set_path

tic
sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = [100 2000];
datanode1 = nodegen_data_nodes();
videonode1 = nodegen_mpeg4_nodes();
videonode1.bps = [ 1000000 5000000 ];

sim1.cleanCache = true;
sim1.AddNodegen( datanode1 );
sim1.AddNodegen( videonode1 );
sim1.Run();
toc

tic
sim2 = dcf_simulation('cachetest');
sim2.nTimesteps = [100 2000];
datanode2 = nodegen_data_nodes();
videonode2 = nodegen_mpeg4_nodes();
videonode2.bps = [ 1000000 5000000 ];

sim2.AddNodegen( datanode2 );
sim2.AddNodegen( videonode2 );
sim2.Run();
toc