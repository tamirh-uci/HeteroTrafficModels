% dcf_matrix Generate the transition probability matrix
function [ pi, dims ] = dcf_matrix_varpacket( p, m, Wmin, nPktMax )

% constants
nRows = m + 1;
nPktStates = nPktMax - 1;
beginXmitCol = 1;
beginBackoffCol = beginXmitCol + 1;

% Compute values for W
W = zeros(1,nRows);
for i = 1:nRows
    W(1,i) = (2^(i - 1)) * Wmin;
end

% Compute values for where the pkt columns begin (after backoff cols)
beginPktCol = zeros(1,nRows);
for i = 1:nRows
    beginPktCol(1,i) = W(1,i) + 1;
end
endPktCol = beginPktCol + nPktStates - 1;

% Initialize the transition matrix with the flattened dimensions
nColsMax = endPktCol(1, nRows);
dims = [nRows, nColsMax]; % store the dimensions of each state
totalStates = nRows * nColsMax;
pi = zeros(totalStates, totalStates);


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
    pNext = p / wColsNext;
    
    for k = beginXmitCol:wColsNext
        [ii, jj] = flattenXY(dims, [i,beginXmitCol], [nextStage,k]);
        pi(ii,jj) = pNext;
    end
    
    % Success case
    % CASE 2
    pSuccess = (1 - p) / W(1,1);
    for k = beginXmitCol:W(1,1)
        [ii, jj] = flattenXY(dims, [i,beginXmitCol], [beginXmitCol,k]);
        pi(ii,jj) = pSuccess;
    end
    
    % Initialize the probabilities from backoff stages to the transmission
    % stage (all stages k > 1)
    % CASE 1
    for k = beginBackoffCol:wCols
        [ii, jj] = flattenXY(dims, [i,k], [i,k-1]);
        pi(ii,jj) = 1.0;
    end
    
    % Variable packet transmission probabilities
    % From column 1, with equal probability we can go to each other
    % state of packet size with equal probability, they will then chain
    % until they reach the end
    
end

% Verify we haven't written anywhere we shouldn't have
% null out rows/columns corresponding to unused cells
doAssert = true;
doOverwrite = true;
overwriteValue = NaN;

% check for non-zero values in ununsed rows/cols
if (doAssert)
    for i = 1:nRows
        nCols = endPktCol(1,i);
        
        for deadRow = nCols+1:nColsMax
            ii = flatten(dims, [i,deadRow]);
            assert( ~any(pi(ii,:)) );
        end
        
        for deadCol = nCols+1:nColsMax
            jj = flatten(dims, [i,deadCol]);
            assert( ~any(pi(:,jj)) );
        end
    end
end

% overwrite values in unused rows/cols
if (doOverwrite)
    for i = 1:nRows
        nCols = endPktCol(1,i);
        
        for deadRow = nCols+1:nColsMax
            ii = flatten(dims, [i,deadRow]);
            pi(ii,:) = overwriteValue;
        end
        
        for deadCol = nCols+1:nColsMax
            jj = flatten(dims, [i,deadCol]);
            pi(:,jj) = overwriteValue;
        end
    end
end

end
