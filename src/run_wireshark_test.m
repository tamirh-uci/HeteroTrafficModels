clear all;
close all;

nBins = 1000;
time = 1:nBins-1;
minPacketsize = 25;

graphWireshark=false;
graphGenerated=true;

if (graphWireshark)
    [binnedWeb, bpsWeb] = load_wireshark_trace('./../Wireshark Web Browsing - web_browsing.csv', nBins, minPacketsize);
    [binnedVid, bpsVid] = load_wireshark_trace('./../Wireshark Youtube - streaming_video.csv', nBins, minPacketsize);
    [binnedFil, bpsFil] = load_wireshark_trace('./../Wireshark Bittorrent Download - bittorrent.csv', nBins, minPacketsize);

    figure
    plot(time, binnedWeb, 'r', time, binnedVid, 'g', time, binnedFil, 'b');
    title('web (red) vs. video (green) vs. file (blue)');
    
    figure
    plot(time, binnedWeb, 'r');
    title('web (red)');

    figure
    plot(time, binnedVid, 'g');
    title('video (green)');

    figure
    plot(time, binnedFil, 'b');
    title('file (blue)');
    
    fprintf('Wireshark Web Traffic: %0.2f Mbps\n', bpsWeb/1000000);
    fprintf('Wireshark Vid Traffic: %0.2f Mbps\n', bpsVid/1000000);
    fprintf('Wireshark Fil Traffic: %0.2f Mbps\n', bpsFil/1000000);
end

if (graphGenerated)
    [binnedWeb, bpsWeb] = load_wireshark_trace('./../results/trace_web.csv', nBins, minPacketsize);
    [binnedVid, bpsVid] = load_wireshark_trace('./../results/trace_video.csv', nBins, minPacketsize);
    [binnedFil, bpsFil] = load_wireshark_trace('./../results/trace_file.csv', nBins, minPacketsize);
    
    
    % remove outliers
    binnedWeb(binnedWeb>mean(binnedWeb)+4*std(binnedWeb))=2*mean(binnedWeb);
    binnedVid(binnedVid>mean(binnedVid)+4*std(binnedVid))=2*mean(binnedWeb);
    binnedFil(binnedFil>mean(binnedFil)+4*std(binnedFil))=2*mean(binnedWeb);

    fprintf('Generated Web Traffic: %0.2f Mbps\n', bpsWeb/1000000);
    fprintf('Generated Vid Traffic: %0.2f Mbps\n', bpsVid/1000000);
    fprintf('Generated Fil Traffic: %0.2f Mbps\n', bpsFil/1000000);
    
    figure
    plot(time, binnedWeb, 'r', time, binnedVid, 'g', time, binnedFil, 'b');
    
    figure
    plot(time, binnedWeb, 'r');
    title('web (red)');

    figure
    plot(time, binnedVid, 'g');
    title('video (green)');

    figure
    plot(time, binnedFil, 'b');
    title('file (blue)');
end