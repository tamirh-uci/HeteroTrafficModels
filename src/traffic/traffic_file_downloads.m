function [ nodegen ] = traffic_file_downloads( nNodes, nTypes, wMin, wMax, fileBigness, fileWaityness)
%TRAFFIC_FILE_DOWNLOADS Create nodegen to simulate file downloading
    nodegen = nodegen_data_nodes();
    nodegen.name = 'file download';
    
    % user entered params
    if (isempty(fileBigness))
        fileBigness = 1.0;
    end
    
    if (isempty(fileWaityness))
        fileWaityness = 1.0;
    end
    
    if (isempty(nTypes))
        nTypes = 3;
    end
    
    if (~isempty(wMin))
        nodegen.wMin = wMin;
    end
    
    if (~isempty(wMax))
        nodegen.wMax = wMax;
    end
    
    if (~isempty(nNodes))
        nodegen.nGenerators = nNodes;
    end
    
    % There is always a packet in the buffer
    nodegen.pArrive = 1.0;
    
    % We will always wait after sending a 'file'
    nodegen.pEnter = 1.0;
    
    multiplier = 5 * (2 .^ (0:nTypes-1));
    nodegen.nMaxPackets = fileBigness * multiplier;
    nodegen.nInterarrival = fileWaityness * multiplier;
end
