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
        
        IFrameNew(20)
        IFrameContinue(21)
        BFrameNew(30)
        BFrameContinue(31)
        PFrameNew(40)
        PFrameContinue(41)
        
        % All values here and below are considered collapsible states
        Collapsible(64)
        CollapsibleTransmit(65)
        CollapsibleSuccess(66)
        CollapsibleFailure(67)
        CollapsiblePacketSize(68)
        CollapsiblePostbackoff(69)
        CollapsibleInterarrival(70) 
        CollapsibleInitialTransmit(71)
        CollapsibleBackoffExpired(72)
        CollapsibleDistribute(73)
    end
end
