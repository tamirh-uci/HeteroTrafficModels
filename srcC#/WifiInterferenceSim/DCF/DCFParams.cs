using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class DCFParams
    {
        // How many packets arrive in the queue per step
        public double packetArrivalRate;

        // How many packets we will send before considering sleeping
        public int awakeTime;

        // How many packets we will have a possibility to sleep before forcing it
        public int drowsyTime;

        // min/max duration of deep sleeps
        public int minSleep, maxSleep;

        // min/max durations of sleep when buffer is empty
        public int minBufferEmptySleep, maxBufferEmptySleep;

        // min/max values of backoff, should be powers of 2
        public int minBackoff, maxBackoff;

        // min/max number of steps to send payload
        public int minPayload, maxPayload;

        // min/max number of steps to not send once we reach a transmit state
        public int minInterarrival, maxInterarrival;

        // interarrival only applies below this value of data in the buffer
        public int interarrivalCutoff;

        // Probability to sleep while we're drowsy
        public double pDrowsySleep;

        // Probability to enter interarrival chain 
        public double pInterarrival;

        // Probability we use minPayload, other values for payload are evenly distributed
        public double pSmallPayload;

        public DCFParams()
        {
            packetArrivalRate = 0.1;

            minPayload = 1;
            maxPayload = 2;

            interarrivalCutoff = 5;
            minInterarrival = 1;
            maxInterarrival = 4;

            awakeTime = 300;
            drowsyTime = 100;

            minSleep = 1;
            maxSleep = 200;

            minBufferEmptySleep = 10;
            maxBufferEmptySleep = 50;
            
            minBackoff = 8;
            maxBackoff = 32;

            pDrowsySleep = 0.05;
            pInterarrival = 0.0;
            pSmallPayload = 0.5;
        }
    }
}
