function [ nodegen ] = traffic_file_downloads(nNodes, wMin, wMax, bps, pSleep, nSleep)
%TRAFFIC_FILE_DOWNLOADS Create nodegen to simulate file downloading
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
    
    % There is always a packet in the buffer
    nodegen.params.pArrive = 1.0;
    nodegen.params.pInterarrival = 0.1;
    nodegen.params.nInterarrival = 4;
    nodegen.params.pSleep = 0;
    nodegen.params.bFixedInterarrival = true;
    nodegen.params.bps = bps;
    nodegen.params.nSleep = 1;
    nodegen.params.sleepProps1 = -100;
    nodegen.params.sleepProps2 = 0.2;
    nodegen.params.sleepProps3 = 150;
    nodegen.params.sleepProps4 = 1;
end
