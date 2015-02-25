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
    name = sprintf('Normal node %d', i);
    sim.add_dcf_matrix(name, dcf_matrix);
end

% Add a multimedia node
media_matrix = markov_video_frames();
media_matrix.gopAnchorFrameDistance = 3;
media_matrix.gopFullFrameDistance = 12;

for i=1:1
    name = sprintf('Multimedia node %d', i);
    sim.add_multimedia_matrix(name, dcf_matrix, media_matrix);
end


sim.Setup();
sim.Steps(10000);
assert( sim.CountInvalid() == 0 );
sim.PrintResults();

[groundProbability] = dcf_ground_state(pSuccessSingleTransmit, Wmin, m);

%%%% Metrics computation
% Note: all time parameters must have the same units
E_p = 5; % TODO: depends on type of traffic
T_s = 10; % TODO: depends on E_p
T_c = 10; % TODO: depends on E_p
n = 2; % number of nodes -- make this a parameter
sigma = 5; % TODO

% 1. Throughput
[tau] = dcf_tau(pSuccessSingleTransmit, Wmin, m);
P_tr = (1 - (1 - tau)^n);
P_s = (n * tau * (1 - tau)^(n - 1)) / (1 - (1 - tau)^n);
[S] = dcf_throughput( P_s, P_tr, E_p, sigma, T_s, T_c );

fprintf('tau=%f\tP_tr=%f\tP_s=%f\n', tau, P_tr, P_s);
fprintf('\n');
