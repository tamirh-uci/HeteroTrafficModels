run_set_path
close all;

NUM_BINS = 200;
MIN_PACKETSIZE = 1;

types = enumeration('trace_type');

GRAPH_WIRESHARK = true;
GRAPH_V1SIM = true;
GRAPH_V2SIM = true;

if (GRAPH_WIRESHARK)
    fprintf('\nGraphing wireshark data\n');
    plot_traces(types, 'wireshark', NUM_BINS, MIN_PACKETSIZE, true, true);
    plot_traces(types, 'wireshark', NUM_BINS, MIN_PACKETSIZE, true, false);
end

if (GRAPH_V1SIM)
    fprintf('\nGraphing v1sim data\n');
    plot_traces(types, 'v1sim', NUM_BINS, MIN_PACKETSIZE, true, true);
end

if (GRAPH_V2SIM)
    fprintf('\nGraphing v2sim data\n');
    plot_traces(types, 'v2sim', NUM_BINS, MIN_PACKETSIZE, true, true);
end
