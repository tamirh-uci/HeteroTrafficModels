using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class Traffic
    {
        public static DCFParams MakeTraffic(TrafficType type, Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            switch (type)
            {
                case TrafficType.Web_Videocall: return Web_VideoCall(network, bps, nodeParams);
                case TrafficType.Web_MultipleNewTabs: return Web_MultipleNewTabs(network, bps, nodeParams);
                case TrafficType.Web_FTPDownload: return Web_FTPDownload(network, bps, nodeParams);
                case TrafficType.YouTube_AudioVideo: return YouTube_AudioVideo(network, bps, nodeParams);
                case TrafficType.Skype_Audio: return Skype_Audio(network, bps, nodeParams);
                case TrafficType.Skype_Video: return Skype_Video(network, bps, nodeParams);
                case TrafficType.Skype_AudioVideo: return Skype_AudioVideo(network, bps, nodeParams);
                case TrafficType.Bittorrent_Leeching: return Bittorrent_Leeching(network, bps, nodeParams);
                
                default:
                    throw new NotSupportedException();
            }
        }

        /// <summary>
        /// Video traffic is fairly regular like file downloads but sleeps are much shorter
        /// Web based video call, less efficient than skype it seems
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Web_VideoCall(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Web_Videocall, nodeParams);

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Very often, and very short interarrivals
            cfg.pInterarrival = 0.25;
            cfg.minInterarrival = 1;
            cfg.maxInterarrival = 8;

            // Even sleep schedule, sleeps are very short
            cfg.awakeTime = 5;
            cfg.drowsyTime = 200;
            cfg.pDrowsySleep = 0.02;
            cfg.minSleep = 1;
            cfg.maxSleep = 8;

            cfg.minBufferEmptySleep = 1;
            cfg.maxBufferEmptySleep = 100;

            return cfg;
        }

        /// <summary>
        /// Web traffic, very bursty and highly variable
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Web_MultipleNewTabs(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Web_MultipleNewTabs, nodeParams);

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Bursts have some gaps
            cfg.pInterarrival = 0.65;
            cfg.minInterarrival = 2;
            cfg.maxInterarrival = 15;

            // Probability to sleep at almost all times, but bursty when there is data
            cfg.awakeTime = 50;
            cfg.drowsyTime = 150;
            cfg.pDrowsySleep = 0.01;
            cfg.minSleep = 1;
            cfg.maxSleep = 100;

            cfg.minBufferEmptySleep = 250;
            cfg.maxBufferEmptySleep = 1750;

            return cfg;
        }

        /// <summary>
        /// Video streaming traffic takes long sleeps, assumes longer buffer
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams YouTube_AudioVideo(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.YouTube_AudioVideo, nodeParams);

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Very often, and very short interarrivals
            cfg.pInterarrival = 0.7;
            cfg.minInterarrival = 1;
            cfg.maxInterarrival = 10;

            // Even sleep schedule, sleeps are very short
            cfg.awakeTime = 500;
            cfg.drowsyTime = 500;
            cfg.pDrowsySleep = 0.001;
            cfg.minSleep = 100;
            cfg.maxSleep = 200;

            cfg.minBufferEmptySleep = 2400;
            cfg.maxBufferEmptySleep = 2600;

            return cfg;
        }

        /// <summary>
        /// Skype traffic with only audio, silences get compressed down to almost nothing
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Skype_Audio(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Skype_Audio, nodeParams);

            // TODO: CHANGE ME
            cfg.packetArrivalRate = 0; //network.PacketArrivalRate(bps);

            return cfg;
        }

        /// <summary>
        /// Skype traffic with only video, still images get compressed quite a bit
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Skype_Video(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Skype_Video, nodeParams);

            // TODO: CHANGE ME
            cfg.packetArrivalRate = 0; //network.PacketArrivalRate(bps);

            return cfg;
        }

        /// <summary>
        /// Skype traffic with both audio and video
        /// Is this just a combination of the separate streams?
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Skype_AudioVideo(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Skype_AudioVideo, nodeParams);

            // TODO: CHANGE ME
            cfg.packetArrivalRate = 0; //network.PacketArrivalRate(bps);

            return cfg;
        }

        /// <summary>
        /// Full traffic saturation
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Web_FTPDownload(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Web_FTPDownload, nodeParams);

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Never have interarrivals
            cfg.pInterarrival = 0;

            // Even sleep schedule, sleeps are very short
            cfg.awakeTime = 0;
            cfg.drowsyTime = 0;
            cfg.pDrowsySleep = 0;
            cfg.minSleep = 0;
            cfg.maxSleep = 0;

            return cfg;
        }


        /// <summary>
        /// BitTorrent download traffic, very steady and low variability
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Bittorrent_Leeching(Physical80211 network, double bps, TrafficNodeParams nodeParams)
        {
            DCFParams cfg = new DCFParams(TrafficType.Bittorrent_Leeching, nodeParams);

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Rely solely on packet buffer for interarrival
            cfg.pInterarrival = 0.0;

            // Approximately send half, sleep half
            cfg.awakeTime = 25;
            cfg.drowsyTime = 100;
            cfg.pDrowsySleep = 0.01;
            cfg.minSleep = 1;
            cfg.maxSleep = 25;

            cfg.minBufferEmptySleep = 100;
            cfg.maxBufferEmptySleep = 500;

            return cfg;
        }

    }
}
