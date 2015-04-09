function [ dcf_matrix ] = add_file_download_node( simulator, m, Wmin, nodeNumber, pArrive, pEnter, nMaxPackets, nInterarrival )

% pArrive = 1.0;
% pEnter = 1.0;
% nMaxPackets = 10;
% nInterarrival = 10;

dcf_model = dcf_markov_model();
dcf_model.m = m;
dcf_model.wMin = Wmin;
dcf_model.nPkt = nMaxPackets;
dcf_model.nInterarrival = nInterarrival;
dcf_model.pEnterInterarrival = pEnter;
dcf_model.pRawArrive = pArrive;

nodeName = sprintf('node%d', nodeNumber);
simulator.add_dcf_model(nodeName, dcf_model);

end

