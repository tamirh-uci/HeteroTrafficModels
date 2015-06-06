function [ dcf_model ] = add_web_traffic_node( simulator, m, Wmin, nodeNumber, pArrive, pEnter, nMaxPackets, nInterarrival )

% pArrive = 0.5;
% pEnter = 0.5;
% nMaxPackets = 5;
% nInterarrival = 5;

dcf_model = dcf_markov_model();
dcf_model.m = m;
dcf_model.wMin = Wmin;
dcf_model.nPkt = nMaxPackets;
dcf_model.nInterarrival = nInterarrival;
dcf_model.pEnterInterarrival = pEnter;
dcf_model.pRawArrive = pArrive;

nodeName = sprintf('node%d', nodeNumber);
simulator.add_plain_node(nodeName, dcf_model);

end

