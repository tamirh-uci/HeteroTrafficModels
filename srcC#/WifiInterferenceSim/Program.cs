using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim
{
    class Program
    {
        static int STEPS = 20000; // 32 seconds
        //static int STEPS = 645; // 1 second

        static double ARRIVAL_MBPS = 0.5;
        static Int64 PAYLOAD_BITS = 1500 * 8;
        static double QUALITY_THRESHOLD = 0.10; // 100 milliseconds
        static int RANDOM_SEED = -1;

        static int NUM_RUNS = 500;

        static double VID_STREAM_ARRIVAL_MULT = 1.0;
        static double VID_CALL_ARRIVAL_MULT = 1.0;
        static double FILE_ARRIVAL_MULT = 1.0;
        static double WEB_ARRIVAL_MULT = 1.0;
        static double FULL_DATA_ARRIVAL_MULT = 1.0;

        static int MIN_VIDEO_STREAM_NODES = 0;
        static int MAX_VIDEO_STREAM_NODES = 0;
        static int MIN_FILE_NODES = 0;
        static int MAX_FILE_NODES = 0;
        static int MIN_WEB_NODES = 0;
        static int MAX_WEB_NODES = 0;
        static int MIN_FULL_DATA_NODES = 0;
        static int MAX_FULL_DATA_NODES = 9;

        // Measured max single node datarate
        static Int64 MAX_NODE_BPS = 1744600;
        static double MAX_NODE_MBPS = MAX_NODE_BPS / 1000000;

        static string CSV_BASE = "./../../../../results/newsim_";

        static void Main(string[] args)
        {
            double arrivalBps = 1000000 * ARRIVAL_MBPS;
            Physical80211 network = new Physical80211(NetworkType.B, PAYLOAD_BITS);
            DCFParams cfgCal = Traffic.VideoCall(network, arrivalBps);
            DCFParams cfgVid = Traffic.VideoStream(network, arrivalBps);
            DCFParams cfgDat = Traffic.File(network, arrivalBps);
            DCFParams cfgWeb = Traffic.Web(network, arrivalBps);
            DCFParams cfgFul = Traffic.Full(network, arrivalBps);

            
            //DoSinglerunExample(network, cfgCal, cfgVid, cfgDat, cfgWeb, cfgFul);
            DoMultirunCartesian(network, cfgCal, cfgVid, cfgDat, cfgWeb, cfgFul);
            //DoMultirunIncrement(network, cfgCal, cfgVid, cfgDat, cfgWeb, cfgFul);

            Console.WriteLine("\nDone\n");
        }

        static string CSVFileBase(string index)
        {
            return String.Format("{0}{1}", CSV_BASE, index);
        }

        static int RandSeed()
        {
            if (RANDOM_SEED > 0)
            {
                return RANDOM_SEED++;
            }
            else
            {
                return RANDOM_SEED;
            }
        }

        static void DoSinglerunExample(Physical80211 network, DCFParams cfgCal, DCFParams cfgVid, DCFParams cfgDat, DCFParams cfgWeb, DCFParams cfgFul)
        {
            SingleNodeTests(network, 1, cfgCal, 1, cfgVid, 1, cfgDat, 1, cfgWeb, 1, cfgFul);

            Simulator sim = MakeMultiNodeSim(network, 0, cfgCal, 0, cfgVid, 0, cfgDat, 0, cfgWeb, 1, cfgFul);
            sim.Steps(STEPS, QUALITY_THRESHOLD);
            sim.PrintResults();
        }

        static void DoMultirunCartesian(Physical80211 network, DCFParams cfgCal, DCFParams cfgVid, DCFParams cfgDat, DCFParams cfgWeb, DCFParams cfgFul)
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
        }

        static Simulator MakeMultiNodeSim(Physical80211 network, int nCal, DCFParams cfgCal, int nVid, DCFParams cfgVid, int nDat, DCFParams cfgDat, int nWeb, DCFParams cfgWeb, int nFul, DCFParams cfgFul)
        {
            Simulator sim = new Simulator(network);

            for (int i = 0; i < nCal; ++i)
            {
                sim.AddNode(new DCFNode(String.Format("call {0}", i), cfgCal, RandSeed()));
            }

            for (int i = 0; i < nVid; ++i)
            {
                sim.AddNode(new DCFNode(String.Format("video {0}", i), cfgVid, RandSeed()));
            }

            for (int i=0; i<nDat; ++i)
            {
                sim.AddNode(new DCFNode(String.Format("files {0}", i), cfgDat, RandSeed()));
            }

            for (int i=0; i<nWeb; ++i)
            {
                sim.AddNode(new DCFNode(String.Format("web {0}", i), cfgWeb, RandSeed()));
            }

            for (int i=0; i<nFul; ++i)
            {
                sim.AddNode(new DCFNode(String.Format("full {0}", i), cfgFul, RandSeed()));
            }

            return sim;
        }

        static void SingleNodeTests(Physical80211 network, int nCal, DCFParams cfgCal, int nVid, DCFParams cfgVid, int nDat, DCFParams cfgDat, int nWeb, DCFParams cfgWeb, int nFul, DCFParams cfgFul)
        {
            for (int i = 0; i < nCal; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("call", cfgCal, RandSeed()));

                sim.Steps(STEPS, QUALITY_THRESHOLD);
                sim.WriteCSVResults(CSVFileBase(String.Format("{0}", i)));
            }

            for (int i = 0; i < nVid; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("video", cfgVid, RandSeed()));

                sim.Steps(STEPS, QUALITY_THRESHOLD);
                sim.WriteCSVResults(CSVFileBase(String.Format("{0}", i)));
            }

            for (int i=0; i<nDat; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("files", cfgDat, RandSeed()));

                sim.Steps(STEPS, QUALITY_THRESHOLD);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }

            for (int i=0; i<nWeb; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("web", cfgWeb, RandSeed()));

                sim.Steps(STEPS, QUALITY_THRESHOLD);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }

            for (int i=0; i<nFul; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("full", cfgFul, RandSeed()));

                sim.Steps(STEPS, QUALITY_THRESHOLD);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }
        }
    }
}
