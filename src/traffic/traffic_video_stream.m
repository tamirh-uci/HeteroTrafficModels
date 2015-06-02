function [ nodegen ] = traffic_video_stream(nNodes, wMin, wMax, bps, gopAnchorFrameDistance, gopFullFrameDistance)
%TRAFFIC_VIDEO_STREAM Create nodegen to simulate mpeg4 video streaming
    nodegen = nodegen_mpeg4_nodes();
    nodegen.name = 'video stream';
    
    % user entered params
    if (~isempty(wMin))
        nodegen.params.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.params.wMax = wMax;
    end
    
    if (~isempty(bps))
        nodegen.params.bps = bps;
    end
    
    if (~isempty(gopAnchorFrameDistance))
        nodegen.params.gopAnchorFrameDistance = gopAnchorFrameDistance;
    end
    
    if (~isempty(gopFullFrameDistance))
        nodegen.params.gopFullFrameDistance = gopFullFrameDistance;
    end
    
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    % There is always a packet in the buffer
    nodegen.params.pArrive = 1.0;
end
