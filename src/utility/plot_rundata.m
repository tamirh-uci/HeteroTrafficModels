function plot_rundata( figNum, figFile, figTitle, figYLabel, labels, plotColors, nVariations, nSimulations, data )
    figure(figNum);
    ax = axes;
    
    hold(ax, 'on');
    for j=1:nVariations
        simData = data(:, j);
        plot( simData, 'Color', plotColors(j, :), 'LineWidth', 3 );
    end
    set(ax, 'XTick', 1:nSimulations);
    hold(ax, 'off');
    title(figTitle);
    xlabel('Number of nodes');
    ylabel(figYLabel);
    legend(labels, 'Location', 'southeast');
    
    if (size(figFile, 2) > 1)
        savefig(figFile);
    end
end
