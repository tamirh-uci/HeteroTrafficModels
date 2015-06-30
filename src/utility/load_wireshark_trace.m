function [binned, bps] = load_wireshark_trace(file, nBins, minPacketSize)

    wireshark = csvread(file);
    wiresharkTimes = wireshark(:,1);
    wiresharkPacketSizes = wireshark(:,2);
    
    minTime = wiresharkTimes(1);
    maxTime = wiresharkTimes(end);
    totTime = maxTime - minTime;
    deltaTime = totTime / nBins;
    binEdges = minTime:deltaTime:maxTime;
    bytesSent = sum(wiresharkPacketSizes);
    bps = bytesSent*8/totTime;

    binned = zeros(1,nBins-1);
    for i=1:nBins-1
        startTime = binEdges(i);
        endTime = binEdges(i+1);

        indices = find(wiresharkTimes >= startTime & wiresharkTimes <= endTime & wiresharkPacketSizes >= minPacketSize);
        binned(i) = sum( wiresharkPacketSizes(indices) );
    end
end
