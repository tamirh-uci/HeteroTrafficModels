classdef nodegen_data_params < handle
    %NODEGEN_DATA_PARAMS Looping params for nodegen_data_nodes
    properties
        pSingleSuccess = 1.0;
        pMultiSuccess = 0.0;
        physical_type = phys80211_type.B;
        physical_speed = 1.0;
        physical_payload = 8*1500;
    end
end
