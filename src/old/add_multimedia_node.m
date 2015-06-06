function [ dcf_model, video_model ] = add_multimedia_node( simulator, m, Wmin, nodeNumber, desired_video_bps)

dcf_model = dcf_markov_model();
dcf_model.m = m;
dcf_model.wMin = Wmin;

dcf_model.bFixedPacketchain = true;
dcf_model.nPkt = 1;
dcf_model.pEnterInterarrival = 1.0;
dcf_model.bFixedInterarrivalChain = true;
dcf_model.CalculateInterarrival(desired_video_bps, simulator.physical_type, simulator.physical_payload, simulator.physical_speed);

video_model = mpeg4_frame_model();
video_model.gopAnchorFrameDistance = 3;
video_model.gopFullFrameDistance = 12;
video_model.bps = desired_video_bps; 
video_model.physical_type = simulator.physical_type;
video_model.physical_payload = simulator.physical_payload;
video_model.physical_speed = simulator.physical_speed;

nodeName = sprintf('media-node%d', nodeNumber);
simulator.add_video_node(nodeName, dcf_model, video_model);

end
