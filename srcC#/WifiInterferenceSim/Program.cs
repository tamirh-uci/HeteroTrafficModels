using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;
using WifiInterferenceSim.Simulation;

namespace WifiInterferenceSim
{
    class Program
    {
        // Precalculated numbers
        static int STEPS_PER_SECOND = 645;
        static Int64 MAX_NODE_BPS = 1744600; // Measured max single node datarate (based on wMin=8, payload=1500bytes)
        static double MAX_NODE_MBPS = MAX_NODE_BPS / 1000000;

        // -----------------------------
        // User variables
        // -----------------------------

        // negative: random seeds, positive: fixed seeds for testing
        static int RANDOM_SEED = -1;

        // How many seconds are we simulating
        static int SIMULATION_SECONDS = 32;

        // The type of the main node
        static TrafficType MAIN_NODE_TYPE = TrafficType.SkypeVideo;

        // Main node arrival rate
        static double MAIN_ARRIVAL_MBPS = 0.5;

        // Quality threshold for the main node
        static double MAIN_THRESHOLD = 0.1;

        // Bytes per packet
        static Int64 PAYLOAD_BITS = 1500 * 8;

        // How many times to repeat each variation of simulation
        static int NUM_RUNS = 500;

        // How many seconds for a packet to be 'too late'
        static double THRESHOLD_SKYPE_VIDEO = 0.10;
        static double THRESHOLD_YOUTUBE = 2.00;
        static double THRESHOLD_BITTORRENT = 2.00;
        static double THRESHOLD_WEBBROWSING = 0.50;
        static double THRESHOLD_CONSTANT = 0.25;

        // multipliers for the global arrival rate
        static double MULT_SKYPE_VIDEO = 1.0;
        static double MULT_YOUTUBE = 1.0;
        static double MULT_BITTORRENT = 1.0;
        static double MULT_WEBBROWSING = 1.0;
        static double MULT_CONSTANT = 1.0;
        
        // How many of each type of competing node
        static int MIN_SKYPE_VIDEO = 0;
        static int MAX_SKYPE_VIDEO = 3;
        static int MIN_YOUTUBE = 0;
        static int MAX_YOUTUBE = 3;
        static int MIN_BITTORRENT = 0;
        static int MAX_BITTORRENT = 3;
        static int MIN_WEBBROWSING = 0;
        static int MAX_WEBBROWSING = 3;
        static int MIN_CONSTANT = 0;
        static int MAX_CONSTANT = 3;

        // Do we have a cartesian product of competing nodes? Or just a single sim
        static bool RUN_CARTESIAN = false;

        // Do we have a run where we iterate through and run one of each?
        static bool RUN_SINGLES = true;

        // Do we have a run where we run the main node against one type of the other nodes
        static bool RUN_INCREMENTAL = false;

        // Spit out stuff to console so we know we're not dead during long calculations
        static bool VERBOSE = true;

        // Storage for final file
        static string CSV_BASE_CARTESIAN = "./../../../../results/csvCartesian/";
        static string CSV_BASE_SINGLES = "./../../../../results/csvSingles/";
        static string CSV_BASE_INCREMENTAL = "./../../../../results/csvIncremental/";
        
        static void Main(string[] args)
        {
            Physical80211 network = new Physical80211(NetworkType.B, PAYLOAD_BITS);
            int steps = STEPS_PER_SECOND * SIMULATION_SECONDS;

            // TODO: Writing to CSV

            // Run each type of node completely by itself
            if (RUN_SINGLES)
            {
                RunSimSet("Singleton Traces", CSV_BASE_SINGLES, network, true, steps, 1, false, false, true);
            }

            // Run one type of main node against different numbers of a single type of competing node
            if (RUN_INCREMENTAL)
            {
                RunSimSet("Incremental Simulations", CSV_BASE_INCREMENTAL, network, false, steps, NUM_RUNS, false, true, false);
            }

            // Run one type of main node against every combination of competing nodes
            if (RUN_CARTESIAN)
            {
                RunSimSet("Cartesian Simulations", CSV_BASE_CARTESIAN, network, false, steps, NUM_RUNS, true, true, false);
            }
            
            Console.WriteLine("\nDone\n");
        }

