classdef video_util < handle
    %VIDEO_UTIL Stuff to handle load/save of videos
    
    properties (Constant)
        % http://www.h264info.com/clips.html
        DEFAULT_INPUT_FOLDER = './../results/';
        DEFAULT_OUTPUT_FOLDER = './../results/cache/video/';
        DEFAULT_FILE = 'serenity_480p_trailer.mp4';
        DEFAULT_START_FRAME = 150;
        DEFAULT_NFRAMES = 1000;
        DEFAULT_PACKETSIZE = 1500;
    end
    
    properties
        fNameOrig;
        fNameSrcU;
        fNameSrcC;
        fNameDstC;
        packetRanges;
        frameStart;
        nFrames;
        nBytesPerPacket;
        resDst;
        baseFilename;
        inputFolder;
        outputFolder;
    end
    
    properties
        nBytesSrcC;
        nPacketsSrcC;
        fpsSrcC;
        bpsSrcC;
        durationSrcC;
    end
    
    methods (Static)
        function exe = ffmpeg_exe()
            exeLocations = {'E:\Downloads\ffmpeg-20150414-git-013498b-win64-static\bin\ffmpeg.exe' 'C:\Users\rawkuts\Downloads\ffmpeg-20150605-git-7be0f48-win64-static\bin\ffmpeg.exe'};
                        
            for i=1:size(exeLocations,2)
                exe = exeLocations{i};
                if (exist(exe, 'file'))
                    return;
                end
            end
            
            % Try it on the system path
            exe = 'ffmpeg';
        end
        
        %function exe = xvid_encode()
            %exe = 'C:\Users\rawkuts\Downloads\xvidcore\build\win32\bin\xvid_encraw.exe';
        %end
        
        %function exe = xvid_decode()
            %exe = 'C:\Users\rawkuts\Downloads\xvidcore\build\win32\bin\xvid_decraw.exe';
        %end
        
        function [fNameOrig, fNameSrcU, fNameSrcC, fNameDstC] = subFilenames(folderIn, folderOut, fNameIn, frameStart, nFrames)
            fNameOrig = fullfile(folderIn, fNameIn);
            
            subsection = ['.' num2str(frameStart) '-' num2str(frameStart+nFrames-1)];
            fNameSrcU = fullfile(folderOut, ['src_u_' fNameIn subsection '.avi']);
            fNameSrcC = fullfile(folderOut, ['src_c_' fNameIn subsection '.mp4']);
            fNameDstC = fullfile(folderOut, ['dst_c_' fNameIn subsection '.mp4']);
            
            if (~exist(folderOut, 'dir'))
                mkdir(folderOut);
            end
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
            
            % Compress from the uncompressed source
            if (exist(fNameSrcC, 'file') ~= 2)
                fprintf('Generating compressed version of %s\n', fNameSrcU);
                video_util.extractFrames(fNameSrcU, fNameSrcC, 'MPEG-4', 1, nFrames);
            else
                fprintf('Compressed version of %s already exists, skipping\n', fNameSrcU);
            end
        end
        
        % Mangle frames listed in badFrames
        % Input and output will be MPEG4 compressed data streams
        function mangle(fNameSrcC, fNameDstC, ~, badPackets, bytesPerPacket)
            copyfile(fNameSrcC, fNameDstC, 'f');
            
            % Open the destination as a byte stream
            dstFile = fopen(fNameDstC, 'r+');
            
            % Make sure the header stuff is all in tact
            % assume first 8KB are protected
            protectedPackets = ceil(8192.0/bytesPerPacket);
            
            for badPkt = badPackets
                if (badPkt > protectedPackets)
                    % Seek to bad packet location
                    offset = (badPkt-1)*bytesPerPacket;
                    fseek(dstFile, offset, 'bof');
                    data = fread(dstFile, bytesPerPacket);
                    
                    % Overwrite 75% of the packet with zeros 
                    overwrite = rand(bytesPerPacket, 1) > 0.75;
                    
                    fseek(dstFile, offset, 'bof');
                    fwrite(dstFile, data .* overwrite, 'uint8');
                    
                    fseek(dstFile, offset, 'bof');
                    dataOut = fread(dstFile, bytesPerPacket);
                end
            end
            
            fclose(dstFile);
        end
        
        function [peaksnr, snr] = psnr_pics(srcPrefix, dstPrefix, nFrames)
            peaksnr = zeros(1, nFrames);
            snr = zeros(1, nFrames);
            
            for i=1:nFrames
                loaded = false;
                src = imread( sprintf('%s_%08d.png', srcPrefix, i) );
                
                try
                    dst = imread( sprintf('%s_%08d.png', dstPrefix, i) );
                    loaded = true;
                catch
                end
                
                % If we couldn't load the destination image, try just using
                % the 1st frame of source as reference
                if (~loaded)
                    try
                        dst = imread( sprintf('%s_%08d.png', srcPrefix, 1) );
                        loaded = true;
                    catch
                        % finally just give up and set values to NaN
                        peaksnr(i) = NaN;
                        snr(i) = NaN;
                        printf('ERROR: Frame %d was not encoded');
                    end
                end
                
                if (loaded)
                    [peaksnr(i), snr(i)] = psnr(dst, src);
                end
            end
        end
        
        function [peaksnr, snr] = psnr_vids(vidDataSrc, vidDataDst, nFrames)
            peaksnr = zeros(1, nFrames);
            snr = zeros(1, nFrames);
            for i=1:nFrames
                src = vidDataSrc(i).cdata;
                dst = vidDataDst(i).cdata;
                [peaksnr(i), snr(i)] = psnr(dst, src, 255);
            end
        end
        
        function vid_to_pics(srcFile, outputPrefix)
            exe = sprintf('%s -i %s -r 30 %s_%%08d.png', video_util.ffmpeg_exe(), srcFile, outputPrefix);
            fprintf(' Running command: %s\n', exe);
            system(exe);
        end
        
        % Test the difference between two video files
        function [peaksnr, snr] = test_diff(fNameSrc, fNameDst, nFrames)
            fprintf('Generating source and mangled frames for: %s...\n', fNameDst);
            
            % Dump temp files into a folder so we can delete it after
            baseDir = fullfile(tempdir(), 'snr');
            srcPrefix = fullfile(baseDir, 'src');
            dstPrefix = fullfile(baseDir, 'dst');
            
            if (~exist(baseDir, 'dir'))
                mkdir(baseDir);
            end
            
            %[vidDataSrc, vidHeightSrc, vidWidthSrc] = video_util.reader(fNameSrc, 1, nFrames);
            %[vidDataDst, vidHeightDst, vidWidthDst] = video_util.reader(fNameDst, 1, nFrames);
            %[peaksnr, snr] = video_util.psnr(vidDataSrc, vidDataDst, nFrames);
            
            % Convert video files to frames of PNG for comparision
            % We don't use built in matlab video reader because it crashes
            % when it encounters bad frames
            video_util.vid_to_pics(fNameSrc, srcPrefix);
            video_util.vid_to_pics(fNameDst, dstPrefix);
            
            fprintf('Calculating PSNR for: %s...\n', fNameDst);
            [peaksnr, snr] = video_util.psnr_pics(srcPrefix, dstPrefix, nFrames);
            
            % clean up our temp files
            rmdir(baseDir, 's');
        end
        
        function [vidData, height, width] = reader(fName, frameStart, nFramesOut)
            vidObj = VideoReader(fName);
            
            frames = vidObj.NumberOfFrames;
            assert(frameStart >= 1);
            assert((frameStart + nFramesOut - 1) <= frames);
            
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
            frames = size(vidData, 2);
            open(vidObj);
            
            % Dump frame data into video
            for k = 1:frames
                vidObj.writeVideo(vidData(k).cdata);
            end
            
            close(vidObj);
        end
    end
    
    methods
        function obj = video_util()
            obj = obj@handle();
            obj.frameStart = video_util.DEFAULT_START_FRAME;
            obj.nFrames = video_util.DEFAULT_NFRAMES;
            obj.nBytesPerPacket = video_util.DEFAULT_PACKETSIZE;
            obj.baseFilename = video_util.DEFAULT_FILE;
            obj.inputFolder = video_util.DEFAULT_INPUT_FOLDER;
            obj.outputFolder = video_util.DEFAULT_OUTPUT_FOLDER;
        end
        
        function prep(this)
            [this.fNameOrig, this.fNameSrcU, this.fNameSrcC, this.fNameDstC] = video_util.subFilenames(this.inputFolder, this.outputFolder, this.baseFilename, this.frameStart, this.nFrames);
            video_util.prepInput(this.fNameOrig, this.fNameSrcU, this.fNameSrcC, this.frameStart, this.nFrames);
            
            fileInfoSrcC = dir(this.fNameSrcC);
            this.nBytesSrcC = fileInfoSrcC.bytes;
            this.nPacketsSrcC = ceil( this.nBytesSrcC / this.nBytesPerPacket );
            
            vidObj = VideoReader(this.fNameSrcC);
            this.fpsSrcC = vidObj.FrameRate;
            this.durationSrcC = vidObj.Duration;
            this.bpsSrcC = (this.nBytesSrcC * 8) / this.durationSrcC;
        end
        
        function filename = getFile(this, type)
            switch(type)
                case 'sU'
                    filename = this.fNameSrcU;
                case 'sC'
                    filename = this.fNameSrcC;
                case 'dU'
                    filename = this.fNameDstU;
                case 'dC'
                    filename = this.fNameDstC;
            end
        end
        
        function [psnr, snr] = decodeMangled(this, badPackets, uncompressedSrc)
            dstType = 'dC';
            
            if (uncompressedSrc)
                srcType = 'sU';
            else
                srcType = 'sC';
            end
            
            video_util.mangle(this.fNameSrcC, this.fNameDstC, this.nFrames, badPackets, this.nBytesPerPacket);
            [psnr, snr] = video_util.test_diff( this.getFile(srcType), this.getFile(dstType), this.nFrames);
        end
    end
end
