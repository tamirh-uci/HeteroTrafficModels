run_set_path

% number of nodes in system
MAX_DATANODES = 2;
MAX_VIDNODES = 1;

% Shared params
simParams = dcf_simulation_params();
timesteps = 100;
simParams.pSingleSuccess = [0.20, 0.40, 0.60, 0.80, 1.0];

% Video node stuff
nVideoNodes = 1;
bps = 800000;

% File node stuff
nFileNodes = 1;
nSizeTypes = 1;
nInterarrivalTypes = 1;
fileBigness = 1.0;
fileWaityness = 1.0;
wMin = 8;
wMax = 16;

nVariations = 5;
datanodeSlowWaitQuality = zeros(5, MAX_DATANODES);
datanodeSlowWaitCount = zeros(5, MAX_DATANODES);

for i=1:MAX_DATANODES
    videonode = traffic_video_stream(nVideoNodes, wMin, wMax, bps, [], []);
    datanode = traffic_file_downloads(nFileNodes, wMin, wMax, nSizeTypes, nInterarrivalTypes, fileBigness, fileWaityness); 

    sim = dcf_simulation('cachetest');
    sim.nTimesteps = timesteps;
    sim.params = simParams;

    sim.AddNodegen( videonode );
    
    for j=1:i
        sim.AddNodegen( datanode );
    end
    
    sim.Run();
    
    nSimResults = size(sim.simResults,2);
    for j=1:nSimResults
        results = sim.simResults{j};
        datanodeSlowWaitQuality(j, i) = results.nodeSlowWaitQuality(1);
        datanodeSlowWaitCount(j, i) = results.nodeSlowWaitCount(1);
    end
end
 
figure(1);
ax = axes;
hold(ax, 'on');
plot(0);
for i=1:nSimResults
    simSlowWaitQuality = datanodeSlowWaitQuality(i,:);
    plot(simSlowWaitQuality, 'Color', sim.plotColors(i,:));
end
hold(ax, 'off');

title('Time spent waiting over threshold');
xlabel('Number of data nodes');
ylabel('Time (microseconds)');


figure(2);
ax = axes;
hold(ax, 'on');
plot(0);
for i=1:nSimResults
    simSlowWaitCount = datanodeSlowWaitCount(i,:);
    plot(simSlowWaitCount, 'Color', sim.plotColors(i,:));
end
hold(ax, 'off');
title('Number of packets waiting over threshold');
xlabel('Simulation Variation');
ylabel('Packet Count');
