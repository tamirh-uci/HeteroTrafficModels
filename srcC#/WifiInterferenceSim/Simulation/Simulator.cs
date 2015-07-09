using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class Simulator
    {
        List<DCFNode> simnodes;
        SimRunResult simRunResult;
        Physical80211 network;

        int simIndex;
        string simName;
        string groupName;
        public TrafficType mainType;

        public Simulator(Simulator referenceSim, int runIndex)
        {
            network = referenceSim.network;

            simRunResult = new SimRunResult(referenceSim.simName, referenceSim.groupName, referenceSim.simIndex, runIndex);
            simnodes = new List<DCFNode>(referenceSim.simnodes.Count);
            foreach (DCFNode referenceNode in referenceSim.simnodes)
            {
                simnodes.Add(referenceNode);
            }

            mainType = referenceSim.mainType;
        }

        public Simulator(Physical80211 _network, string _simName, string _groupName, int _simIndex)
        {
            network = _network;
            simName = _simName;
            simIndex = _simIndex;
            groupName = _groupName;

            simnodes = new List<DCFNode>();
            simRunResult = new SimRunResult(_simName, _groupName , _simIndex, -1);
        }

        public string SimName { get { return simName; } }
        public string GroupName { get { return groupName; } }
        public int SimIndex { get { return simIndex; } }

        public void AddNode(DCFNode node)
        {
            if (simnodes.Count == 0)
            {
                mainType = node.cfg.type;
            }

            simnodes.Add(node);
        }

        public void Steps(int nSteps, bool keepTrace)
        {
            foreach (DCFNode node in simnodes)
            {
                node.Init(nSteps, network);
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

            // Stats
            foreach (DCFNode node in simnodes)
            {
                simRunResult.Add(node.CalculateResults(keepTrace));
            }
        }

        public SimRunResult GetResults()
        {
            return simRunResult;
        }
    }
}
