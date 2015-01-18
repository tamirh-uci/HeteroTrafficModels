% FHSS physical model in 802.11 standard
p = 0.5;
Wmin = 2;
Wmax = 4; %1024;
m = log2(Wmax / Wmin)

[pi] = dcf_matrix(p, m, Wmin);
pi;