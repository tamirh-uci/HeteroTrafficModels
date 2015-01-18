function [ p ] = dcf_ground_state( p, Wmin, m )
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here

    num = 2 * (1 - 2*p) * (1 - p);
    denom = ((1 - 2*p) * (Wmin + 1)) + ((p*Wmin) * (1 - (2 * p)^m));
    p = num / denom;

end

