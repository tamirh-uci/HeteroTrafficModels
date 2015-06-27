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
    
    allMovAvgPsnr = cell(1, nVariations);
    nTimeIndices = size(mangledPsnrData{1,1} ,2);
    
    for j=1:nVariations
        allMovAvgPsnr{j} = zeros( nSimulations, size(mangledPsnrData{1,j}, 2) ); % TODO: what's up with indexing here?
        for i=1:nSimulations
            normalizedPsnr = mangledPsnrData{i,j} ./ baselinePsnr;
            allMovAvgPsnr{j}(i,:) = normalizedPsnr; %smooth(normalizedPsnr, movAvgWindow);
        end
    end
    
    plotIndex = 0;
    plotColors = distinguishable_colors(nSimulations);
    for j=1:nVariations
        plotIndex = 1 + plotIndex;
        movAvgPsnr = allMovAvgPsnr{j};
        
        plot_timedata( nPlots, [nVariations 1], plotIndex, sprintf('Moving Average Normalized PSNR %s', psnrLabsl{j}), ...
            'transfers', timedataLabels, plotColors, nSimulations, nTimeIndices, movAvgPsnr);
    end
end
