function plot_traces( types, prefix, nBins, minPacketsize, plotEmpty )
    numTypes = size(types, 1);
    time = 1:nBins-1;
    
    binned = cell(1, numTypes);
    bps = cell(1, numTypes);
    typename = cell(1, numTypes);
    
    numValid = 0;
    for i = 1:numTypes
        typename{i} = trace.Name('', types(i));
        filename = sprintf('./../traces/%s_%s.csv', prefix, typename{i});
        
        if (exist(filename, 'file') == 2)
            %binnedWeb(binnedWeb>mean(binnedWeb)+4*std(binnedWeb))=2*mean(binnedWeb);
            [binned{i}, bps{i}] = load_trace_csv(filename, nBins, minPacketsize);
            fprintf('%s %s: %0.2f Mbps\n', prefix, typename{i}, bps{i}/1000000);
            numValid = numValid + 1;
        else
            if (plotEmpty)
                typename{i} = sprintf('(not generated) %s', typename{i});
                binned{i} = zeros(1, nBins-1);
                numValid = numValid + 1;
            else
                typename{i} = '';
            end
        end
    end
    
    figure
    cols = ceil(numValid / 5);
    rows = ceil(numValid / cols);
    
    numPlots = 0;
    for i = 1:numTypes
        if (size(typename{i}, 2) ~= 0)
            numPlots = numPlots + 1;
            subplot(rows, cols, numPlots);
            plot(time, binned{i});
            title(sprintf('%s %s', prefix, strrep(typename{i}, '_', ' ')));
        end
    end
end