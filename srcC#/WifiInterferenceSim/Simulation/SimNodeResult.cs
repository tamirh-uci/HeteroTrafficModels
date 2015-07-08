using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class SimNodeResult
    {
        public TrafficType type;
        public string name;
        public double qualityThreshold;

        public double secondsPerSlot;
        public double timeSpent;
        public Int64 thresholdSlots;

        public Int64 packetsSent;
        public Int64 packetsUnsent;
        public Int64 packetsOverThreshold;
        public Int64 timeSlotsOverThreshold;
        public Int64 maxTimeSlotsOverThreshold;
        public Int64 maxSleepStage;

        public double avgSleepStage;
        public double avgTimeSlotsOverThreshold;
        public Int64 bitsSent;
        public double datarate;

        public SimTrace trace;

        public void PrintResults(Physical80211 network, bool overviewInfo)
        {
            if (overviewInfo)
            {
                Console.WriteLine("Steps: {0}", trace.states.Count);
                Console.WriteLine("Slot Duration: {0:F2} milliseconds", secondsPerSlot * 1000.0);
                Console.WriteLine("Threshold: {0:F2} milliseconds (~{1} slots)", qualityThreshold * 1000.0, thresholdSlots);
                Console.WriteLine("Time elapsed: {0:F3} seconds", timeSpent);
                Console.WriteLine("\n");
            }

            Console.WriteLine(" ==Sim Node '{0}'==", name);
            Console.WriteLine(" Packets Sent: {0} ({1} still in buffer)", packetsSent, packetsUnsent);
            Console.WriteLine(" Data Sent: {0:F1} bits ({1:F2} Mbits)", bitsSent, bitsSent / 1000000.0);
            Console.WriteLine(" Datarate: {0:F1} bps ({1:F2} Mbps)", datarate, datarate / 1000000.0);
            Console.WriteLine(" Packets over threshold: {0}", packetsOverThreshold);
            Console.WriteLine(" Time spent over threshold: {0:F2} milliseconds ({1} slots)", secondsPerSlot * timeSlotsOverThreshold * 1000.0, timeSlotsOverThreshold);
            Console.WriteLine(" Time spent over threshold per packet: {0:F2} milliseconds ({1:F2} slots)", secondsPerSlot * avgTimeSlotsOverThreshold * 1000.0, avgTimeSlotsOverThreshold);
            Console.WriteLine(" Max time spent over threshold: {0:F2} milliseconds ({1} slots)", secondsPerSlot * maxTimeSlotsOverThreshold * 1000.0, maxTimeSlotsOverThreshold);
            Console.WriteLine(" Average sleep stage: {0:F2} (max {1})", avgSleepStage, maxSleepStage);
        }
    }
}
