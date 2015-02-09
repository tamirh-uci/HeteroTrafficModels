% dcf_matrix Generate the transition probability matrix using classes
function [ pi, dims, dcf ] = dcf_matrix_oo( pFail, m, Wmin, nPkt, nInterarrival )

% constants
pSuccess = 1 - pFail;
nRows = m + 1;
beginXmitCol = 1;
beginBackoffCol = beginXmitCol + 1;

% Compute values for W
W = zeros(1,nRows);
for i = 1:nRows
    W(1,i) = (2^(i - 1)) * Wmin;
end
nColsMax = W(1, nRows);

% Initialize the transition matrix
dcf = dcf_container();
dims = [nRows, nColsMax]; % store the dimensions of each state

% Create all of the states
% current format is [row, col, nPkt, nInterarrival]
for i = 1:nRows
    wCols = W(1,i);
    
    % transmit attempt states
    for k = beginXmitCol:beginBackoffCol-1
        dcf.NewState( dcf_state( [i, k], dcf_state_type.Transmit ) );
    end
    
    % backoff states
    for k = beginBackoffCol:wCols
        dcf.NewState( dcf_state( [i, k], dcf_state_type.Backoff ) );
    end
    
    % packet size 'calculation' states
    if (nPkt > 1)
        for k = 2:nPkt
            dcf.NewState( dcf_state( [i, 1, k], dcf_state_type.PacketSize ) );
        end
    end
    
    % interarival time 'calculation' states
    for k = 1:nInterarrival
        dcf.NewState( dcf_state( [i, 1, 1, k], dcf_state_type.Interarrival ) );
    end
    
    % unused states
%     if (wCols < nColsMax)
%         for k=wCols+1:nColsMax
%             dcf.NewState( dcf_state( [i, k], dcf_state_type.Null ) );
%         end
%     end
end

% Initialize the probabilities from transmission stages to the backoff
% stages
for i = 1:nRows
    wCols = W(1,i);
    
    % Handle the last stage specially -- it loops on top of itself
    nextStage = nRows;
    if (i < nRows)
        nextStage = i + 1;
    end
    
    % Failure case
    % CASE 3/4
    wColsNext = W(1, nextStage);
    pDistFail = pFail / wColsNext;
    
    for k = beginXmitCol:wColsNext
        dcf.SetP( [i,beginXmitCol], [nextStage,k], pDistFail, dcf_transition_type.TxFailure );
    end
        
    % Success case
    % If success, we have equal probability to go to each of the variable
    % packet countdown states
    % CASE 2
    pDistSuccess = pSuccess / W(1,1);
    for k = beginXmitCol:W(1,1)
        dcf.SetP( [i,beginXmitCol], [beginXmitCol,k], pDistSuccess, dcf_transition_type.TxSuccess );
    end

    
    if (nPkt > 1)
        pPktNSuccess = pSuccess / nPkt;
        
        % Recalculate success transitions for when a single packet succeeds
        % We go into the regular success states in stage 0
        % This is the same for our packet chain at 2
        pPkt1Success = pPktNSuccess / W(1,1);
        pPkt2Success = pSuccess / W(1,1);
        for k = 1:W(1,1)
            dcf.SetP( [i, 1],    [1,k], pPkt1Success, dcf_transition_type.TxSuccess );
            dcf.SetP( [i, 1, 2], [1,k], pPkt2Success, dcf_transition_type.TxSuccess );
        end
        
        % Here were are 'calculating' how many packets we have by equally
        % distributing over the rest of the packet chain stages
        for k = 2:nPkt
            dcf.SetP( [i, beginXmitCol], [i, 1, k], pPktNSuccess, dcf_state_type.Backoff );
        end
        
        % We are calculate the probability of success coming OUT of each
        % of the packet chain states (which just goes along the chain)
        % to the next packet chain state
        for k = 3:nPkt
            dcf.SetP( [i, 1, k], [i, 1, k-1], pPktNSuccess, dcf_state_type.Backoff );
        end
        
        % Now we calculate the probability of failure at each of the packet
        % chain states (dst same as the normal transmit attempt states)
        for srcK = 2:nPkt
            for destK = beginXmitCol:wColsNext
                dcf.SetP( [i, 1, srcK], [nextStage, destK], pDistFail, dcf_transition_type.TxFailure );
            end
        end
    end
 
    % Initialize the probabilities from backoff stages to the transmission
    % stage (all stages k > 1)
    % CASE 1
    for k = beginBackoffCol:wCols
        dcf.SetP( [i,k], [i,k-1], 1.0, dcf_transition_type.Backoff );
    end
end

[pi, ~] = dcf.TransitionTable();
assert( dcf.Verify() );

end
