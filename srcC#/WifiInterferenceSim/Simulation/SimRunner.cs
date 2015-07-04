using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class SimRunner
    {
        Physical80211 network;
        bool cartesian;

        SimParams mainSimParams;
        List<SimParams> competingSimParams;

        List<Simulator> simulators;
        List<List<SimulationResults>> results;

        public SimRunner(Physical80211 _network, bool _cartesian)
        {
            network = _network;
            cartesian = _cartesian;

            simulators = new List<Simulator>();
            results = new List<List<SimulationResults>>();
            competingSimParams = new List<SimParams>();
        }

        public void SetMainSim(SimParams _mainSim)
        {
            mainSimParams = _mainSim;
        }

        public void AddCompetingSim(SimParams competingSim)
        {
            competingSimParams.Add(competingSim);
        }

        public string SimulatorName(List<int> numNodes)
        {
            StringBuilder s = new StringBuilder();
            s.AppendFormat("{0}main", Traffic.ShortName(mainSimParams.type));

            for (int i=0; i<competingSimParams.Count; ++i)
            {
                s.AppendFormat("-{0}{1}", Traffic.ShortName(competingSimParams[i].type), numNodes[i]);
            }

            return s.ToString();
        }

        private void AddSimulator(List<int> numNodes)
        {
            Simulator sim = new Simulator(network, SimulatorName(numNodes));
            AddNode(sim, mainSimParams, "main", 1);

            for (int i = 0; i < competingSimParams.Count; ++i )
            {
                AddNode(sim, competingSimParams[i], "node", numNodes[i]);
            }

            simulators.Add(sim);
        }

        private void AddNode(Simulator sim, SimParams simParams, string namePrefix, int numNodes)
        {
            if (numNodes <= 0)
                return;

            DCFParams dcfParams = Traffic.MakeTraffic(simParams.type, network, simParams.arrivalBps);
            for (int i=1; i<=numNodes; ++i)
            {
                string name = String.Format("{0}{1}-{2}", namePrefix, Traffic.Name(simParams.type), i);
                sim.AddNode(new DCFNode(name, dcfParams, simParams.randSeed, simParams.qualityThreshold));
            }
        }

        public void RunSims(int repititions, int steps)
        {
            int length = competingSimParams.Count;
            if (cartesian && length > 0)
            {
                // Limits
                List<int> min = new List<int>();
                List<int> max = new List<int>();
                List<int> cur = new List<int>();
                for (int i=0; i<length; ++i)
                {
                    min.Add(competingSimParams[i].minNodes);
                    max.Add(competingSimParams[i].maxNodes);
                    cur.Add(competingSimParams[i].minNodes);
                }

                // Create a cartesian product of all variations
                // Loop through min-max at every level
                while (cur[0] <= max[0])
                {
                    // Add a simulation with the current set of params
                    AddSimulator(cur);

                    // Increment the last param by one
                    int cartesianIndex = length - 1;
                    cur[length - 1]++;

                    // Cascade any overflow
                    while( cur[cartesianIndex] > max[cartesianIndex] )
                    {
                        // Reset current overflowed value to minimum
                        cur[cartesianIndex] = min[cartesianIndex];

                        // Go to previous index, and increment
                        if (--cartesianIndex >= 0)
                        {
                            cur[cartesianIndex]++;
                        }
                    }
                }
            }
            else
            {
                // use maxNodes as number of nodes to add as main
                for (int i=0; i<length; ++i)
                {
                    mainSimParams = competingSimParams[i];

                    List<int> cur = new List<int>();
                    for (int j = 0; j < length; ++j)
                    {
                        if (i==j)
                        {
                            // See how many more copies of the main node we're adding
                            cur.Add(competingSimParams[j].maxNodes - 1);
                        }
                        else
                        {
                            // Other nodes get their min value of nodes
                            cur.Add(competingSimParams[i].minNodes);
                        }
                    }

                    AddSimulator(cur);
                }
            }

            foreach (Simulator sim in simulators)
            {
                List<SimulationResults> variationResults = new List<SimulationResults>();
                for (int run=0; run<repititions; ++run)
                {
                    sim.Steps(steps);
                    variationResults.Add(sim.GetResults());
                }

                results.Add(variationResults);
            }
        }
    }
}
