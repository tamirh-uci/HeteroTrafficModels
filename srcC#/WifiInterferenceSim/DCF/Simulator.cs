using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class Simulator
    {
        List<DCFNode> simnodes;

        public Simulator()
        {
            simnodes = new List<DCFNode>();
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
                    numTransmitting++;
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

        public void PrintResults(Physical80211 network, double qualityThreshold)
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
    }
}
