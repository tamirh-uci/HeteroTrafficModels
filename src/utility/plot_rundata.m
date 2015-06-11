function plot_rundata( figNum, subplotSize, subplotIndex, figFile, figTitle, figYLabel, labels, plotColors, nVariations, nSimulations, data )
    figure(figNum);
    ax = subplot(subplotSize(1), subplotSize(2), subplotIndex);
    hold(ax, 'on');
    
    for j=1:nVariations
        simData = data(:, j);
        plot( ax, simData, 'Color', plotColors(j, :), 'LineWidth', 3 );
    end
    set(ax, 'XTick', 1:nSimulations);
    hold(ax, 'off');
    title(ax, figTitle);
    xlabel(ax, 'Number of nodes');
    ylabel(ax, figYLabel);
    legend(ax, labels, 'Location', 'southeast');
    
    if (size(figFile, 2) > 1)
        savefig(figFile);
    end
end
