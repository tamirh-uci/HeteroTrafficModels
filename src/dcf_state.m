classdef dcf_state < handle
    %DCF State - A single state in the markov chain
    
    properties
        % Describes how this state is executed when in the simulator
        Type@dcf_state_type = dcf_state_type.Null;
        
        % Logical indexing in N dimensions as an array of indices
        % format: "[<dimension1>, <dimension2>, ... <dimensionN>]"
        % format: can be obtained by using mat2str
        Key@char = '[Null]';
        
        % The calculated index for the flattened version of the state table
        % TODO: Figure out why we can't restrict this to int32 w/o error?
        IF@int32 = int32(-1);
        
        % HashTable of nonzero transition probabilities to other states
        P@containers.Map
        
        % HashTable of types of transitions to other states
        TX@containers.Map
    end %properties
    
    methods(Static)
        % Convert array indices of dimensions into a character key
        function key = MakeKey(array)
            if (ischar(array))
                key = array;
            else
                key = mat2str(array);
            end
        end
    end %methods(Static)
    
    methods
        % Constructor for dcf_state
        % key: the dimensioned index for this state
        % type: the dcf_state_type for simulation
        function obj = dcf_state(key, type)
            obj = obj@handle();
            obj.Type = type;
            obj.P = containers.Map('KeyType', 'char', 'ValueType', 'double');
            obj.TX = containers.Map('KeyType', 'char', 'ValueType', 'int32');
            
            if (ischar(key))
                obj.Key = key;
            else
                % TODO: Figure out why we can't call MakeKey from here
                obj.Key = mat2str(key);
            end
        end
    end %methods
end
