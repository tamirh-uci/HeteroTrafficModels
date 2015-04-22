% Larson hash (expcets in to be of type uint64)
function h = hash_larson(in, prime, salt)
    h = uint64(salt);
    p = uint64(prime);
    
    % MATLAB doesn't have real integer overflow
    % So we'll restrict the number of bits we use so that we don't bump
    % up against 2^64 on our multiplication pass
    max = uint64(2^50 - 1);
    
    for c = in
        h = mod(h * p + c, max);
    end
end
