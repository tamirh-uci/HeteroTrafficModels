classdef dcf_state < handle
    %DCF State - A single state in the markov chain
    
    properties
        % Describes how this state is executed when in the simulator
        Type@dcf_state_type = dcf_state_type.Null;
        
        % The logical indexing in N dimensions as an array of indices in
        % those dimensions
        ID = [ NaN, NaN ];
        
        % The calculated index for the flattened version of the state table
        IF@int32 = -1;
        
        % HashTable of nonzero transition probabilities to other states
        P@containers.Map = containers.Map();
    end
    
    methods
        % Assign flattened index and return the index for the next state
        function next = Flatten(this, current)
            this.IF = current;
            next = current + 1;
        end
    end
end
