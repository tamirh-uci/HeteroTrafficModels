using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.Simulation
{
    struct SimulationNodeResults
    {
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
    }
}
