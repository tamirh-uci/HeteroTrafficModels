clear all;
close all;

% -----------------------------
% CONSTANTS
% -----------------------------
VID_FILE = 'serenity_480p_trailer.mp4';
START_FRAME = 100;
END_FRAME = 500;
BYTES_PER_PACKET = 1500;
COMPARE_AGAINST_UNCOMPRESSED_SRC = true;


% -----------------------------
% TODO: Load in NS3 data
% -----------------------------
badPackets = [100, 101, 102, 157, 191, 222]; % placeholder data


% -----------------------------
% Prep the video files
% -----------------------------
vu = video_util();
vu.frameStart = START_FRAME;
vu.nFrames = END_FRAME - START_FRAME + 1;
vu.nBytesPerPacket = BYTES_PER_PACKET;
vu.baseFilename = VID_FILE;
vu.prep();


[mangledPsnr, ~] = vu.decodeMangled(badPackets, COMPARE_AGAINST_UNCOMPRESSED_SRC);
[baselinePsnr, ~] = vu.decodeMangled([], COMPARE_AGAINST_UNCOMPRESSED_SRC);


% -----------------------------
% Plot results
% -----------------------------
mangledPsnrData = cell(1,1);
psnrLabels = cell(1,1);
timedataLabels = cell(1,1);

mangledPsnrData{1,1} = mangledPsnr;
psnrLabels{1} = '';
timedataLabels{1} = '';

plot_viddata(1, mangledPsnrData, baselinePsnr, [], [], psnrLabels, timedataLabels);
