classdef dcf_simulator_oo < handle
    %DCF Simulator using OO classes
    
    % For multinode simulation, we need multiple of these 'structs'
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
        
        % Total number of nodes we'll simultaneously simulate
        nNodes;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator_oo(dcfIn, nNodesIn)
            obj = obj@handle();
            obj.dcf = dcfIn;
            obj.nNodes = nNodesIn;
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this)
            this.transitions = this.dcf.TransitionTable();
            this.stateTypes = this.dcf.StateTypes();
            nStates = size(this.stateTypes,2);
            
            this.sampleIndices = 1:nStates;
            
            % Setup node data
            this.TransitionCount = zeros(this.nNodes, nStates, nStates);
            for i=1:this.nNodes
                this.SetupNode(i);
            end
        end
        
        % Initialize a single node
        function SetupNode(this, iNode)
            % Choose randomly based on weighted average of steady state
            startState = this.dcf.WeightedRandomState(0.0001, 1000);
            this.PrevState(iNode) = startState;
            this.CurrentState(iNode) = startState;
        end
        
        % Simulate multipler timer transitions for all nodes
        function Steps(this, nSteps)
            for i=1:nSteps
                this.Step();
            end
        end

        % Simulate single timer transition for all nodes
        function Step(this)
            for i=1:this.nNodes
                % Advance to the next state with given probabilities
                this.PrevState(i) = this.CurrentState(i);
                p = this.transitions(this.PrevState(i), :);
                this.CurrentState(i) = randsample(this.sampleIndices, 1, true, p);
            end
            
            % Handle interactions between nodes
            for i=1:this.nNodes
                % TODO: Handle collisions
            end
            
            % Log metrics for all nodes
            for i=1:this.nNodes
                src = this.PrevState(i);
                dst = this.CurrentState(i);
                this.TransitionCount(i, src, dst) = 1 + this.TransitionCount(i, src, dst);
            end
        end
        
        % Count up success transitions
        function successes = CountSuccesses(this)
            successes = zeros(1, this.nNodes);
            
            nStates = size(this.stateTypes,2);
            for src = 1:nStates
                for dst = 1:nStates
                    dstType = this.stateTypes(dst);
                    
                    if (dstType == dcf_state_type.Transmit)
                        successes = successes + this.TransitionCount(:,src,dst);
                    end
                end
            end
        end
        
        % Count up failure transitions
        function failures = CountFailures(this)
            failures = zeros(1, this.nNodes);
            
            nStates = size(this.stateTypes,2);
            for src = 1:nStates
                for dst = 1:nStates
                    srcType = this.stateTypes(src);
                    dstType = this.stateTypes(dst);
                    
                    if (srcType == dcf_state_type.Transmit && dstType == dcf_state_type.Backoff)
                        failures = failures + this.TransitionCount(:,src,dst);
                    end
                end
            end
        end
        
        % Count up wait (backoff) transitions
        function waits = CountWaits(this)
            waits = zeros(1, this.nNodes);
            
            nStates = size(this.stateTypes,2);
            for src = 1:nStates
                for dst = 1:nStates
                    srcType = this.stateTypes(src);
                    dstType = this.stateTypes(dst);
                    
                    if (srcType == dstType && srcType == dcf_state_type.Backoff)
                        waits = waits + this.TransitionCount(:,src,dst);
                    end
                end
            end
        end
    end %methods
end
