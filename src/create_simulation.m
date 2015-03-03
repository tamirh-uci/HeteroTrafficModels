function [ simulator ] = create_simulation( numNormals, numMedias, pSuccess, pArrive, pEnter, Wmin, Wmax )

% Precompute variables for the DCF model
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% Create the matrix
dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;
dcf_matrix.nPkt = 1;
dcf_matrix.nInterarrival = 0;
dcf_matrix.pEnterInterarrival = pEnter;
dcf_matrix.pRawArrive = pArrive;

% Populate the nodes in the simulator
simulator = dcf_simulator_oo(pSuccess, 0.0);

for i = 1:numNormals
    node = dcf_matrix_factory(pArrive, pEnter, m, Wmin, 1, 0);
    nodeName = sprintf('node%d', i);
    simulator.add_dcf_matrix(nodeName, node);
end
for i = 1:numMedias
	media_matrix = markov_video_frames();
	media_matrix.gopAnchorFrameDistance = 3;
	media_matrix.gopFullFrameDistance = 12;
    simulator.add_multimedia_matrix(nodeName, dcf_matrix, media_matrix);
end

simulator.Setup();

end