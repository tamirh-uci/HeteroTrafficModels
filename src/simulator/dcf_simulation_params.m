classdef dcf_simulation_params < handle
    %DCF_SIMULATION_PARAMS Looping params for dcf_simulation
    properties
        pSingleSuccess = 1.0;
        pMultiSuccess = 0.0;
        physical_type = phys80211_type.B;
        physical_speed = 1.0;
        physical_payload = 8*1500;
    end
end
