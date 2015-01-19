function [ pi, dims ] = dcf_matrix( p, m, Wmin )
% dcf_matrix Generate the transition probability matrix 

% Compute values for W
W = zeros(1,m + 1);
for i = 1:(m + 1)
    W(1,i) = (2^(i - 1)) * Wmin;
end

% Initialize the transition matrix with the flattened dimensions
n = (m + 1) * W(1, m + 1);
dims = [m + 1, W(1, m + 1)]; % store the dimensions of each state
pi = zeros(n, n);

% Initialize the probabilities from transmission stages to the backoff
% stages
for i = 1:(m + 1)
   % Handle the last stage specially -- it loops on top of itself
   nextStage = m + 1;
   if (i < m + 1)
      nextStage = i + 1; 
   end
   
   % Failure case
   % CASE 3/4
   for k = 1:W(1, nextStage)
       ii = flatten(dims, [i,1]);
       jj = flatten(dims, [nextStage, k]);
       pi(ii,jj) = (p / W(1, nextStage));
%        pi(i,1,nextStage,k) = (p / W(1, nextStage));
   end
   
   % Success case
   % CASE 2
   for k = 1:W(1,1)
       ii = flatten(dims, [i,1]);
       jj = flatten(dims, [1,k]);
       pi(ii,jj) = (1 - p) / W(1,1); 
%       pi(i,1,1,k) = (1 - p) / W(1,1); 
   end
   
   % Initialize the probabilities from backoff stages to the transmission
   % stage (all stages k > 1)
   % CASE 1
   for k = W(1,i):-1:2
      ii = flatten(dims, [i,k]);
      jj = flatten(dims, [i,k-1]);
      pi(ii,jj) = 1.0;
%       pi(i,k,i,k-1) = 1.0;
   end
end

end
