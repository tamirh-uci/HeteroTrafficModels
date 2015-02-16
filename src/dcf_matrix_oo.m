% OLD VERSION, SEE dcf_matrix_collapsible.m
classdef dcf_matrix_oo < handle

    properties (SetAccess = public)
        % probability any given packet transmission will succeed, given the
        % channel is free
        pRawFail;

        % number of stages
        m;

        % minimum number of backoff states
        wMin;

        % maximum size of packets
        % transmissions will be [1:nPkt] length
        nPkt;

        % number of states in the interarrival chain, we will jump to one
        % randomly with probability pEnterInterarrival
        nInterarrival;
        
        % probability to enter the interarrival chain, so probability there is
        % not a packet immediately ready to send
        pEnterInterarrival;
        
        % use single chain or multichain packetsize states (0 or 1)
        bUseSingleChainPacketsize;
    end %properties (SetAccess = public)

    properties (SetAccess = protected)
        % W matrix which holds number of DCF states in each row
        W;
        
        % 1 - pRawFail
        pRawSuccess;
        
        % number of rows in the basic DCF matrix
        nRows;
        
        % column where backoff states start
        beginBackoffCol;
        
        % maximum number of columns in any of the rows
        nColsMax;
    end %properties (SetAccess = protected)

    methods
        function obj = dcf_matrix_oo()
            obj = obj@handle();
            
            obj.pRawFail = 0.25;
            obj.m = 1;
            obj.wMin = 2;
            obj.nPkt = 0;
            obj.nInterarrival = 0;
            obj.pEnterInterarrival = 0;
            obj.bUseSingleChainPacketsize = true;
        end
        
        function CalculateConstants(this)
            this.pRawSuccess = 1 - this.pRawFail;
            this.nRows = this.m + 1;
            this.beginBackoffCol = 2;

            if (this.nInterarrival < 1 || this.pEnterInterarrival == 0)
                this.nInterarrival = 0;
                this.pEnterInterarrival = 0;
            end

            % Compute values for W
            this.W = zeros(1,this.nRows);
            for i = 1:this.nRows
                this.W(1,i) = (2^(i - 1)) * this.wMin;
            end
            
            this.nColsMax = this.W(1, this.nRows);
        end
        
        function [pi, dims, dcf] = CreateMatrix(this, pFail, nPacketSizeStates, nInterarrivalStates)
            this.pRawFail = pFail;
            this.nPkt = nPacketSizeStates;
            this.nInterarrival = nInterarrivalStates;
            this.CalculateConstants();
            
            % Initialize the transition matrix
            dcf = dcf_container();
            
            % store the dimensions of each state
            dims = [this.nRows, this.nColsMax]; 

            % Create all of the states
            % current format is [row, col, nPkt, nInterarrival]
            for i = 1:this.nRows
                wCols = this.W(1,i);

                % transmit attempt states
                for k = 1:this.beginBackoffCol-1
                    dcf.NewState( dcf_state( [i, k], dcf_state_type.Transmit ) );
                end

                % backoff states
                for k = this.beginBackoffCol:wCols
                    dcf.NewState( dcf_state( [i, k], dcf_state_type.Backoff ) );
                end

                % packet size 'calculation' states
                if (this.nPkt > 1)
                    for k = 2:this.nPkt
                        dcf.NewState( dcf_state( [i, 1, k], dcf_state_type.PacketSize ) );
                    end
                end

                % interarival time 'calculation' states
                for k = 1:this.nInterarrival
                    dcf.NewState( dcf_state( [i, 1, 1, k], dcf_state_type.Interarrival ) );
                end

                % unused states
            %     if (wCols < this.nColsMax)
            %         for k=wCols+1:this.nColsMax
            %             dcf.NewState( dcf_state( [i, k], dcf_state_type.Null ) );
            %         end
            %     end
            end

            % Initialize the probabilities from transmission stages to the backoff
            % stages
            for i = 1:this.nRows
                wCols = this.W(1,i);

                % Handle the last stage specially -- it loops on top of itself
                nextStage = this.nRows;
                if (i < this.nRows)
                    nextStage = i + 1;
                end

                % Failure case
                % CASE 3/4
                wColsNext = this.W(1, nextStage);
                pDistFail = pFail / wColsNext;

                for k = 1:wColsNext
                    dcf.SetP( [i,1], [nextStage,k], pDistFail, dcf_transition_type.TxFailure );
                end

                % Success case
                % If success, we have equal probability to go to each of the variable
                % packet countdown states
                % CASE 2
                pDistSuccess = (1-this.pEnterInterarrival) * this.pRawSuccess;
                pInterarrivalSuccess = 1 - pDistSuccess;
                pDistSuccess = pDistSuccess / this.W(1,1);
                
                % TODO: The way it's set up now it will always send 1
                % packet and then go to interarrival chain to see if there
                % are more. It should go straight to interarrival chain.
                for k = 1:this.W(1,1)
                    dcf.SetP( [i,1], [1,k], pDistSuccess, dcf_transition_type.TxSuccess );
                end
                
                if (this.nInterarrival > 0)
                    pInterarrivalSuccess = pInterarrivalSuccess / this.nInterarrival;
                    
                    % Setup the interarrival chain to see how many frames
                    % we sit idle
                    for k = 1:this.nInterarrival
                        % probability we enter the interarrival chain at any of
                        % the possible chain locations
                        dcf.SetP( [i,1], [i,1,1,k], pInterarrivalSuccess, dcf_transition_type.Interarrival );
                        
                        if (k > 1)
                            % move down along the chain
                            dcf.SetP( [i,1,1,k], [i,1,1,k-1], 1, dcf_transition_type.Interarrival );
                        else % we are exiting the chain
                            % possible success
                            for j = 1:this.W(1,1)
                                dcf.SetP( [i,1,1,k], [1,j], pDistSuccess, dcf_transition_type.TxSuccess );
                            end
                            
                            % possible failure
                            for j = 1:wColsNext
                                dcf.SetP( [i,1,1,k], [nextStage,k], pDistFail, dcf_transition_type.TxFailure );
                            end
                        end
                    end
                end

                if (this.nPkt > 1)
                    % TODO: Right now interarrival & packet length don't
                    % play well together, the packet length calculations
                    % will override the interarrival ones i think
                    
                    pPktNSuccess = this.pRawSuccess / this.nPkt;

                    % Recalculate success transitions for when a single packet succeeds
                    % We go into the regular success states in stage 0
                    % This is the same for our packet chain at 2
                    pPkt1Success = pPktNSuccess / this.W(1,1);
                    pPkt2Success = this.pRawSuccess / this.W(1,1);
                    for k = 1:this.W(1,1)
                        dcf.SetP( [i, 1],    [1,k], pPkt1Success, dcf_transition_type.TxSuccess );
                        dcf.SetP( [i, 1, 2], [1,k], pPkt2Success, dcf_transition_type.TxSuccess );
                    end

                    % Here were are 'calculating' how many packets we have by equally
                    % distributing over the rest of the packet chain stages
                    for k = 2:this.nPkt
                        dcf.SetP( [i, 1], [i, 1, k], pPktNSuccess, dcf_state_type.Backoff );
                    end

                    % We are calculate the probability of success coming OUT of each
                    % of the packet chain states (which just goes along the chain)
                    % to the next packet chain state
                    for k = 3:this.nPkt
                        dcf.SetP( [i, 1, k], [i, 1, k-1], pPktNSuccess, dcf_state_type.Backoff );
                    end

                    % Now we calculate the probability of failure at each of the packet
                    % chain states (dst same as the normal transmit attempt states)
                    for srcK = 2:this.nPkt
                        for destK = 1:wColsNext
                            dcf.SetP( [i, 1, srcK], [nextStage, destK], pDistFail, dcf_transition_type.TxFailure );
                        end
                    end
                end

                % Initialize the probabilities from backoff stages to the transmission
                % stage (all stages k > 1)
                % CASE 1
                for k = this.beginBackoffCol:wCols
                    dcf.SetP( [i,k], [i,k-1], 1.0, dcf_transition_type.Backoff );
                end
            end

            dcf.Collapse();
            [pi, ~] = dcf.TransitionTable();
            dcf.PrintMapping();
            assert( dcf.Verify() );

        end %function CreateMatrix

    end %methods
end %classdef
