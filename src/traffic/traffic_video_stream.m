function [ nodegen ] = traffic_video_stream(nNodes, wMin, wMax, bps, gopAnchorFrameDistance, gopFullFrameDistance)
%TRAFFIC_VIDEO_STREAM Create nodegen to simulate mpeg4 video streaming
    nodegen = nodegen_mpeg4_nodes();
    nodegen.name = 'video stream';
    
    % user entered params
    if (~isempty(wMin))
        nodegen.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.wMax = wMax;
    end
    
    if (~isempty(bps))
        nodegen.bps = bps;
    end
    
    if (~isempty(gopAnchorFrameDistance))
        nodegen.gopAnchorFrameDistance = gopAnchorFrameDistance;
    end
    
    if (~isempty(gopFullFrameDistance))
        nodegen.gopFullFrameDistance = gopFullFrameDistance;
    end
    
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    % There is always a packet in the buffer
    nodegen.pArrive = 1.0;
end
