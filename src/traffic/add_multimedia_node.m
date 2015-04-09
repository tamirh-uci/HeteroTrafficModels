function [ dcf_model, media_matrix ] = add_multimedia_node( simulator, m, Wmin, nodeNumber, bps, payloadSize )

dcf_model = dcf_markov_model();
dcf_model.m = m;
dcf_model.wMin = Wmin;

dcf_model.bFixedPacketchain = true;
dcf_model.nPkt = 1;
dcf_model.pEnterInterarrival = 1.0;
dcf_model.bFixedInterarrivalChain = true;
dcf_model.CalculateInterarrival(phys80211_type.B, bps, payloadSize);

media_matrix = markov_video_frames();
media_matrix.gopAnchorFrameDistance = 3;
media_matrix.gopFullFrameDistance = 12;
media_matrix.bps = bps; 
media_matrix.payloadSize = payloadSize;

nodeName = sprintf('media-node%d', nodeNumber);
simulator.add_multimedia_matrix(nodeName, dcf_model, media_matrix);

end

