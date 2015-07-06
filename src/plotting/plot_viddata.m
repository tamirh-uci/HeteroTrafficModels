function nPlots = plot_viddata(currentPlot, mangledPsnrData, baselinePsnr, meanMangledPsnr, medMangledPsnr, psnrLabsl, timedataLabels)
    [nSimulations, nVariations] = size(mangledPsnrData);
    
    % PSNR
    nPlots = 1 + currentPlot;
    plotColors = distinguishable_colors(nVariations);
    if (~isempty(meanMangledPsnr))
        plot_rundata( nPlots, [2 1], 1, 'Mean PSNR with dropped packets (lower better)', ...
            'PSNR', psnrLabsl, plotColors, nVariations, nSimulations, meanMangledPsnr);
    end
    
    if (~isempty(medMangledPsnr))
        plot_rundata( nPlots, [2 1], 2, 'Median PSNR with dropped packets (lower better)', ...
            'PSNR', psnrLabsl, plotColors, nVariations, nSimulations, medMangledPsnr);
    end
    
    allNormPsnr = cell(1, nVariations);
    nTimeIndices = size(mangledPsnrData{1,1} ,2);
    
    % Normalize against our baseline
    for j=1:nVariations
        allNormPsnr{j} = zeros( nSimulations, size(mangledPsnrData{1,j}, 2) );
        for i=1:nSimulations
            normalizedPsnr = mangledPsnrData{i, j} ./ baselinePsnr;
            allNormPsnr{j}(i,:) = 100*normalizedPsnr; %smooth(normalizedPsnr, movAvgWindow);
        end
    end
    
    plotIndex = 0;
    plotColors = distinguishable_colors(nSimulations);
    limits = [0 size(allNormPsnr{1}, 2) 0 1];
    for j=1:nVariations
        minValue = min(allNormPsnr{j});
        maxValue = max(allNormPsnr{j});
        limits(3) = min(limits(3), minValue);
        limits(4) = max(limits(4), maxValue);
    end
    for j=1:nVariations
        plotIndex = 1 + plotIndex;
        normPsnr = allNormPsnr{j};
        
        plot_timedata( nPlots, [nVariations 1], plotIndex, sprintf('Normalized PSNR %s', psnrLabsl{j}), ...
            'Percent of baseline PSNR', timedataLabels, plotColors, nSimulations, nTimeIndices, normPsnr, limits);
    end
end