        static void RunSimSet(string name, string csvBase, Physical80211 network, bool keepTrace, int steps, int repitions, bool isCartesian, bool useMain, bool isSingles)
        {
            // make sure directory exists for csv files
            System.IO.Directory.CreateDirectory(csvBase);

            if (VERBOSE)
            {
                Console.WriteLine("---------------------");
                Console.WriteLine(name);
                Console.WriteLine("---------------------");
                Console.WriteLine("Generating...");
            }

            SimRunner simRunner = new SimRunner(network, isCartesian);

            if (useMain)
            {
                simRunner.SetMain(MakeSimParams(MAIN_NODE_TYPE, isSingles, true));
            }

            foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
            {
                if (type != TrafficType.Custom)
                {
                    simRunner.AddCompeting(MakeSimParams(type, isSingles, false));
                }
            }

            if (VERBOSE)
            {
                Console.WriteLine("Running...");
            }
            simRunner.RunSims(VERBOSE, keepTrace, repitions, steps);


            if (VERBOSE)
            {
                Console.WriteLine("Saving CSV...");
            }
            if (isSingles)
            {
                simRunner.SaveTracesCSV(csvBase);
            }
            else
            {
                simRunner.SaveOverviewCSV(csvBase);
            }


            if (VERBOSE)
            {
                Console.WriteLine();
            }
        }

        static SimParams MakeSimParams(TrafficType type, bool isSinglesSim, bool isMain)
        {
            int minNodes, maxNodes;
            double arrivalBps, qualityThreshold;
            double baseBps = MAIN_ARRIVAL_MBPS * 1000000;

            switch (type)
            {
                case TrafficType.SkypeVideo:
                    minNodes = MIN_SKYPE_VIDEO;
                    maxNodes = MAX_SKYPE_VIDEO;
                    qualityThreshold = THRESHOLD_SKYPE_VIDEO;
                    arrivalBps = baseBps * MULT_SKYPE_VIDEO;
                    break;

                case TrafficType.YouTube:
                    minNodes = MIN_YOUTUBE;
                    maxNodes = MAX_YOUTUBE;
                    qualityThreshold = THRESHOLD_YOUTUBE;
                    arrivalBps = baseBps * MULT_YOUTUBE;
                    break;

                case TrafficType.BitTorrent:
                    minNodes = MIN_BITTORRENT;
                    maxNodes = MAX_BITTORRENT;
                    qualityThreshold = THRESHOLD_BITTORRENT;
                    arrivalBps = baseBps * MULT_BITTORRENT;
                    break;

                case TrafficType.WebBrowsing:
                    minNodes = MIN_WEBBROWSING;
                    maxNodes = MAX_WEBBROWSING;
                    qualityThreshold = THRESHOLD_WEBBROWSING;
                    arrivalBps = baseBps * MULT_WEBBROWSING;
                    break;

                case TrafficType.ConstantStream:
                    minNodes = MIN_CONSTANT;
                    maxNodes = MAX_CONSTANT;
                    qualityThreshold = THRESHOLD_CONSTANT;
                    arrivalBps = baseBps * MULT_CONSTANT;
                    break;

                case TrafficType.Custom:
                default:
                    throw new NotSupportedException();
            }

            if (isMain)
            {
                minNodes = 1;
                maxNodes = 1;
                arrivalBps = baseBps;
                qualityThreshold = MAIN_THRESHOLD;
            }

            if (isSinglesSim)
            {
                Debug.Assert(!isMain);
                minNodes = 0;
                maxNodes = 1;
            }

            return new SimParams(type, minNodes, maxNodes, arrivalBps, qualityThreshold, RANDOM_SEED);
        }


