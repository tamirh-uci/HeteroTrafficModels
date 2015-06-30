classdef nodegen_data_params < handle
    %NODEGEN_DATA_PARAMS Looping params for nodegen_data_nodes
    properties
        wMin = 32;
        wMax = 64;
        
        pArrive = 1.0;
        pInterarrival = 1.0;
        pSleep = 0.1;
        
        nInterarrival = 2;
        nMaxPackets = 2;
        nSleep = -1;
        
        bps = 1000000 * 4;
    end
end
