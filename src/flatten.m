function [ index ] = flatten( dims, point )

    % reduce to 0-based indexing    
    copy = point - 1;
    length = size(point,2);
    
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