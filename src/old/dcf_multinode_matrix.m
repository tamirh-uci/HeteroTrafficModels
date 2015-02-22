function [ pi, dims ] = dcf_multinode_matrix( numNodes, m, Wmin )
%UNTITLED14 Summary of this function goes here
%   Detailed explanation goes here

% Compute values for W
W = zeros(1,m + 1);
for i = 1:(m + 1)
    W(1,i) = (2^(i - 1)) * Wmin;
end

% Initialize the transition matrix with the flattened dimensions
totalSize = numNodes * (m + 1) * W(1, m + 1);
dims = [numNodes, m + 1, W(1, m + 1)]; % store the dimensions of each state
pi = zeros(totalSize, totalSize);

% TODO: fill in matrix using the states of each node
for n = 1:numNodes
   for i = 1:(m+1)
       % Handle the last stage specially -- it loops on top of itself
       nextStage = m + 1;
       if (i < m + 1)
           nextStage = i + 1; 
       end
       
       % P(collision) = P(at least one node is in a stage with timer 0)
       p = 0.5;
       
       for k = 1:W(1, nextStage)
           ii = flatten(dims, [n,i,1]);
           jj = flatten(dims, [n,nextStage, k]);
           pi(ii,jj) = (p / W(1, nextStage));
       end
   end
end

end

