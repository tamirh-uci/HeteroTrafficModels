% FHSS physical model in 802.11 standard
p = 0.25;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
packetMax = 2;
% -> W = (2 4)

%%%% Transition matrix generation
dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;
dcf_matrix.pEnterInterarrival = 0.5;
dcf_matrix.nPkt = 0;
dcf_matrix.bUseSingleChainPacketsize = true;
dcf_matrix.nInterarrival = 0;
dcf_matrix.pRawArrive = 1.0

[piFail, dimsFail, dcfFail] = dcf_matrix.CreateMatrix(1.0);
[pi, dims, dcf] = dcf_matrix.CreateMatrix(p);
dcf.PrintMapping();

sim = dcf_simulator_oo(dcf, dcfFail, 1);
sim.Setup();
sim.Steps(10000);

successes = sim.CountSuccesses();
failures = sim.CountFailures();
waits = sim.CountWaits();
successPercent = successes/(successes+failures)
transmitPercent = successes/(successes+failures+waits)

pi

[groundProbability] = dcf_ground_state(p, Wmin, m);

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

S;

% 2. Packet loss probability
