function [ pi ] = dcf_matrix( p, m, Wmin )
% dcf_matrix Generate the transition probability matrix 
%   TODO

% Compute values for W
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^i) * Wmin;
end

% Initialize the transition matrix (2D state, so 4D matrix)
pi = zeros(m+1, W(1,m+1), m+1, W(1,m+1));

% Initialize the probabilities from transmission stages to the backoff
% stages
for i = 1:(m+1)
   % Handle the last stage specially -- it loops on top of itself
   nextStage = m+1;
   if (i < m+1)
      nextStage = i + 1; 
   end
   
   % Failure cases
   % CASE 3/4
   for j = 1:W(1, nextStage)
       pi(i,1,nextStage,j) = (p / W(1, nextStage));
   end
   
   % Success case
   % CASE 2
   for k = 1:W(1,1)
      pi(i,1,1,k) = (1 - p) / W(1,1); 
   end
end

% Initialize the probabilities from backoff stages to the transmission
% stage
% CASE 1
for i = 1:(m+1)
   for j = W(1,i):-1:2 % Count down from the end
      pi(i,j,i,j-1) = 1.0;
   end
end

end