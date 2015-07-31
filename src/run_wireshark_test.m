run_set_path
close all;

NUM_BINS = 200;
MIN_PACKETSIZE = 1;

types = enumeration('trace_type');

GRAPH_WIRESHARK = false;
GRAPH_V1SIM = false;
GRAPH_V2SIM = true;
GRAPH_FLAT = true;

if (GRAPH_WIRESHARK)
    fprintf('\nGraphing wireshark data\n');
    plot_traces(types, 'wireshark', NUM_BINS, MIN_PACKETSIZE, true, true, 0);
    plot_traces(types, 'wireshark', NUM_BINS, MIN_PACKETSIZE, true, false, 0);
end

if (GRAPH_V1SIM)
    fprintf('\nGraphing v1sim data\n');
    plot_traces(types, 'v1sim', NUM_BINS, MIN_PACKETSIZE, true, true, 0);
end

if (GRAPH_V2SIM)
    fprintf('\nGraphing v2sim data\n');
    max = plot_traces(types, 'v2sim', NUM_BINS, MIN_PACKETSIZE, false, true, 0);
end

if (GRAPH_FLAT)
    fprintf('\nGraphing flat data\n'); 
    for i=1:5
        plot_traces(types, sprintf('v2sim_flat%d', i), NUM_BINS, MIN_PACKETSIZE, false, true, max);
    end
end
