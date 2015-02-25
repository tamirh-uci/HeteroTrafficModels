timeSteps = 100000; 
pSuccess = 0.25; 
pArrive = 1;
pEnter = 0;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin);
W = zeros(1,m+1);
for i = 1:(m+1)
    W(1,i) = (2^(i-1)) * Wmin;
end

% create the simulator
simulator = dcf_simulator_oo(pSuccess, 0);

% create the nodes we want to participate in the sim
n1 = dcf_matrix_factory(pArrive, pEnter, m, Wmin, 1, 0);
n2 = dcf_matrix_factory(pArrive, pEnter, m, Wmin, 1, 0);
simulator.add_dcf_matrix(n1);
simulator.add_dcf_matrix(n2);

simulator.Setup();

% run the simulation
simulator.Steps(1000);
simulator.PrintResults();
