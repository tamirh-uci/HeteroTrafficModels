classdef nodegen_mpeg4_params < handle
    %NODEGEN_MPEG4_PARAMS Looping params for nodegen_mpeg4_nodes
    properties
        pArrive = 1.0;
        wMin = 32;
        wMax = 64;
        bps = 1000000 * 4;
        gopAnchorFrameDistance = 3;
        gopFullFrameDistance = 12;
        packetSize = 1;
    end
end
