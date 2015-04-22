run_set_path

tic
sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = [100 2000];
sim1.pSingleSuccess = [1.0];

datanode1 = nodegen_data_nodes();
datanode1.pArrive = [1.0];

sim1.cleanCache = true;
sim1.AddNodegen( datanode1 );
sim1.Run();
toc

tic
sim2 = dcf_simulation('cachetest');
sim2.nTimesteps = [100 2000];
sim2.pSingleSuccess = [1.0];

datanode2 = nodegen_data_nodes();
datanode2.pArrive = [1.0];

sim2.AddNodegen( datanode2 );
sim2.Run();
toc