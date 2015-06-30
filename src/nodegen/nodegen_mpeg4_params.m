classdef nodegen_mpeg4_params < handle
    %NODEGEN_MPEG4_PARAMS Looping params for nodegen_mpeg4_nodes
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
        
        gopAnchorFrameDistance = 3;
        gopFullFrameDistance = 12;
    end
end
