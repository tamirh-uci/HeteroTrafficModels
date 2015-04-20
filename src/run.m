run_set_path

sim = dcf_simulation();
sim.nTimesteps = [100 200];
sim.pSingleSuccess = [1.0];

filenode = nodegen_file_download();
filenode.pArrive = [1.0];


sim.AddNodegen( filenode );
sim.Run();
