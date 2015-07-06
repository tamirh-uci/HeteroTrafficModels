close all;
run_set_path

% -----------------------------
% CONSTANTS
% -----------------------------
VID_FILE = 'serenity_480p_trailer.mp4';
START_FRAME = 250;
END_FRAME = 500;
BYTES_PER_PACKET = 1500;
COMPARE_AGAINST_UNCOMPRESSED_SRC = true;


% -----------------------------
% TODO: Load in NS3 data
% -----------------------------
NUM_TRACES = 3;
badPackets = cell(1, NUM_TRACES);

% placeholder data
badPackets{1} = 100:200; 
badPackets{2} = 500:600;
badPackets{3} = [15, 16, 25, 55, 82];

labels = cell(1, NUM_TRACES);
labels{1} = 'bad packets 100-200';
labels{2} = 'bad packets 500-600';
labels{3} = 'bad packets 15, 16, 25, 55, 82';

% -----------------------------
% Prep the video files
% -----------------------------
vu = video_util();
vu.frameStart = START_FRAME;
vu.nFrames = END_FRAME - START_FRAME + 1;
vu.nBytesPerPacket = BYTES_PER_PACKET;
vu.baseFilename = VID_FILE;
vu.prep();

[baselinePsnr, ~] = vu.decodeMangled([], COMPARE_AGAINST_UNCOMPRESSED_SRC);

mangledPsnr = cell(1, NUM_TRACES);
for i = 1:NUM_TRACES
    [mangledPsnr{i}, ~] = vu.decodeMangled(badPackets{i}, COMPARE_AGAINST_UNCOMPRESSED_SRC);
end

% -----------------------------
% Plot results
% -----------------------------
plot_viddata(1, mangledPsnr, baselinePsnr, [], [], labels, []);
