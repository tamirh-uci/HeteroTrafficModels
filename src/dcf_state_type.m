classdef dcf_state_type < int32
    %DCF State Type - Describing what happens in this state for the
    %simulator
    enumeration
        Null
        Transmit
        Backoff
        PacketSize
        Interarrival
        
        % All values here and below are considered collapsible states
        Collapsible
        CollapsibleTransmit
        CollapsibleSuccess
        CollapsibleFailure
        CollapsiblePacketSize
        CollapsibleInterarrival
    end
end
