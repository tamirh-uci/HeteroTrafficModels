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
    % If success, we have equal probability to go to each of the variable
    % packet countdown states
    % CASE 2
    pSuccess = (1 - p) / W(1,1);
    for k = beginBackoffCol:W(1,1)
        [ii, jj] = flattenXY(dims, [i,beginXmitCol], [beginXmitCol,k]);
        pi(ii,jj) = pSuccess;
    end
    
    % Set probability to go to start and to each other packet variable equal
    pVarPkt = pSuccess / nPktMax;
    [ii, jj] = flattenXY(dims, [i,beginXmitCol], [beginXmitCol,1]);
    pi(ii,jj) = pVarPkt;
    for k = beginPktCol(1,i):endPktCol(1,i)
        [ii, jj] = flattenXY(dims, [i,beginXmitCol], [i,k]);
        pi(ii,jj) = pVarPkt;
    end
    
    % Initialize the probabilities from backoff stages to the transmission
    % stage (all stages k > 1)
    % CASE 1
    for k = beginBackoffCol:wCols
        [ii, jj] = flattenXY(dims, [i,k], [i,k-1]);
        pi(ii,jj) = 1.0;
    end
    
    % Set probabilities for the packet chain to continue properly
    for k = beginPktCol(1,i):endPktCol(1,i)
        prev = k - 1;
        if (prev < beginPktCol(1,i))
            prev = beginXmitCol;
        end
        
        % success, go to previous variable packet state
        [ii, jj] = flattenXY(dims, [i,k], [i,prev]);
        pi(ii,jj) = 1 - p;
        
        % failure, go to a backoff state
        for j = beginXmitCol:wColsNext
            [ii, jj] = flattenXY(dims, [i,k], [nextStage,j]);
            pi(ii,jj) = pi(ii,jj) + pNext;
        end
    end
end

% Verify we haven't written anywhere we shouldn't have
% null out rows/columns corresponding to unused cells
doAssert = true;
doOverwrite = true;
overwriteValue = NaN;
epsilonThreshold = 0.0001;

if (doAssert)
    for i = 1:nRows
        nCols = endPktCol(1,i);
        
        % check for non-zero values in ununsed rows
        for deadRow = nCols+1:nColsMax
            ii = flatten(dims, [i,deadRow]);
            assert( ~any(pi(ii,:)) );
        end
        
        % check for non-zero values in ununsed cols
        for deadCol = nCols+1:nColsMax
            jj = flatten(dims, [i,deadCol]);
            assert( ~any(pi(:,jj)) );
        end
        
        % check each valid row sums to 1
        for liveRow = 1:nCols
            ii = flatten(dims, [i,liveRow]);
            s = sum(pi(ii,:));
            assert( abs(1-s) < epsilonThreshold );
        end
    end
end

% overwrite values in unused rows/cols (just for visualizing the table)
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
