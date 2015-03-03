% FHSS physical model in 802.11 standard
p = 0.25;
Wmin = 8;
Wmax = 32; %1024;
m = log2(Wmax / Wmin);

% -> W = (2 4)

[pi, dims, cost] = dcf_matrix(p, m, Wmin);
% [groundProbability] = dcf_ground_state(p, Wmin, m);

% n
TM = pi^50;

% cost = zeros(n, 1);


