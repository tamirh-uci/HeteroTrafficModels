function [ pi, dims ] = dcf_matrix_varpacket( p, m, Wmin )
% dcf_matrix Generate the transition probability matrix 

nrows = m + 1;

% Compute values for W
W = zeros(1,nrows);
for i = 1:nrows
    W(1,i) = (2^(i - 1)) * Wmin;
end

% Initialize the transition matrix with the flattened dimensions
nColsMax = W(1, nrows);
n = nrows * nColsMax;
dims = [nrows, nColsMax]; % store the dimensions of each state
pi = zeros(n, n);

% Initialize the probabilities from transmission stages to the backoff
% stages
for i = 1:nrows
   nCols = W(1, i);
    
   % Handle the last stage specially -- it loops on top of itself
   nextStage = nrows;
   if (i < nrows)
      nextStage = i + 1; 
   end
   
   % Failure case
   % CASE 3/4
   nColsNext = W(1, nextStage);
   pNext = p / nColsNext;
   
   for k = 1:nColsNext
       [ii, jj] = flattenXY(dims, [i,1], [nextStage,k]);
       pi(ii,jj) = pNext;
   end
   
   % Success case
   % CASE 2
   pSuccess = (1 - p) / W(1,1);
   for k = 1:W(1,1)
       [ii, jj] = flattenXY(dims, [i,1], [1,k]);
       pi(ii,jj) = pSuccess; 
   end
   
   % Initialize the probabilities from backoff stages to the transmission
   % stage (all stages k > 1)
   % CASE 1
   for k = nCols:-1:2
      [ii, jj] = flattenXY(dims, [i,k], [i,k-1]);
      pi(ii,jj) = 1.0;
   end
end

% Verify we haven't written anywhere we shouldn't have
% null out rows/columns corresponding to unused cells
for i = 1:nrows
    
end

end
