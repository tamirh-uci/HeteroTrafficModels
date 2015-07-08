using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class SimTrace
    {
        // History of all steps taken
        public List<DCFState> states;

        // History of all our transmitted packets
        public List<Packet> sent;

        // Leftover packets
        public Queue<Packet> queue;

        // The type of network we simulated on 
        public Physical80211 network;

        public SimTrace(int _steps, Physical80211 _network)
        {
            network = _network;
            states = new List<DCFState>(_steps);
            sent = new List<Packet>();
            queue = new Queue<Packet>();
        }

        public void WritePacketTraceCSV(StreamWriter writer)
        {
            double secondsPerSlot = Physical80211.TransactionTime(network.type, network.payloadBits) / 1000000.0;
            foreach (Packet p in sent)
            {
                double time = p.txSuccess * secondsPerSlot;
                writer.WriteLine("{0},{1}", time, p.payloadSize * network.payloadBits / 8);
            }

            writer.Flush();
            writer.Close();
        }
    }
}
