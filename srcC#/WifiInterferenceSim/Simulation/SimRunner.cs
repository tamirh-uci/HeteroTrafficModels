using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
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
        SimResults results;

        public SimRunner(Physical80211 _network, bool _cartesian)
        {
            network = _network;
            cartesian = _cartesian;

            mainParams = null;
            simulators = new List<Simulator>();
            competingParams = new List<SimParams>();
            results = new SimResults();
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
            s.AppendFormat("main-{0}_", TrafficUtil.ShortName(mainParams.type));

            for (int i=0; i<competingParams.Count; ++i)
            {
                s.AppendFormat("_{0}-{1}", TrafficUtil.ShortName(competingParams[i].type), numNodes[i]);
            }

            return s.ToString();
        }

        private void AddSimulator(List<int> numNodes, string groupName, int simIndex)
        {
            Simulator sim = new Simulator(network, SimulatorName(numNodes), groupName == null ? SimulatorName(numNodes) : groupName, simIndex);
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
                string name = String.Format("{0}{1}-{2}", namePrefix, TrafficUtil.Name(simParams.type), i);
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
            int simIndex = 0;
            while (cur[0] <= max[0])
            {
                // Add a simulation with the current set of params
                AddSimulator(cur, null, simIndex++);

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

                AddSimulator(cur, TrafficUtil.Name(mainParams.type), 1);
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

                // group name is the competing type we're iterating over
                string groupName = TrafficUtil.Name(competingParams[competingIndex].type);

                // Iterate over all possible values of the current type
                for (int numCompeting = min[competingIndex]; numCompeting < max[competingIndex]; ++numCompeting)
                {
                    cur[competingIndex] = numCompeting;
                    AddSimulator(cur, groupName, numCompeting);
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
                    Console.Write("Running: {0} ({1})", referenceSim.SimName, referenceSim.GroupName);
                }

                for (int run=0; run<repititions; ++run)
                {
                    if (verbose && run%25 == 0)
                    {
                        Console.Write('.');
                    }

                    Simulator runSim = new Simulator(referenceSim, run);
                    runSim.Steps(steps, keepTrace);
                    results.Add(runSim.GetResults());
                }

                if (verbose)
                {
                    Console.WriteLine();
                }
            }
        }

        public void SaveTracesCSV(string folder, string prefix)
        {
            // Results grouped by the main node type
            Dictionary<string, List<SimRunResult>> groupNameResults = results.GroupNameResults;

            // For every variation type
            foreach (string groupName in groupNameResults.Keys)
            {
                List<SimRunResult> multirunResults = groupNameResults[groupName];

                // We only care about the main run
                SimRunResult runResult = multirunResults[0];
                SimNodeResult mainResult = runResult.Get(0);
                
                string filename;
                if (multirunResults.Count == 1)
                {
                    // Don't need the full name, since there's only 1 run anywawy
                    filename = groupName;
                }
                else
                {
                    // Otherwise we use the result name which will include run #
                    filename = mainResult.name;
                }

                // Dump out entire trace
                StreamWriter writer = new StreamWriter(String.Format("{0}{1}{2}.csv", folder, prefix, filename));
                mainResult.trace.WritePacketTraceCSV(writer);
            }
        }

        public void SaveIncrementalOverviewCSV(string folder, string prefix)
        {
            // Find out how many simulations we have in each variation
            Dictionary<string, int> numSimVariations = new Dictionary<string, int>();
            foreach (string groupName in results.GroupNameResults.Keys)
            {
                numSimVariations[groupName] = 0;
            }

            foreach (string simName in results.UnindexedNameResults.Keys)
            {
                foreach (SimRunResult runResult in results.UnindexedNameResults[simName])
                {
                    numSimVariations[runResult.GroupName] = Math.Max(numSimVariations[runResult.GroupName], 1 + runResult.SimIndex);
                }
            }


            // We want our results grouped by groupName, and indexable by number of nodes
            Dictionary<string, List<SimResultAggregate>> aggregateResults = new Dictionary<string, List<SimResultAggregate>>();
            foreach (string groupName in results.GroupNameResults.Keys)
            {
                aggregateResults[groupName] = new List<SimResultAggregate>();
                for (int i = 0; i < numSimVariations[groupName]; ++i)
                {
                    aggregateResults[groupName].Add(null);
                }
            }

            Dictionary<string, List<SimRunResult>> groupedResults = results.UnindexedNameResults;

            // For every set of runs aggregate runs and put them in the correct index
            foreach (string simName in groupedResults.Keys)
            {
                List<SimRunResult> resultSet = groupedResults[simName];
                SimResultAggregate aggregate = new SimResultAggregate(resultSet);
                SimRunResult runResult = resultSet[0];
                
                string groupName = runResult.GroupName;
                int simIndex = runResult.SimIndex;

                aggregateResults[groupName][simIndex] = aggregate;
            }

            string filename = String.Format("{0}{1}-main-{2}.csv", folder, prefix, TrafficUtil.Name(mainParams.type));
            StreamWriter w = new StreamWriter(filename);

            // Header line
            w.Write("{0},{1},", "CompetingType", "NumNodes");
            SimResultAggregate.HeaderToCSV(w);
            w.WriteLine();

            // Go through each group and the list of simulations and dump to CSV
            foreach (string groupName in aggregateResults.Keys)
            {
                List<SimResultAggregate> simResults = aggregateResults[groupName];
                for (int i = 0; i < simResults.Count; ++i )
                {
                    w.Write("{0},{1},", groupName, i);
                    simResults[i].ToCSV(w);
                    w.WriteLine();
                }

                w.Flush();
            }

            w.Flush();
            w.Close();
        }
    }
}
