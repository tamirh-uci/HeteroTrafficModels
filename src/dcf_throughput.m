function [ S ] = dcf_throughput( P_s, P_tr, E_p, sigma, T_s, T_c )
% P_s = probability that TX is successful
% P_tr = probability that at least node transmits on the channel
% E_p = average packet payload size
% sigma = duration of empty slot time
% T_s = average time the channel is sensed busy because of successful TX
% T_c = average time the channel is sensed busy because of collision

num = P_s * P_tr * E_p;
denom = ((1 - P_tr) * sigma) + (P_tr * P_s * T_s) + (P_tr * (1 - P_s) * T_c);
S = num / denom;

end
