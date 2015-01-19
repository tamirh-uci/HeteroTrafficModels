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
dims = [m + 1, W(1, m + 1)]; % store the dimensions of each state
pi = zeros(totalSize, totalSize);

% TODO: fill in matrix using the states of each node

end

