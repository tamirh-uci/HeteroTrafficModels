function [ nodegen ] = traffic_custom(nNodes, wMin, wMax, pArrive, pEnter, nMaxPackets, nInterarrival)
%TRAFFIC_CUSTOM Create nodegen with all custom params
    nodegen = nodegen_data_nodes();
    nodegen.name = 'custom';
    
    % user entered params
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    if (~isempty(wMin))
        nodegen.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.wMax = wMax;
    end
    
    if (~isempty(pArrive))
        nodegen.pArrive = pArrive;
    end
    
    if (~isempty(pEnter))
        nodegen.pEnter = pEnter;
    end
    
    if (~isempty(nMaxPackets))
        nodegen.nMaxPackets = nMaxPackets;
    end
    
    if (~isempty(nInterarrival))
        nodegen.nInterarrival = nInterarrival;
    end
end
