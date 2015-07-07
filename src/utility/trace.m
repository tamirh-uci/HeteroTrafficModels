classdef trace < handle
    methods (Static)
        function name = Name(prefix, type)
            switch(type)
                case trace_type.bittorrent_leeching
                    typename = 'bittorrent_leeching';
                    
                case trace_type.skype_audio
                    typename = 'skype_audio';
                    
                case trace_type.skype_video
                    typename = 'skype_video';
                    
                case trace_type.skype_audio_video
                    typename = 'skype_audio-video';
                    
                case trace_type.web_multiple_new_tabs
                    typename = 'web_multiple-new-tabs';
                    
                case trace_type.web_videocall
                    typename = 'web_videocall';
                    
                case trace_type.web_ftp_download
                    typename = 'web_ftp-download';
                    
                case trace_type.youtube_audio_video
                    typename = 'youtube_audio-video';
                    
                case default
                    assert(false);
            end
            
            name = sprintf('%s%s', prefix, typename);
        end
    end
end

