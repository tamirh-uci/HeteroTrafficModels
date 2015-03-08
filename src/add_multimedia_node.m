function [ dcf_matrix, media_matrix ] = add_multimedia_node( simulator, m, Wmin, nodeNumber, bps, payload )

dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;

dcf_matrix.bFixedPacketchain = true;
dcf_matrix.nPkt = 1;

% bps = 4 * 1000000; % 4MBits/second
% payloadSize = 1500*8;

dcf_matrix.pEnterInterarrival = 1.0;
dcf_matrix.bFixedInterarrivalChain = true;
dcf_matrix.CalculateInterarrival(phys80211_type.B, bps, payloadSize);

media_matrix = markov_video_frames();
media_matrix.gopAnchorFrameDistance = 3;
media_matrix.gopFullFrameDistance = 12;
media_matrix.bps = bps; 
media_matrix.payloadSize = payloadSize;

nodeName = sprintf('media-node%d', nodeNumber);
simulator.add_multimedia_matrix(nodeName, dcf_matrix, media_matrix);

end

