using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    enum TrafficType
    {
        Web_Videocall,
        Web_MultipleNewTabs,
        Web_FTPDownload,
        YouTube_AudioVideo,
        Skype_Audio,
        Skype_Video,
        Skype_AudioVideo,
        Bittorrent_Leeching,
        Background,
    }

    class TrafficUtil
    {
        public static string ShortName(TrafficType type)
        {
            switch (type)
            {
                case TrafficType.Web_Videocall: return "Wvc";
                case TrafficType.Web_MultipleNewTabs: return "Wmt";
                case TrafficType.Web_FTPDownload: return "Wft";
                case TrafficType.YouTube_AudioVideo: return "Yav";
                case TrafficType.Skype_Audio: return "Saa";
                case TrafficType.Skype_Video: return "Svv";
                case TrafficType.Skype_AudioVideo: return "Sav";
                case TrafficType.Bittorrent_Leeching: return "Ble";
                case TrafficType.Background: return "Bkg";

                default:
                    throw new NotSupportedException();
            }
        }

        public static string Name(TrafficType type)
        {
            switch (type)
            {
                case TrafficType.Web_Videocall: return "web_videocall";
                case TrafficType.Web_MultipleNewTabs: return "web_multiple-new-tabs";
                case TrafficType.Web_FTPDownload: return "web_ftp-download";
                case TrafficType.YouTube_AudioVideo: return "youtube_audio-video";
                case TrafficType.Skype_Audio: return "skype_audio";
                case TrafficType.Skype_Video: return "skype_video";
                case TrafficType.Skype_AudioVideo: return "skype_audio-video";
                case TrafficType.Bittorrent_Leeching: return "bittorrent_leeching";
                case TrafficType.Background: return "background";

                default:
                    throw new NotSupportedException();
            }
        }
    }
}
