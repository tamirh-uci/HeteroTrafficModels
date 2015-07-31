function overallMax = plot_traces( types, prefix, nBins, minPacketsize, plotEmpty, scaleGraph, initMax )
    numTypes = size(types, 1);
    time = 1:nBins-1;
    
    colors = distinguishable_colors(numTypes);
    binned = cell(1, numTypes);
    bps = cell(1, numTypes);
    typename = cell(1, numTypes);
    overallMax = initMax;
    
    numValid = 0;
    for i = 1:numTypes
        typename{i} = trace.Name('', types(i));
        filename = sprintf('./../traces/%s_%s.csv', prefix, typename{i});
        
        if (exist(filename, 'file') == 2)
            [binned{i}, bps{i}] = load_trace_csv(filename, nBins, minPacketsize);
        end
        
        if (~isempty(binned{i}))
            binned{i} = binned{i} / 1000; % kpbs
            
            % get rid of extreme outliers
            outlierEdge = mean(binned{i})+4*std(binned{i});
            binned{i}( binned{i} > outlierEdge) = outlierEdge;
            
            binMax = max(binned{i});
            overallMax = max(binMax, overallMax);
            
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
            
            plot(time, binned{i}, 'LineWidth', 1.5, 'Color', colors(i, :));
            ylabel('kpbs');
            title(sprintf('%s %s', prefix, strrep(typename{i}, '_', ' ')));
            
            if (scaleGraph)
                axis([0 nBins 0 overallMax]);            
            end
        end
    end
end