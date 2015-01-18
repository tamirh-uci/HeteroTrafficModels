function [ pi ] = dcf_matrix( p, m, Wmin )
% dcf_matrix Generate the transition probability matrix 
%   TODO

% Compute values for W
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% Initialize the transition matrix (2D state, so 4D matrix for all transitions)
% pi = (i,j,i',j')
n = (m + 1) * W(1, m + 1);
I = (m+1);
J = W(1,m+1);
pi = zeros(n, n);

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
   for k = 1:W(1, nextStage)
       ii = flatIndex(I,J,i,1);
       jj = flatIndex(I,J,nextStage,k);
       %pi(i,1,nextStage,k) = (p / W(1, nextStage));
       pi(ii, jj) = (p / W(1, nextStage));
   end
   
   % Success case
   % CASE 2
   for k = 1:W(1,1)
      ii = flatIndex(I,J,i,1);
      jj = flatIndex(I,J,1,k);
      %pi(i,1,1,k) = (1 - p) / W(1,1); 
      pi(ii,jj) = (1 - p) / W(1,1); 
   end
   
   % Initialize the probabilities from backoff stages to the transmission
   % stage (all stages k > 1)
   % CASE 1
   for k = W(1,i):-1:2 
      ii = flatIndex(I,J,i,k);
      jj = flatIndex(I,J,i,k-1);
      %pi(i,k,i,k-1) = 1.0;
      pi(ii,jj) = 1.0;
   end
end

end