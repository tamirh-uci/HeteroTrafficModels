using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
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

        SimParams mainParams;
        List<SimParams> competingParams;

        List<Simulator> simulators;
        List<List<SimulationResults>> results;

        public SimRunner(Physical80211 _network, bool _cartesian)
        {
            network = _network;
            cartesian = _cartesian;

            mainParams = null;
            simulators = new List<Simulator>();
            results = new List<List<SimulationResults>>();
            competingParams = new List<SimParams>();
        }

        public void SetMain(SimParams _main)
        {
            mainParams = _main;
        }

        public void AddCompeting(SimParams competing)
        {
            competingParams.Add(competing);
        }

        private string SimulatorName(List<int> numNodes)
        {
            StringBuilder s = new StringBuilder();
            s.AppendFormat("main-{0}_", Traffic.ShortName(mainParams.type));

            for (int i=0; i<competingParams.Count; ++i)
            {
                s.AppendFormat("_{0}-{1}", Traffic.ShortName(competingParams[i].type), numNodes[i]);
            }

            return s.ToString();
        }

        private void AddSimulator(List<int> numNodes)
        {
            Simulator sim = new Simulator(network, SimulatorName(numNodes));
            Debug.Assert(mainParams != null);

            AddNode(sim, mainParams, "main", 1);

            for (int i = 0; i < competingParams.Count; ++i )
            {
                AddNode(sim, competingParams[i], "node", numNodes[i]);
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

        /// <summary>
        /// We have a single main node
        /// Competing nodes go from min-max, and we get every cartesian product of possible combinations
        /// </summary>
        private void GenerateCartesianSimulators()
        {
            // Limits
            List<int> min = new List<int>();
            List<int> max = new List<int>();
            List<int> cur = new List<int>();
            int length = competingParams.Count;
            for (int i = 0; i < length; ++i)
            {
                min.Add(competingParams[i].minNodes);
                max.Add(competingParams[i].maxNodes);
                cur.Add(competingParams[i].minNodes);
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
                while (cur[cartesianIndex] > max[cartesianIndex])
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

        
        private void GenerateSinglesSimulators()
        {
            int length = competingParams.Count;

            // Iterate over all the types and allow each one of them to be the main one
            for (int mainIndex = 0; mainIndex < length; ++mainIndex)
            {
                mainParams = competingParams[mainIndex];

                List<int> cur = new List<int>();
                for (int competingIndex = 0; competingIndex < length; ++competingIndex)
                {
                    if (mainIndex == competingIndex)
                    {
                        // See how many more copies of the main node we're adding
                        // Subtract one because we already have one as the 'main'
                        cur.Add(competingParams[mainIndex].maxNodes - 1);
                    }
                    else
                    {
                        // Other nodes get their min value of nodes
                        cur.Add(competingParams[competingIndex].minNodes);
                    }
                }

                AddSimulator(cur);
            }

            mainParams = null;
        }

        private void GenerateIncrementalSimulators()
        {
            // Limits
            List<int> min = new List<int>();
            List<int> max = new List<int>();
            List<int> cur = new List<int>();
            int length = competingParams.Count;
            for (int i = 0; i < length; ++i)
            {
                min.Add(competingParams[i].minNodes);
                max.Add(competingParams[i].maxNodes);
                cur.Add(0);
            }

            // Iterate over all the types, allow each one be the competing type
            for (int competingIndex = 0; competingIndex < length; ++competingIndex)
            {
                // Reset all other nodes to have 0
                for (int i=0; i<length; ++i)
                {
                    cur[i] = 0;
                }

                // Iterate over all possible values of the current type
                for (int numCompeting = min[competingIndex]; numCompeting < max[competingIndex]; ++numCompeting)
                {
                    cur[competingIndex] = numCompeting;
                    AddSimulator(cur);
                }
            }
        }

        private void GenerateSimulators()
        {
            int length = competingParams.Count;
            if (cartesian && length > 0)
            {
                Debug.Assert(mainParams != null);
                GenerateCartesianSimulators();
            }
            else
            {
                if (mainParams == null)
                {
                    GenerateSinglesSimulators();
                }
                else
                {
                    GenerateIncrementalSimulators();
                }
            }
        }

        public void RunSims(bool verbose, bool keepTrace, int repititions, int steps)
        {
            GenerateSimulators();

            foreach (Simulator referenceSim in simulators)
            {
                if (verbose)
                {
                    Console.Write("Running: {0}", referenceSim.name);
                }

                List<SimulationResults> variationResults = new List<SimulationResults>();
                for (int run=0; run<repititions; ++run)
                {
                    if (verbose && run%25 == 0)
                    {
                        Console.Write('.');
                    }

                    Simulator runSim = new Simulator(referenceSim, run);
                    runSim.Steps(steps, keepTrace);
                    variationResults.Add(runSim.GetResults());
                }

                if (verbose)
                {
                    Console.WriteLine();
                }

                results.Add(variationResults);
            }
        }

        public void SaveTracesCSV(string folder)
        {
            foreach(List<SimulationResults> variationResults in results)
            {
                foreach(SimulationResults runResult in variationResults)
                {
                    SimulationNodeResults mainResult = runResult.GetResults(0);

                    string filename = String.Format("{0}{1}.csv", folder, mainResult.name);
                    StreamWriter writer = new StreamWriter(filename);

                    mainResult.trace.WritePacketTraceCSV(writer);
                }
            }
        }

        public void SaveOverviewCSV(string folder)
        {
            // TODO: Write me
        }
    }
}
