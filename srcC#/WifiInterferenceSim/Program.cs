﻿using System;
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
        static Int64 MAX_NODE_BPS = 1744600; // Measured max single node datarate (based on wMin=8, payload=1500bytes)
        static double MAX_NODE_MBPS = MAX_NODE_BPS / 1000000;


        // -----------------------------
        // User variables
        // -----------------------------

        // negative: random seeds, positive: fixed seeds for testing
        static int RANDOM_SEED = -1;

        static NetworkType NETWORK_TYPE = NetworkType.G_short;

        // How many seconds are we simulating
        static int SIMULATION_SECONDS = 32;

        // The type of the main node
        static TrafficType MAIN_NODE_TYPE = TrafficType.Web_Videocall;

        // Main node arrival rate
        static double MAIN_ARRIVAL_MBPS = 0.5;

        // Quality threshold for the main node
        static double MAIN_THRESHOLD = 0.025;

        // Max number of nodes to compare against (for incremental version)
        static int MAX_NODES = 9;
        static int CUSTOM_NODE_NUM = 10;

        // How many times to repeat each variation of simulation
        static int NUM_RUNS_SINGLES = 16;
        static int NUM_RUNS_INCREMENTAL = 25;
        static int NUM_RUNS_CUSTOM = 1;

        static int BYTES_PER_PAYLOAD = 100;
        static int BITS_PER_PAYLOAD = 8 * BYTES_PER_PAYLOAD;
        static int[] PAYLOAD_BINS = { 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500 };

        // Do we have a cartesian product of competing nodes? Or just a single sim
        static bool RUN_CARTESIAN = false;

        // Do we have a run where we iterate through and run one of each?
        static bool RUN_SINGLES = false;

        // Do we have a run where we run the main node against one type of the other nodes
        static bool RUN_INCREMENTAL = false;

        // Do we have a run where we have a custom combination of stuff
        static bool RUN_CUSTOM = true;

        // Spit out stuff to console so we know we're not dead during long calculations
        static bool VERBOSE = true;
        
        static TrafficAnalyzer WEB_VIDEOCALL = new TrafficAnalyzer(
            0, MAX_NODES,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            0.1,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer WEB_MULTIPLENEWTABS = new TrafficAnalyzer(
            0, MAX_NODES,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            1.0,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer WEB_FTPDOWNLOAD = new TrafficAnalyzer(
            0, MAX_NODES,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            4.0,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer YOUTUBE_AUDIOVIDEO = new TrafficAnalyzer(
            0, MAX_NODES,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            1.5,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer SKYPE_AUDIO = new TrafficAnalyzer(
            0, 0,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            0.1,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer SKYPE_VIDEO = new TrafficAnalyzer(
            0, 0,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            0.1,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer SKYPE_AUDIOVIDEO = new TrafficAnalyzer(
            0, 0,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            0.1,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer BITTORRENT_LEECHING = new TrafficAnalyzer(
            0, MAX_NODES,   // min/max nodes to simulate
            1.0,    // multiplier against the main arrival rate
            4.0,     // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        static TrafficAnalyzer BACKGROUND = new TrafficAnalyzer(
            0, 0,   // min/max nodes to simulate
            1.0, // multiplier against main arrival rate
            1.0, // threshold in seconds to consider packet late
            BYTES_PER_PAYLOAD, PAYLOAD_BINS
            );

        // Storage for final files
        static string CSV_BASE_SOURCE = "./../../../../traces/";
        static string CSV_BASE_CARTESIAN = "./../../../../results/csvCartesian/";
        static string CSV_BASE_SINGLES = "./../../../../traces/";
        static string CSV_BASE_INCREMENTAL = "./../../../../results/";
        static string CSV_BASE_FLAT = "./../../../../traces/";

        static string CSV_PREFIX_SOURCE = "wireshark_";
        static string CSV_PREFIX_CARTESIAN = "v2sim_cartesian_";
        static string CSV_PREFIX_SINGLES = "v2sim_";
        static string CSV_PREFIX_INCREMENTAL = "v2sim_inc_";
        static string CSV_PREFIX_FLAT = "v2sim_flat";
            
        static void Main(string[] args)
        {
            // Trace analysis to get parameter values
            RunTraceAnalysis();

            Physical80211 network = new Physical80211(NETWORK_TYPE, BYTES_PER_PAYLOAD*8);
            int steps = (int)Math.Ceiling(network.StepsPerSecond() * SIMULATION_SECONDS);

            // Run each type of node completely by itself
            if (RUN_SINGLES)
            {
                RunSimSet("Singleton Traces", CSV_BASE_SINGLES, CSV_PREFIX_SINGLES, network, true, steps, NUM_RUNS_SINGLES, false, false, true, -1, -1, -1);
            }

            // Run one type of main node against different numbers of a single type of competing node
            if (RUN_INCREMENTAL)
            {
                RunSimSet("Incremental Simulations", CSV_BASE_INCREMENTAL, CSV_PREFIX_INCREMENTAL, network, false, steps, NUM_RUNS_INCREMENTAL, false, true, false, -1, -1, -1);
            }

            // Run one type of main node against every combination of competing nodes
            if (RUN_CARTESIAN)
            {
                // Haven't really tested this, so make sure we don't think it's all good to go
                throw new NotSupportedException();
                //RunSimSet("Cartesian Simulations", CSV_BASE_CARTESIAN, CSV_PREFIX_CARTESIAN, network, false, steps, NUM_RUNS_INCREMENTAL, true, true, false, -1, -1, -1);
            }

            if (RUN_CUSTOM)
            {
                for (int i = CUSTOM_NODE_NUM; i <= CUSTOM_NODE_NUM; ++i)
                {
                    int trafficIndex = 0;
                    string prefix = String.Format("{0}{1}_", CSV_PREFIX_FLAT, i);
                    foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
                    {
                        RunSimSet("Custom Simulations", CSV_BASE_FLAT, prefix, network, true, steps, NUM_RUNS_CUSTOM, false, true, false, i, i, trafficIndex);
                        ++trafficIndex;
                    }
                }
            }
            
            Console.WriteLine("\nDone\n");
        }

        static void RunTraceAnalysis()
        {
            foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
            {
                string sourceTrace = String.Format("{0}{1}{2}.csv", CSV_BASE_SOURCE, CSV_PREFIX_SOURCE, TrafficUtil.Name(type));
                TrafficAnalyzer nodeParams = GetTrafficNodeParams(type);

                nodeParams.AnalyzeTrace(sourceTrace);
            }
        }

        static Dictionary<TrafficType, TrafficAnalyzer> TrafficParamList()
        {
            Dictionary<TrafficType, TrafficAnalyzer> list = new Dictionary<TrafficType, TrafficAnalyzer>();
            foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
            {
                list[type] = GetTrafficNodeParams(type);
            }

            return list;
        }

        static void RunSimSet(string name, string csvBase, string csvPrefix, Physical80211 network, bool keepTrace, int steps, int repitions, bool isCartesian, bool useMain, bool isSingles, int forceMin, int forceMax, int trafficIndex)
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

            SimRunner simRunner = new SimRunner(network, TrafficParamList(), isCartesian);

            if (useMain)
            {
                simRunner.SetMain(MakeSimParams(MAIN_NODE_TYPE, isSingles, true));
            }

            int currentTrafficIndex = 0;
            foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
            {
                if (trafficIndex >= 0 && currentTrafficIndex != trafficIndex)
                {
                    currentTrafficIndex++;
                    continue;
                }

                SimParams simParams = MakeSimParams(type, isSingles, false);
                if (simParams.maxNodes > 0)
                {
                    if (forceMin > 0)
                    {
                        simParams.minNodes = forceMin;
                    }

                    if (forceMax > 0)
                    {
                        simParams.maxNodes = forceMax;
                    }

                    simRunner.AddCompeting(simParams);
                }

                currentTrafficIndex++;
            }

            simRunner.RunSims(VERBOSE, keepTrace, repitions, steps);


            if (VERBOSE)
            {
                Console.WriteLine("Saving CSV...");
            }
            if (isSingles || forceMin > 0 || forceMax > 0)
            {
                simRunner.SaveTracesCSV(csvBase, csvPrefix, isSingles);
            }
            else
            {
                simRunner.SaveIncrementalOverviewCSV(csvBase, csvPrefix);
            }

            if (VERBOSE)
            {
                Console.WriteLine();
            }
        }

        static TrafficAnalyzer GetTrafficNodeParams(TrafficType type)
        {
            switch(type)
            {
                case TrafficType.Web_Videocall: return WEB_VIDEOCALL;
                case TrafficType.Web_MultipleNewTabs: return WEB_MULTIPLENEWTABS;
                case TrafficType.Web_FTPDownload: return WEB_FTPDOWNLOAD;
                case TrafficType.YouTube_AudioVideo: return YOUTUBE_AUDIOVIDEO;
                case TrafficType.Skype_Audio: return SKYPE_AUDIO;
                case TrafficType.Skype_Video: return SKYPE_VIDEO;
                case TrafficType.Skype_AudioVideo: return SKYPE_AUDIOVIDEO;
                case TrafficType.Bittorrent_Leeching: return BITTORRENT_LEECHING;
                case TrafficType.Background: return BACKGROUND;

                default:
                    throw new NotSupportedException();
            }
        }

        static SimParams MakeSimParams(TrafficType type, bool isSinglesSim, bool isMain)
        {
            TrafficAnalyzer p = GetTrafficNodeParams(type);
            double baseBps = MAIN_ARRIVAL_MBPS * 1000000;

            int minNodes = p.min;
            int maxNodes = p.max;
            double arrivalBps = baseBps * p.multiplier;
            double qualityThreshold = p.threshold;

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
    }
}
