function binned = load_wireshark_trace(file, nBins)

    wireshark = csvread(file);
    minTime = wireshark(1,1);
    maxTime = wireshark(end,1);
    totTime = maxTime - minTime;
    deltaTime = totTime / nBins;
    binEdges = minTime:deltaTime:maxTime;

    binned = zeros(1,nBins-1);
    for i=1:nBins-1
        startTime = binEdges(i);
        endTime = binEdges(i+1);

        indices = find(wireshark >= startTime & wireshark <= endTime);
        binned(i) = sum( wireshark(indices,2) );
    end
end
