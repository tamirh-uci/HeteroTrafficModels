function plot_timedata( figNum, subplotSize, subplotIndex, figTitle, figYLabel, labels, plotColors, nPlots, nX, data )
    figure(figNum);
    ax = subplot(subplotSize(1), subplotSize(2), subplotIndex);
    hold(ax, 'on');
    
    for j=1:nPlots
        simData = data(j, :);
        plot( ax, simData, 'Color', plotColors(j, :), 'LineWidth', 1.5 );
    end
    set(ax, 'XTick', 1:nX);
    hold(ax, 'off');
    title(ax, figTitle);
    xlabel(ax, 'Number of nodes');
    ylabel(ax, figYLabel);
    legend(ax, labels, 'Location', 'southeast');
end
