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
        static int STEPS = 40000;
        static double ARRIVAL_MBPS = 1.25;
        static Int64 PAYLOAD_BITS = 1500 * 8;
        static double QUALITY_THRESHOLD = 0.10; // 50 milliseconds

        static void Main(string[] args)
        {
            Physical80211 network = new Physical80211(NetworkType.B, PAYLOAD_BITS);
            Simulator sim = new Simulator();

            double arrivalBps = 1000000 * ARRIVAL_MBPS;

            DCFParams datTraffic = Traffic.File(network, arrivalBps);
            DCFParams webTraffic = Traffic.Web(network, arrivalBps);
            DCFParams vidTraffic = Traffic.Video(network, arrivalBps);

            //sim.AddNode(new DCFNode("video", vidTraffic, 1));
            sim.AddNode(new DCFNode("files", datTraffic, 1));
            //sim.AddNode(new DCFNode("web", webTraffic, 1));
            
            sim.Steps(STEPS);
            sim.PrintResults(network, QUALITY_THRESHOLD);

            Console.WriteLine("\n");
        }
    }
}
