classdef(Enumeration) dcf_transition_type < int32
    %DCF Transition Type - Describes what happens on a given transition of
    %src->dst states
    
    enumeration
        Null(0)
        TxSuccess(1)
        TxFailure(2)
        Backoff(3)
        PacketSize(4)
        Interarrival(5)
        Postbackoff(6)
        
        TxIFrame(20)
        TxBFrame(21)
        TxPFrame(22)
        
        % All values here and below are considered collapsible states
        Collapsible(64)
    end
end
