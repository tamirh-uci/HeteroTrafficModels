function [ index ] = flatten( dims, point )
    copy = point;
    
    ll = size(point);
    length = ll(2);
    for i = 1:length
        copy(i) = copy(i) - 1; % reduce to 0-based indexing
    end
    
    sum = 0;
    for i = 1:(length - 1)
        prod = 1;
        for j = (i + 1):length
           prod = prod * dims(j);
        end
        sum = sum + (prod * copy(i));
    end
    sum = sum + copy(length);
    
    index = sum + 1;
end