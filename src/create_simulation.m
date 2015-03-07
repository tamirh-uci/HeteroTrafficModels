function [ simulator ] = create_simulation( bVerbose, numNormals, numMedias, pSuccess, pArrive, pEnter, Wmin, Wmax, nMaxPackets, nInterarrival )

% Precompute variables for the DCF model
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% Populate the nodes in the simulator
dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;
dcf_matrix.nPkt = nMaxPackets;
dcf_matrix.nInterarrival = nInterarrival;
dcf_matrix.pEnterInterarrival = pEnter;
dcf_matrix.pRawArrive = pArrive;

simulator = dcf_simulator_oo(pSuccess, 0.0);

for i = 1:numNormals
    nodeName = sprintf('node%d', i);
    simulator.add_dcf_matrix(nodeName, dcf_matrix);
end

% modify dcf matrix for media settings
% TODO: Set these up
dcf_matrix.bFixedPacketchain = true;

for i = 1:numMedias
	media_matrix = markov_video_frames();
	media_matrix.gopAnchorFrameDistance = 3;
	media_matrix.gopFullFrameDistance = 12;
    nodeName = sprintf('media-node%d', i);
    simulator.add_multimedia_matrix(nodeName, dcf_matrix, media_matrix);
end

simulator.Setup(bVerbose);

end