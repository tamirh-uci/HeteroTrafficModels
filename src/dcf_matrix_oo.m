% dcf_matrix Generate the transition probability matrix using classes
function [ pi, dims ] = dcf_matrix_oo( p, m, Wmin )

% constants
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
for i = 1:nRows
    wCols = W(1,i);
    
    for k = beginXmitCol:beginBackoffCol-1
        dcf.NewState( dcf_state( [i, k], dcf_state_type.Transmit ) );
    end
    
    for k = beginBackoffCol:wCols
        dcf.NewState( dcf_state( [i, k], dcf_state_type.Backoff ) );
    end
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
    
    fprintf('\n\nSetting failure cases 3+4\n');
    % Failure case
    % CASE 3/4
    wColsNext = W(1, nextStage);
    pNext = p / wColsNext;
    
    for k = beginXmitCol:wColsNext
        dcf.SetP( [i,beginXmitCol], [nextStage,k], pNext );
    end
    
    fprintf('\n\nSetting success case 2\n');
    % Success case
    % If success, we have equal probability to go to each of the variable
    % packet countdown states
    % CASE 2
    pSuccess = (1 - p) / W(1,1);
    for k = beginXmitCol:W(1,1)
        dcf.SetP( [i,beginXmitCol], [beginXmitCol,k], pSuccess );
    end
    
    fprintf('\n\nSetting backoff case 1\n');
    % Initialize the probabilities from backoff stages to the transmission
    % stage (all stages k > 1)
    % CASE 1
    for k = beginBackoffCol:wCols
        dcf.SetP( [i,k], [i,k-1], 1.0 );
    end
end

pi = dcf.TransitionTable();
assert( dcf.Verify() );

end
