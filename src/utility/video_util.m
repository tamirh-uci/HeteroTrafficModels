classdef video_util < handle
    %VIDEO_UTIL Stuff to handle load/save of videos
    
    properties
        % http://www.h264info.com/clips.html
        DEFAULT_FOLDER = 'C:\Users\rawkuts\Downloads\';
        DEFAULT_FILE_IN = 'serenity_hd_dvd_trailer.mp4';
        DEFAULT_FILE_OUT = 'mod-serenity_hd_dvd_trailer.avi';
    end
    
    methods (Static)
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
            nFrames = size(vidData,2);
            
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
            this.dostuff(200, 100);
        end
        
        function dostuff(this, frameStart, nFrames)
            fNameIn = [this.DEFAULT_FOLDER this.DEFAULT_FILE_IN];
            fNameOut = [this.DEFAULT_FOLDER this.DEFAULT_FILE_OUT];
            
            % Read in the video file to memory
            fprintf('reading video\n');
            [vidData, ~, ~] = video_util.reader(fNameIn, frameStart, nFrames);
            
            % Mangle some video data
            fprintf('mangling data');
            for i = 25:50
                fprintf('.');
                frame = vidData(i).cdata;
                frame(:,:,2) = 255; % set green to full on entire frame
                vidData(i).cdata = frame;
            end
            fprintf('\n');
            
            % Write the video file back out
            fprintf('writing video\n');
            video_util.writer(vidData, VideoWriter(fNameOut, 'Uncompressed AVI'));
        end
    end
    
end
