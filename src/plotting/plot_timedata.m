function plot_timedata( figNum, subplotSize, subplotIndex, figTitle, figYLabel, labels, plotColors, nPlots, nX, data, limits )
    figure(figNum);
    
    ax = subplot(subplotSize(1), subplotSize(2), subplotIndex);
    hold(ax, 'on');
    
    for j=1:nPlots
        simData = data(j, :);
        plot( ax, simData, 'Color', plotColors(j, :), 'LineWidth', 1.5 );
    end
    
    d = 2;
    if (nX > 100)
        d = 10;
    end
    
    if (nX > 300)
        d = 25;
    end
    
    if (nX > 700)
        d = 50;
    end
    
    set(ax, 'XTick', 0:d:nX);
    hold(ax, 'off');
    title(ax, figTitle);
    xlabel(ax, 'Simulation Time');
    ylabel(ax, figYLabel);
    
    if (~isempty(limits))
        axis(limits);
    end
    
    if (~isempty(labels))
        legend(ax, labels, 'Location', 'southeast');
    end
end
