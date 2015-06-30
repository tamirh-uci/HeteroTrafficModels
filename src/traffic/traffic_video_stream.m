function [ nodegen ] = traffic_video_stream(nNodes, wMin, wMax, bps)
%TRAFFIC_VIDEO_STREAM Create nodegen to simulate mpeg4 video streaming
    nodegen = nodegen_mpeg4_nodes();
    nodegen.name = 'video stream';
    
    % user entered params
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    if (~isempty(wMin))
        nodegen.params.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.params.wMax = wMax;
    end
    
    if (isempty(bps))
        bps = -1;
    end
    
    % There is always a packet in the buffer
    nodegen.params.pArrive = 1.0;
    nodegen.params.pInterarrival = 0.5;
    nodegen.params.nInterarrival = 10;
    nodegen.params.pSleep = 0;
    nodegen.params.bps = bps;
    nodegen.params.nSleep = 1;
    nodegen.params.sleepProps1 = -200;
    nodegen.params.sleepProps2 = 0.1;
    nodegen.params.sleepProps3 = 500;
    nodegen.params.sleepProps4 = 100;
end
