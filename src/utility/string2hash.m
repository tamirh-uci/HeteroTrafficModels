% Run larson hash multiple times and concat values
function hash = string2hash(str, repeat)
    rng = RandStream.create('mt19937ar', 'Seed', 1);
    salts = randsample(rng, primes(10000), repeat);
    
    in = uint64(str);
    hash = uint64( zeros(1, repeat) );
    for i=1:repeat
        hash(i) = hash_larson(in, 101, salts(i));
    end
end
