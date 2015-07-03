﻿using System;
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
            cfg.awakeTime = 25;
            cfg.drowsyTime = 100;
            cfg.pDrowsySleep = 0.01;
            cfg.minSleep = 1;
            cfg.maxSleep = 25;

            cfg.minBufferEmptySleep = 100;
            cfg.maxBufferEmptySleep = 500;

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
        /// Video traffic is fairly regular like file downloads but sleeps are much shorter
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams VideoCall(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

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

            // We have many more full data packets for video
            cfg.pSmallPayload = 0.26;

            return cfg;
        }

        /// <summary>
        /// Video streaming traffic takes long sleeps, assumes longer buffer
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams VideoStream(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

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

            cfg.pSmallPayload = 0.56;

            return cfg;
        }

        /// <summary>
        /// Full traffic saturation
        /// </summary>
        /// <param name="network">802.11 network type</param>
        /// <param name="bps">Incoming BPS of source</param>
        /// <returns>params for DCFNode</returns>
        public static DCFParams Full(Physical80211 network, double bps)
        {
            DCFParams cfg = new DCFParams();

            cfg.packetArrivalRate = network.PacketArrivalRate(bps);

            // Never have interarrivals
            cfg.pInterarrival = 0;

            // Even sleep schedule, sleeps are very short
            cfg.awakeTime = 0;
            cfg.drowsyTime = 0;
            cfg.pDrowsySleep = 0;
            cfg.minSleep = 0;
            cfg.maxSleep = 0;

            // Always send single
            cfg.minPayload = 1;
            cfg.maxPayload = 1;
            cfg.pSmallPayload = 1.00;

            return cfg;
        }
    }
}