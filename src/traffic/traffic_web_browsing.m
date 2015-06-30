function [ nodegen ] = traffic_web_browsing(nNodes, wMin, wMax, bps)
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
    
    % TODO: Add back in bps calc
    if (isempty(bps))
        bps = -1;
    end
    
    % There is always a packet in the buffer
    nodegen.params.pArrive = 1.0; % TODO: pArrive is broken
    nodegen.params.pInterarrival = 0.05;
    nodegen.params.nInterarrival = 15;
    nodegen.params.pSleep = 0;
    nodegen.params.bFixedInterarrival = false;
    nodegen.params.bps = bps;
    nodegen.params.nSleep = 1;
    nodegen.params.sleepProps1 = -50;
    nodegen.params.sleepProps2 = 0.01;
    nodegen.params.sleepProps3 = 25;
    nodegen.params.sleepProps4 = 400;
end
