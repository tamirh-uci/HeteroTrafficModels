classdef(Enumeration) dcf_transition_type < int32
    %DCF Transition Type - Describes what happens on a given transition of
    %src->dst states
    
    enumeration
        Null
        TxSuccess
        TxFailure
        Backoff
        PacketSize
        Interarrival
    end
end