        /*
        static void DoMultirunCartesian(Physical80211 network, int minCal, int maxCal, DCFParams cfgCal, int minVid, int maxVid, DCFParams cfgVid, int minDat, int maxDat, DCFParams cfgDat, int minWeb, int maxWeb, DCFParams cfgWeb, int minFul, int maxFul, DCFParams cfgFul)
        {
            List<string> variations = new List<string>();
            List<List<Int64>> packetsOverThreshold = new List<List<Int64>>();
            List<List<double>> throughput = new List<List<double>>();

            for (int iVidStreamNodes = MIN_VIDEO_STREAM_NODES; iVidStreamNodes <= MAX_VIDEO_STREAM_NODES; ++iVidStreamNodes)
            {
                for (int iFileNodes = MIN_FILE_NODES; iFileNodes <= MAX_FILE_NODES; ++iFileNodes)
                {
                    for (int iWebNodes = MIN_WEB_NODES; iWebNodes <= MAX_WEB_NODES; ++iWebNodes)
                    {
                        for (int iFullDataNodes = MIN_FULL_DATA_NODES; iFullDataNodes <= MAX_FULL_DATA_NODES; ++iFullDataNodes)
                        {
                            List<Int64> variationResultsPacketsOverThreshold = new List<Int64>(NUM_RUNS);
                            List<double> variationResultsThroughput = new List<double>(NUM_RUNS);

                            string variationName = String.Format("v{0}_f{1}_w{2}_d{3}", iVidStreamNodes, iFileNodes, iWebNodes, iFullDataNodes);
                            variations.Add(variationName);

                            Console.Write("Running variation: {0}", variationName);
                            for (int iteration = 0; iteration < NUM_RUNS; ++iteration)
                            {
                                if (iteration % 10 == 0)
                                {
                                    Console.Write('.');
                                }

                                Simulator sim = MakeMultiNodeSim(network, 1, cfgCal, iVidStreamNodes, cfgVid, iFileNodes, cfgDat, iWebNodes, cfgWeb, iFullDataNodes, cfgFul);
                                sim.Steps(STEPS, QUALITY_THRESHOLD);

                                SimulationResults results = sim.GetResults(0);

                                variationResultsPacketsOverThreshold.Add(results.packetsOverThreshold);
                                variationResultsThroughput.Add(results.datarate);
                            }

                            Console.WriteLine();
                            packetsOverThreshold.Add(variationResultsPacketsOverThreshold);
                            throughput.Add(variationResultsThroughput);
                        }
                    }
                }
            }

            Console.WriteLine("\nWriting out results to CSV...");

            string csvName = variations[variations.Count - 1];
            StreamWriter fullData = new StreamWriter(CSVFileBase(String.Format("{0}-cartesian-full.csv", csvName)));
            StreamWriter avgData = new StreamWriter(CSVFileBase(String.Format("{0}-cartesian-avg.csv", csvName)));

            
            int numVariations = packetsOverThreshold.Count;
            for (int variationIndex = 0; variationIndex < numVariations; ++variationIndex)
            {
                Int64 totalPacketsOverThreshold = 0;
                double totalThroughput = 0;

                List<Int64> varResPacketsOverThreshold = packetsOverThreshold[variationIndex];
                List<double> varResThroughput = throughput[variationIndex];

                int numRuns = varResThroughput.Count;
                for (int runIndex = 0; runIndex < numRuns; ++runIndex)
                {
                    Int64 resPacketsOverThreshold = varResPacketsOverThreshold[runIndex];
                    double resThroughput = varResThroughput[runIndex];

                    totalPacketsOverThreshold += resPacketsOverThreshold;
                    totalThroughput += resThroughput;

                    fullData.WriteLine("{0},{1},{2},{3}", variationIndex, runIndex, resPacketsOverThreshold, resThroughput);
                }

                double avgPacketsOverThreshold = (double)totalPacketsOverThreshold / numRuns;
                double avgThreshold = totalThroughput / numRuns;

                avgData.WriteLine("{0},{1},{2}", variationIndex, avgPacketsOverThreshold, avgThreshold);

                fullData.Flush();
                avgData.Flush();
            }

            fullData.Close();
            avgData.Close();
        }*/
    }
}
