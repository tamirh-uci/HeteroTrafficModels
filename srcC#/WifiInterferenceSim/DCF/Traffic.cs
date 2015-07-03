using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class Traffic
    {
        /// <summary>
        /// File download traffic, very steady and low variability
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams File(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);
            
            // Rely solely on packet buffer for interarrival
            cfg.pInterarrival = 0.0;
            
            // Approximately send half, sleep half
            cfg.awakeTime = 200;
            cfg.drowsyTime = 25;
            cfg.pDrowsySleep = 0.1;
            cfg.minSleep = 150;
            cfg.maxSleep = 200;

            return cfg;
        }

        /// <summary>
        /// Web traffic, very bursty and highly variable
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Web(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Bursts have some gaps
            cfg.pInterarrival = 0.025;
            cfg.minInterarrival = 1;
            cfg.maxInterarrival = 10;

            // Probability to sleep at almost all times
            cfg.awakeTime = 25;
            cfg.drowsyTime = 300;
            cfg.pDrowsySleep = 0.005;
            cfg.minSleep = 25;
            cfg.maxSleep = 400;

            return cfg;
        }

        /// <summary>
        /// Video traffic is fairly regular like file downloads but sleeps are much shorter
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Video(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Very often, and very short interarrivals
            cfg.pInterarrival = 0.05;
            cfg.minInterarrival = 1;
            cfg.maxInterarrival = 4;

            // Even sleep schedule, sleeps are very short
            cfg.awakeTime = 25;
            cfg.drowsyTime = 25;
            cfg.pDrowsySleep = 0.1;
            cfg.minSleep = 5;
            cfg.maxSleep = 10;

            // We have many more full data packets for video
            cfg.pSmallPayload = 0.26;

            return cfg;
        }
    }
}
