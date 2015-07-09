using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class TrafficNodeParams
    {
        // User entered
        public double threshold;
        public double multiplier;
        public int min, max;
        private int[] packetsizeBins;

        // From trace analysis
        public double[] packetsizeProbabilities;

        public TrafficNodeParams(int _min, int _max, double _multiplier, double _threshold, int[] _packetsizeBins)
        {
            min = _min;
            max = _max;
            multiplier = _multiplier;
            threshold = _threshold;

            packetsizeBins = _packetsizeBins;
            packetsizeProbabilities = new double[packetsizeBins.Length];
        }

        public void AnalyzeTrace(string filename)
        {
            List<double> csvTimes = new List<double>();
            List<int> csvPacketSizes = new List<int>();

            try
            {
                ReadCSV(filename, csvTimes, csvPacketSizes);
            }
            catch(IOException e)
            {
                Console.WriteLine("Error reading trace: {0}", filename);
                Console.WriteLine(e.ToString());
            }

            AnalyzePacketsizeProbabilities(csvPacketSizes);
        }

        private static void ReadCSV(string filename, List<double> csvTimes, List<int> csvPacketSizes)
        {
            StreamReader r = new StreamReader(filename);
            double csvTime;
            int csvPacketsize;

            // Grab trace in format <time>, <packetsize>
            while (!r.EndOfStream)
            {
                string line = r.ReadLine();
                string[] values = line.Split(',');

                // Throw away any lines that have invalid data
                if (Double.TryParse(values[0], out csvTime) && Int32.TryParse(values[1], out csvPacketsize))
                {
                    csvTimes.Add(csvTime);
                    csvPacketSizes.Add(csvPacketsize);
                }
            }
        }

        private void AnalyzePacketsizeProbabilities(List<int> csvPacketSizes)
        {
            // Init
            for (int i = 0; i < packetsizeProbabilities.Length; ++i)
            {
                packetsizeProbabilities[i] = 0;
            }

            // If we're empty, just make all equal probabilities
            if (csvPacketSizes.Count == 0)
            {
                for(int i = 0; i < packetsizeBins.Length; ++i)
                {
                    csvPacketSizes.Add(packetsizeBins[i]);
                }
            }

            // Add up how many times we're in each bin
            foreach (int packetsize in csvPacketSizes)
            {
                // If we're bigger than our bins, then dump into the last one
                if (packetsize >= packetsizeBins[packetsizeBins.Length-1])
                {
                    packetsizeProbabilities[packetsizeBins.Length - 1]++;
                    break;
                }
                
                for (int i = 0; i < packetsizeBins.Length; ++i)
                {
                    if (packetsize <= packetsizeBins[i])
                    {
                        packetsizeProbabilities[i]++;
                        break;
                    }
                }

                // Should never reach here
                Debug.Assert(false);
            }

            // Divide by numPackets to get probability we're in each bin
            for (int i = 0; i < packetsizeProbabilities.Length; ++i)
            {
                packetsizeProbabilities[i] /= csvPacketSizes.Count;
            }
        }
    }
}
