function [ dcf_matrix ] = add_random_node( simulator, m, Wmin, nodeNumber, pArrive, pEnter, nMaxPackets, nInterarrival )

% pArrive = 1.0;
% pEnter = 0.0;
% nMaxPackets = 4;
% nInterarrival = 0;

dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;
dcf_matrix.nPkt = nMaxPackets;
dcf_matrix.nInterarrival = nInterarrival;
dcf_matrix.pEnterInterarrival = pEnter;
dcf_matrix.pRawArrive = pArrive;

nodeName = sprintf('node%d', nodeNumber);
simulator.add_dcf_matrix(nodeName, dcf_matrix);

end

