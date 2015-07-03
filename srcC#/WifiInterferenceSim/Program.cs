using System;
using System.Collections.Generic;
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
        static int RANDOM_SEED = 1;

        // Measured max single node datarate
        static Int64 MAX_NODE_BPS = 1744600;
        static double MAX_NODE_MBPS = MAX_NODE_BPS / 1000000;

        static string CSV_BASE = "./../../../../results/newsim_";

        static void Main(string[] args)
        {
            Physical80211 network = new Physical80211(NetworkType.B, PAYLOAD_BITS);

            double arrivalBps = 1000000 * ARRIVAL_MBPS;
            DCFParams vidCfg = Traffic.Video(network, arrivalBps);
            DCFParams datCfg = Traffic.File(network, arrivalBps);
            DCFParams webCfg = Traffic.Web(network, arrivalBps);
            DCFParams fulCfg = Traffic.Full(network, arrivalBps);

            SingleNodeTests(network, 1, vidCfg, 1, datCfg, 1, webCfg, 1, fulCfg);

            //Simulator sim = MultiNodeTests(network, 1, vidCfg, 0, datCfg, 1, webCfg, 0, fulCfg);
            //sim.PrintResults(QUALITY_THRESHOLD);
            
            Console.WriteLine("\n");
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

        static Simulator MultiNodeTests(Physical80211 network, int nVid, DCFParams cfgVid, int nDat, DCFParams cfgDat, int nWeb, DCFParams cfgWeb, int nFul, DCFParams cfgFul)
        {
            Simulator sim = new Simulator(network);


            for (int i=0; i<nVid; ++i)
            {
                sim.AddNode(new DCFNode("video", cfgVid, RandSeed()));
            }

            for (int i=0; i<nDat; ++i)
            {
                sim.AddNode(new DCFNode("files", cfgDat, RandSeed()));
            }

            for (int i=0; i<nWeb; ++i)
            {
                sim.AddNode(new DCFNode("web", cfgWeb, RandSeed()));
            }

            for (int i=0; i<nFul; ++i)
            {
                sim.AddNode(new DCFNode("full", cfgFul, RandSeed()));
            }

            sim.Steps(STEPS);
            sim.WriteCSVResults(CSVFileBase( String.Format("v{0}_d{1}_w{2}_f{3}", nVid, nDat, nWeb, nFul) ));

            return sim;
        }

        static void SingleNodeTests(Physical80211 network, int nVid, DCFParams cfgVid, int nDat, DCFParams cfgDat, int nWeb, DCFParams cfgWeb, int nFul, DCFParams cfgFul)
        {
            for (int i=0; i<nVid; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("video", cfgVid, RandSeed()));

                sim.Steps(STEPS);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }

            for (int i=0; i<nDat; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("files", cfgDat, RandSeed()));

                sim.Steps(STEPS);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }

            for (int i=0; i<nWeb; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("web", cfgWeb, RandSeed()));

                sim.Steps(STEPS);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }

            for (int i=0; i<nFul; ++i)
            {
                Simulator sim = new Simulator(network);

                sim.AddNode(new DCFNode("full", cfgFul, RandSeed()));

                sim.Steps(STEPS);
                sim.WriteCSVResults(CSVFileBase( String.Format("{0}", i) ));
            }
        }
    }
}
