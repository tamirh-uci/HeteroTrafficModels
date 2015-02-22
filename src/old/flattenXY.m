function [ ii, jj ] = flattenXY( dims, x, y )
    ii = flatten(dims, x);
    jj = flatten(dims, y);