run_set_path

tic
sim1 = dcf_simulation('cachetest');
sim1.nTimesteps = [100 2000];
sim1.pSingleSuccess = [1.0];

filenode = nodegen_file_download();
filenode.pArrive = [1.0];

sim1.cleanCache = true;
sim1.AddNodegen( filenode );
sim1.Run();
toc

tic
sim2 = dcf_simulation('cachetest');
sim2.nTimesteps = [100 2000];
sim2.pSingleSuccess = [1.0];

filenode2 = nodegen_file_download();
filenode2.pArrive = [1.0];


sim2.AddNodegen( filenode2 );
sim2.Run();
toc