function [ nodegen ] = traffic_file_downloads(nNodes, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness)
%TRAFFIC_FILE_DOWNLOADS Create nodegen to simulate file downloading
    nodegen = nodegen_data_nodes();
    nodegen.name = 'file download';
    
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
    
    % 2nd level params to be used later
    if (isempty(fileBigness))
        fileBigness = 1.0;
    end
    
    if (isempty(fileWaityness))
        fileWaityness = 1.0;
    end
    
    if (isempty(nSizeTypes))
        nSizeTypes = 3;
    end
    
    if (isempty(nInterarrivalTypes))
        nInterarrivalTypes = 3;
    end
    
    % There is always a packet in the buffer
    nodegen.pArrive = 1.0;
    
    % We will always wait after sending a 'file'
    nodegen.pEnter = 1.0;
    
    % Generate some variation in our packet/interarrival sizes
    nodegen.nMaxPackets = ceil( fileBigness * 5 * (2 .^ (0:nSizeTypes-1)) );
    nodegen.nInterarrival = ceil( fileWaityness * 5 * (2 .^ (0:nInterarrivalTypes-1)) );
end
