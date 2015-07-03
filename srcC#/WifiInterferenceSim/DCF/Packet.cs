using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    struct Packet
    {
        public int queueArrival;
        public int txAttempt;
        public int txSuccess;
        public int payloadSize;

        public Packet(int arrival, int size)
        {
            queueArrival = arrival;
            txAttempt = -1;
            txSuccess = -1;
            payloadSize = size;
        }

        public bool IsValid()
        {
            return (queueArrival >=0 && payloadSize >= 0);
        }

        public void Invalidate()
        {
            queueArrival = -1;
            txAttempt = -1;
            txSuccess = -1;
            payloadSize = -1;
        }
    }
}
