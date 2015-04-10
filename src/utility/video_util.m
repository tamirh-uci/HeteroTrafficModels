classdef video_util < handle
    %VIDEO_UTIL Stuff to handle load/save of videos
    
    properties
        % http://www.h264info.com/clips.html
        DEFAULT_FOLDER = 'C:\Users\rawkuts\Downloads\';
        DEFAULT_FILE = 'serenity_hd_dvd_trailer.mp4';
        DEFAULT_START_FRAME = 100;
        DEFAULT_NFRAMES = 150;
        DEFAULT_QP = 27;
        DEFAULT_BLOCK_SIZE = 16;
    end
    
    methods (Static)
        function [fNameOrig, fNameSrcU, fNameSrcC, fNameDstC] = subFilenames(folder, fNameIn, frameStart, nFrames)
            fNameOrig = [folder fNameIn];
            
            subsection = ['.' num2str(frameStart) '-' num2str(nFrames)];
            fNameSrcU = [folder 'src_u_' fNameIn subsection '.avi'];
            fNameSrcC = [folder 'src_c_' fNameIn subsection '.mp4'];
            fNameDstC = [folder 'dst_c_' fNameIn subsection '.mp4'];
        end
        
        % Take input video and extract subset of frames and reencode
        function extractFrames(fNameIn, fNameOut, encoding, frameStart, nFrames)
            % Read in the video file to memory
            fprintf('reading video: %s [%d-%d]\n', fNameIn, frameStart, frameStart+nFrames-1);
            [vidData, ~, ~] = video_util.reader(fNameIn, frameStart, nFrames);
            
            % Write the video file back out
            fprintf('writing video: %s (%s)\n', fNameOut, encoding);
            video_util.writer(vidData, VideoWriter(fNameOut, encoding));
        end
        
        % Prep input data by creating compressed and uncompressed src data
        function prepInput(fNameOrig, fNameSrcU, fNameSrcC, frameStart, nFrames)
            assert( exist(fNameOrig, 'file') == 2 );
            
            if (exist(fNameSrcU, 'file') ~= 2)
                fprintf('Generating uncompressed version of %s\n', fNameOrig);
                video_util.extractFrames(fNameOrig, fNameSrcU, 'Uncompressed AVI', frameStart, nFrames);
            else
                fprintf('Uncompressed version of %s already exists, skipping\n', fNameOrig);
            end
            
            if (exist(fNameSrcC, 'file') ~= 2)
                fprintf('Generating compressed version of %s\n', fNameOrig);
                video_util.extractFrames(fNameOrig, fNameSrcC, 'MPEG-4', frameStart, nFrames);
            else
                fprintf('Compressed version of %s already exists, skipping\n', fNameOrig);
            end
        end
        
        % Mangle frames listed in badFrames
        % Input and output will be MPEG4 compressed data streams
        function mangle(fNameSrcC, fNameDstC, nFrames, ~)
            % TODO: Do mangle here
            
            % This just re-encodes
            [vidData, ~, ~] = video_util.reader(fNameSrcC, 1, nFrames);
            video_util.writer(vidData, VideoWriter(fNameDstC, 'MPEG-4'));
        end
        
        function [peaksnr, snr] = psnr(vidDataSrc, vidDataDst, nFrames)
            peaksnr = zeros(1, nFrames);
            snr = zeros(1, nFrames);
            for i=1:nFrames
                src = vidDataSrc(i).cdata;
                dst = vidDataDst(i).cdata;
                [peaksnr(i), snr(i)] = psnr(dst, src, 255);
            end
        end
        
        % Test the difference between two video files
        function [peaksnr, snr] = test_diff(fNameSrc, fNameDst, nFrames)
            fprintf('Calculating PSNR of %s...\n', fNameDst);
            
            [vidDataSrc, vidHeightSrc, vidWidthSrc] = video_util.reader(fNameSrc, 1, nFrames);
            [vidDataDst, vidHeightDst, vidWidthDst] = video_util.reader(fNameDst, 1, nFrames);
            
            % Check some basic sizing values match up
            assert(vidHeightSrc == vidHeightDst);
            assert(vidWidthSrc == vidWidthDst);
            assert(size(vidDataSrc, 2) == nFrames);
            assert(size(vidDataDst, 2) == nFrames);
            
            % calculate differences between two videos
            [peaksnr, snr] = video_util.psnr(vidDataSrc, vidDataDst, nFrames);
        end
        
        function [vidData, height, width] = reader(fName, frameStart, nFramesOut)
            vidObj = VideoReader(fName);
            
            nFrames = vidObj.NumberOfFrames;
            assert(frameStart >= 1);
            assert((frameStart + nFramesOut - 1) <= nFrames);
            
            width = vidObj.Width;
            height = vidObj.Height;
            
            % array for raw rgb data (colormap ignored)
            vidData(1:nFramesOut) = struct('cdata', zeros(height, width, 3, 'uint8'), 'colormap', []);
            for i = 1:nFramesOut
                % dump frame data into our local struct
                vidData(i).cdata = vidObj.read(frameStart + i - 1);
            end
        end
        
        function writer(vidData, vidObj)
            nFrames = size(vidData, 2);
            open(vidObj);
            
            % Dump frame data into video
            for k = 1:nFrames
                vidObj.writeVideo(vidData(k).cdata);
            end
            
            close(vidObj);
        end
    end
    
    methods
        function obj = video_util()
            obj = obj@handle();
        end
        
        function test(this)
            frameStart = this.DEFAULT_START_FRAME;
            nFrames = this.DEFAULT_NFRAMES;
            [fNameOrig, fNameSrcU, fNameSrcC, fNameDstC] = video_util.subFilenames(this.DEFAULT_FOLDER, this.DEFAULT_FILE, frameStart, nFrames);
            
            fprintf('\n=============PREP INPUT==============\n');
            video_util.prepInput(fNameOrig, fNameSrcU, fNameSrcC, frameStart, nFrames);
            
            fprintf('\n===============MANGLE================\n');
            badFrames = nFrames/2 : nFrames;
            video_util.mangle(fNameSrcC, fNameDstC, nFrames, badFrames);
            
            fprintf('\n=============TEST DIFF===============\n');
            [psnrUtoC, snrUtoC] = video_util.test_diff(fNameSrcU, fNameSrcC, nFrames);
            [psnrUtoMC, snrUtoMC] = video_util.test_diff(fNameSrcU, fNameDstC, nFrames);
            [psnrCtoMC, snrCtoMC] = video_util.test_diff(fNameSrcC, fNameDstC, nFrames);
            
            % plot stuff
            fprintf('Plotting...');
            figure
            
            % Peak SNR Plot
            subplot(2,1,1);
            plot(psnrUtoC, 'r');
            hold on;
            plot(psnrUtoMC, 'b');
            plot(psnrCtoMC, 'c');
            hold off;
            xlabel('Frame');
            ylabel('Peak SNR');
            legend('compression', 'from uncompressed to mangled', 'from compressed to mangled');
            
            subplot(2,1,2);
            plot(snrUtoC, 'r');
            hold on;
            plot(snrUtoMC, 'b');
            plot(snrCtoMC, 'c');
            hold off;
            xlabel('Frame');
            ylabel('SNR');
            legend('compression', 'from uncompressed to mangled', 'from compressed to mangled');

            fprintf('\nDone!\n');
        end
    end
end
