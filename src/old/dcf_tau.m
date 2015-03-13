function [ tau ] = dcf_tau( p, W, m )
% Compute tau, the probability that a station transmits in a randomly
% chosen state.

num = 2 * (1 - (2 * p));
denom = (1 - (2 * p)) * (W + 1) + (p * W * (1 - (2 * p)^m));
tau = num / denom;

end

