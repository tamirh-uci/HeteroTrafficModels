% FHSS physical model in 802.11 standard
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
% -> W = (2 4)

%%%% Transition matrix generation
dcf_matrix = dcf_matrix_collapsible();
dcf_matrix.m = m;
dcf_matrix.wMin = Wmin;
dcf_matrix.nPkt = 1;
dcf_matrix.nInterarrival = 0;
dcf_matrix.pEnterInterarrival = 0.0;
dcf_matrix.pRawArrive = 1.0;

pSuccessSingleTransmit = 0.75;
pSuccessMultiTransmit = 0.0;
sim = dcf_simulator_oo(pSuccessSingleTransmit, pSuccessMultiTransmit);

for i=1:1
    sim.add_dcf_matrix(dcf_matrix);
end

sim.Setup();
sim.Steps(10000);

successes = sim.CountSuccesses();
failures = sim.CountFailures();
waits = sim.CountWaits();
successPercent = successes/(successes+failures);
transmitPercent = successes/(successes+failures+waits);

[groundProbability] = dcf_ground_state(pSuccessSingleTransmit, Wmin, m);

%%%% Metrics computation
% Note: all time parameters must have the same units
E_p = 5; % TODO: depends on type of traffic
T_s = 10; % TODO: depends on E_p
T_c = 10; % TODO: depends on E_p
n = 2; % number of nodes -- make this a parameter
sigma = 5; % TODO

% 1. Throughput
[tau] = dcf_tau(pSuccessSingleTransmit, Wmin, m)
P_tr = (1 - (1 - tau)^n)
P_s = (n * tau * (1 - tau)^(n - 1)) / (1 - (1 - tau)^n)
[S] = dcf_throughput( P_s, P_tr, E_p, sigma, T_s, T_c );

S;

% 2. Packet loss probability
fprintf('Success %%: %f, Transmit %%: %f\n\n', 100*successPercent, 100*transmitPercent);
