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
        % The DCFs we are simulating, expect 2 DCF objects
        % 1: Normal probability
        % 2: 100% Failure probability
        dcf@dcf_container;
        dcfFail@dcf_container;
        
        % The transition table for the DCF with normal p
        txP;
        
        % The transition table for the DCF with p=0
        txPFail;
        
        % The transition table with labels of types of transitions
        txTypes;
        
        % The vector of state types for each state
        stateTypes;
        
        % The possible indices of states we can roam to
        sampleIndices;
        
        % Total number of nodes we'll simultaneously simulate
        nNodes;
    end %properties (SetAccess = protected)
    
    methods
        % Constructor
        function obj = dcf_simulator_oo(dcfIn, dcfFailIn, nNodesIn)
            obj = obj@handle();
            obj.dcf = dcfIn;
            obj.dcfFail = dcfFailIn;
            obj.nNodes = nNodesIn;
        end
        
        % Initialize the object and ready it for calls to StepSimulate
        function Setup(this)
            this.stateTypes = this.dcf.StateTypes();
            
            [this.txP, this.txTypes]= this.dcf.TransitionTable();
            this.txPFail = this.dcfFail.TransitionTable();
            this.txTypes
            
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
                pCur = this.txP(this.CurrentState(i), :);
                this.CurrentState(i) = randsample(this.sampleIndices, 1, true, pCur);
            end
            
            % Handle multiple nodes trying to transmit at once
            transmitting = find(this.CurrentState == dcf_state_type.Transmit);
            nTransmitting = size(transmitting,2);
            if (nTransmitting > 1)
                for i=1:nTransmitting
                    assert(false);
                    % Force all of these into failure states by using the
                    % transition table for when there are 100% failures
                    % TODO: Verify this works correctly
                    pCur = this.txPFail(this.PrevState(i), :);
                    this.CurrentState(i) = randsample(this.sampleIndices, 1, true, pCur);
                end
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
                    if (this.txTypes(src,dst) == dcf_transition_type.TxSuccess)
                        successes = successes + this.TransitionCount(:, src, dst);
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
                    if (this.txTypes(src,dst) == dcf_transition_type.TxFailure)
                        failures = failures + this.TransitionCount(:, src, dst);
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
                    if (this.txTypes(src,dst) == dcf_transition_type.Backoff)
                        waits = waits + this.TransitionCount(:, src, dst);
                    end
                end
            end
        end
    end %methods
end
