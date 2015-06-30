function [ nodegen ] = traffic_web_browsing(nNodes, wMin, wMax, bps, nSleep)
%TRAFFIC_WEB_BROWSING Create nodegen to simulate browsing webpages
    nodegen = nodegen_data_nodes();
    nodegen.name = 'file download';
    
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
    
    if (isempty(nSleep))
        nSleep = -1;
    end
    
    % There is always a packet in the buffer
    nodegen.params.pArrive = 1.0;
    nodegen.params.pInterarrival = 0.75;
    
    nodegen.params.nInterarrival = 20;
    nodegen.params.pSleep = 0.5;
    nodegen.params.bps = bps;
    nodegen.params.nSleep = nSleep;
end
