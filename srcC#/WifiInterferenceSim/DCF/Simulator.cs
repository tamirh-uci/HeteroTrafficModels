using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class Simulator
    {
        List<DCFNode> simnodes;
        Physical80211 network;

        public Simulator(Physical80211 _network)
        {
            simnodes = new List<DCFNode>();
            network = _network;
        }

        public void AddNode(DCFNode node)
        {
            simnodes.Add(node);
        }

        public void Steps(int nSteps)
        {
            foreach (DCFNode node in simnodes)
            {
                node.Init(nSteps);
            }

            int numTransmitting;
            for (int i = 0; i < nSteps; ++i)
            {
                // Each node steps forward in time one timeslice
                numTransmitting = 0;
                foreach (DCFNode node in simnodes)
                {
                    node.Step();
                    numTransmitting += node.IsTransmitting() ? 1 : 0;
                }

                // If multiple nodes are transmitting, they will be forced to all fail
                if (numTransmitting > 1)
                {
                    foreach (DCFNode node in simnodes)
                    {
                        node.Fail();
                    }
                }

                // Finally, record history of what just happened
                foreach (DCFNode node in simnodes)
                {
                    node.PostStep();
                }
            }
        }

        public void PrintResults(double qualityThreshold)
        {
            Console.WriteLine("Nodes: {0}", simnodes.Count);

            bool first = true;
            foreach(DCFNode node in simnodes)
            {
                node.PrintResults(network, first, qualityThreshold);
                first = false;
                Console.WriteLine("\n");
            }
        }

        public void WriteCSVResults(string filebase)
        {
            foreach(DCFNode node in simnodes)
            {
                node.WriteCSVResults(network, filebase);
                
            }
        }
    }
}
