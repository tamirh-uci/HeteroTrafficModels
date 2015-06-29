nBins = 500;
minPacketsize = 25;

binnedWeb = load_wireshark_trace('./../Wireshark Web Browsing - web_browsing.csv', nBins, minPacketsize);
binnedVid = load_wireshark_trace('./../Wireshark Youtube - streaming_video.csv', nBins, minPacketsize);
binnedFil = load_wireshark_trace('./../Wireshark Bittorrent Download - bittorrent.csv', nBins, minPacketsize);
time = 1:nBins-1;

figure
plot(time, binnedWeb, 'r', time, binnedVid, 'g', time, binnedFil, 'b');
title('web (red) vs. video (green) vs. file (blue)');
