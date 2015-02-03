classdef dcf_simulator_oo < handle
    %DCF Simulator using OO classes
    
    properties (SetAccess = public)
        CurrentState;
        PrevState;
        
        % Matrix which counts occurance of each state transition
        TransitionCount;
    end %properties (SetAccess = public)
    
    properties (SetAccess = protected)
        % The DCF we are simulating
        dcf@dcf_container;
        
        % The transition table for the DCF
        transitions;
        
        % The vector of state types for each state
        stateTypes;
        
        % The possible indices of states we can roam to
        sampleIndices;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator_oo(dcfIn)
            obj = obj@handle();
            obj.dcf = dcfIn;
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this)
            this.transitions = this.dcf.TransitionTable();
            this.stateTypes = this.dcf.StateTypes();
            nStates = size(this.stateTypes,2);
            
            this.sampleIndices = 1:nStates;
            this.TransitionCount = zeros(nStates,nStates);
            
            % Choose randomly based on weighted average of steady state
            this.PrevState = this.dcf.WeightedRandomState(0.0001, 1000);
        end

        % Simulate nIter number of state transitions
        function Step(this, nIter)
            for i=1:nIter
                % Advance to the next state with given probabilities
                p = this.transitions(this.CurrentState, :);
                this.CurrentState = randsample(this.sampleIndices, 1, true, p);
                
                % Log metrics for this state
                this.TransitionCount(this.PrevState, this.CurrentState) = 1 + this.TransitionCount(this.PrevState, this.CurrentState);
            end
        end
        
        % Count up success states
        function successes = CountSuccesses(this)
            successes = 0;
            
            nStates = size(this.stateTypes,2);
            for src = 1:nStates
                for dst = 1:nStates
                    
                end
            end
        end
        
        % Count up failure states
        function failures = CountFailures(this)
            failures = 0;
            
            nStates = size(this.stateTypes,2);
            for src = 1:nStates
                for dst = 1:nStates
                    
                end
            end
        end
    end %methods
end
