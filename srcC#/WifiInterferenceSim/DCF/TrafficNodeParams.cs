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

        public int bytesPerPayload;
        public int[] payloadBins;
        

        // From trace analysis
        public double[] payloadProbabilities;

        public TrafficNodeParams(int _min, int _max, double _multiplier, double _threshold, int _bytesPerPayload, int[] _payloadBins)
        {
            min = _min;
            max = _max;
            multiplier = _multiplier;
            threshold = _threshold;

            bytesPerPayload = _bytesPerPayload;
            payloadBins = _payloadBins;
            payloadProbabilities = new double[payloadBins.Length];
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
            for (int i = 0; i < payloadProbabilities.Length; ++i)
            {
                payloadProbabilities[i] = 0;
            }

            // If we're empty, just make all equal probabilities
            if (csvPacketSizes.Count == 0)
            {
                for(int i = 0; i < payloadBins.Length; ++i)
                {
                    csvPacketSizes.Add(payloadBins[i]);
                }
            }

            // Add up how many times we're in each bin
            foreach (int packetsize in csvPacketSizes)
            {
                // If we're bigger than our bins, then dump into the last one
                if (packetsize >= payloadBins[payloadBins.Length-1])
                {
                    payloadProbabilities[payloadBins.Length - 1]++;
                    break;
                }
                
                for (int i = 0; i < payloadBins.Length; ++i)
                {
                    if (packetsize <= payloadBins[i])
                    {
                        payloadProbabilities[i]++;
                        break;
                    }
                }

                // Should never reach here
                Debug.Assert(false);
            }

            // Divide by numPackets to get probability we're in each bin
            for (int i = 0; i < payloadProbabilities.Length; ++i)
            {
                payloadProbabilities[i] /= csvPacketSizes.Count;
            }

            // Generate a cumulitive sum for easier random distribution
            for (int i = 1; i < payloadProbabilities.Length; ++i)
            {
                payloadProbabilities[i] += payloadProbabilities[i - 1];
            }

            Debug.Assert(payloadProbabilities[payloadProbabilities.Length - 1] > 0.9999 && payloadProbabilities[payloadProbabilities.Length - 1] < 1.0001);
            payloadProbabilities[payloadProbabilities.Length - 1] = 1.0;
        }
    }
}
