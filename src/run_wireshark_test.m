run_set_path
close all;

nBins = 200;
time = 1:nBins-1;
minPacketsize = 1;

graphWireshark=true;
graphGenerated=false;
graphCSharpGenerated=false;

if (graphWireshark)
    types = enumeration('trace_type');
    numTypes = size(types, 1);
    binned = cell(1, numTypes);
    bps = cell(1, numTypes);
    
    for i = 1:numTypes
        filename = sprintf('%s.csv', trace.Name('./../traces/wireshark_', types(i)));
        [binned{i}, bps{i}] = load_wireshark_trace(filename, nBins, minPacketsize);
    end
    
    figure
    plot_traces(types, 'wireshark ', time, binned);
    
    for i = 1:numTypes
        fprintf('%s: %0.2f Mbps\n', trace.Name('wireshark ', types(i)), bps{i}/1000000);
    end
end

if (graphGenerated)
    [binnedWeb, bpsWeb] = load_wireshark_trace('./../results/trace_web.csv', nBins, minPacketsize);
    [binnedVid, bpsVid] = load_wireshark_trace('./../results/trace_video.csv', nBins, minPacketsize);
    [binnedFil, bpsFil] = load_wireshark_trace('./../results/trace_file.csv', nBins, minPacketsize);
    
    
    % remove outliers
    binnedWeb(binnedWeb>mean(binnedWeb)+4*std(binnedWeb))=2*mean(binnedWeb);
    binnedVid(binnedVid>mean(binnedVid)+4*std(binnedVid))=2*mean(binnedVid);
    binnedFil(binnedFil>mean(binnedFil)+4*std(binnedFil))=2*mean(binnedFil);

    fprintf('Generated Web Traffic: %0.2f Mbps\n', bpsWeb/1000000);
    fprintf('Generated Vid Traffic: %0.2f Mbps\n', bpsVid/1000000);
    fprintf('Generated Fil Traffic: %0.2f Mbps\n', bpsFil/1000000);
    
    %figure
    %plot(time, binnedWeb, 'r', time, binnedVid, 'g', time, binnedFil, 'b');
    
    figure
    
    subplot(4,1,1);
    plot(time, binnedWeb, 'r');
    title('Original DCF web');

    subplot(4,1,2);
    plot(time, binnedVid, 'g');
    title('Original DCF video');
    
    subplot(4,1,3);
    plot(time, zeros(size(binnedWeb,1), size(binnedWeb,2)), 'm');
    title('Did not simulate');
    
    subplot(4,1,4);
    plot(time, binnedFil, 'b');
    title('Original DCF file');
end

if (graphCSharpGenerated)
    [binnedWeb, bpsWeb] = load_wireshark_trace('./../results/newsim_0-web.csv', nBins, minPacketsize);
    [binnedVid, bpsVid] = load_wireshark_trace('./../results/newsim_0-video.csv', nBins, minPacketsize);
    [binnedCal, bpsCal] = load_wireshark_trace('./../results/newsim_0-call.csv', nBins, minPacketsize);
    [binnedFil, bpsFil] = load_wireshark_trace('./../results/newsim_0-files.csv', nBins, minPacketsize);
    [binnedFul, bpsFul] = load_wireshark_trace('./../results/newsim_0-full.csv', nBins, minPacketsize);
    
    fprintf('Generated Web Traffic: %0.2f Mbps\n', bpsWeb/1000000);
    fprintf('Generated Vid Traffic: %0.2f Mbps\n', bpsVid/1000000);
    fprintf('Generated Fil Traffic: %0.2f Mbps\n', bpsFil/1000000);
    fprintf('Generated Ful Traffic: %0.2f Mbps\n', bpsFul/1000000);
    
    %figure
    %plot(time, binnedWeb, 'r', time, binnedVid, 'g', time, binnedFil, 'b');
    
    figure
    
    subplot(4,1,1);
    plot(time, binnedWeb, 'r');
    title('Buffer Sim w/ Sleep web (browsing text+images)');

    subplot(4,1,2);
    plot(time, binnedVid, 'g');
    title('Buffer Sim w/ Sleep video stream (YouTube)');
    
    subplot(4,1,3);
    plot(time, binnedCal, 'm');
    title('Buffer Sim w/ Sleep video call (Skype)');

    subplot(4,1,4);
    plot(time, binnedFil, 'b');
    title('Buffer Sim w/ Sleep file (BitTorrent)');
    
    %figure
    %plot(time, binnedFul, 'm');
    %title('full');
end