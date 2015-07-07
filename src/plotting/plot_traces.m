function plot_traces( types, prefix, time, binned )
    numTypes = size(types, 1);
    cols = ceil(numTypes / 5);
    rows = ceil(numTypes / cols);
    
    titles = cell(1, numTypes);
    for i = 1:numTypes
        titles{i} = strrep(trace.Name(prefix, types(i)), '_', ' ');
    end
    
    index = 1;
    for col = 1:cols
        for row = 1:rows
            if (index > numTypes)
                break;
            end
            
            subplot(rows, cols, index);
            plot(time, binned{index});
            title(titles{index});
            index = index + 1;
        end
    end
end
