classdef dcf_transition_type < int32
    %DCF Transition Type - Describes what happens on a given transition of
    %src->dst states
    
    enumeration
        Null (0)
        TxSuccess (1)
        TxFailure (2)
        Backoff (4)
        PacketSize (8)
        Interarrival (16)
    end
end
