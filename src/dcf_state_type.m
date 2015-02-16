classdef dcf_state_type < int32
    %DCF State Type - Describing what happens in this state for the
    %simulator
    enumeration
        Null(0)
        Transmit(1)
        Backoff(2)
        PacketSize(3)
        Interarrival(4)
        Postbackoff(5)
        
        % All values here and below are considered collapsible states
        Collapsible(64)
        CollapsibleTransmit(65)
        CollapsibleSuccess(66)
        CollapsibleFailure(67)
        CollapsiblePacketSize(68)
        CollapsiblePostbackoff(69)
        CollapsibleInterarrival(70) 
    end
end
