% FHSS physical model in 802.11 standard
p = 0.25;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
packetMax = 2;
% -> W = (2 4)

%%%% Transition matrix generation
%[pi, dims] = dcf_matrix(p, m, Wmin);
[pi, dims, dcf] = dcf_matrix_oo(p, m, Wmin);
[groundProbability] = dcf_ground_state(p, Wmin, m);

sim = dcf_simulator_oo(dcf);
sim.Setup();
sim.Step(1000);

dims
pi

%%%% Metrics computation
% Note: all time parameters must have the same units
E_p = 5; % TODO: depends on type of traffic
T_s = 10; % TODO: depends on E_p
T_c = 10; % TODO: depends on E_p
n = 2; % number of nodes -- make this a parameter
sigma = 5; % TODO

% 1. Throughput
[tau] = dcf_tau(p, Wmin, m)
P_tr = (1 - (1 - tau)^n)
P_s = (n * tau * (1 - tau)^(n - 1)) / (1 - (1 - tau)^n)
[S] = dcf_throughput( P_s, P_tr, E_p, sigma, T_s, T_c );

S

% 2. Packet loss probability
