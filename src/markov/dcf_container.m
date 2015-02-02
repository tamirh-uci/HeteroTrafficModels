classdef dcf_container < handle
    %DCF Container - Holds set of states of markov chain
    
    properties (SetAccess = protected)
        % HashTable of all states
        states@containers.Map = containers.Map();    
    end
    
    methods
        
    end
    
end

