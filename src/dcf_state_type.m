classdef dcf_state_type < int32
    %DCF State Type - Describing what happens in this state for the
    %simulator
    enumeration
        Null (0)
        Transmit (1)
        Backoff (2)
        PacketLength (4)
    end
end
