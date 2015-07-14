using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.DCF
{
    class BPSAnalysis
    {
        // 1st index tells the number of divisions made
        // 2nd index tells you all of the bps's at the different windows created by the divisions
        List<List<double>> windowedBps;

        public int MaxDivisions { get { return windowedBps.Count; } }

        public BPSAnalysis()
        {
            windowedBps = new List<List<double>>();
        }

        public void Analyze(int numDivisions, List<double> csvTimes, List<int> csvPacketSizes)
        {
            // Find the time bounds of our trace
            double minTime = Double.MaxValue;
            double maxTime = Double.MinValue;
            foreach(double time in csvTimes)
            {
                minTime = Math.Min(minTime, time);
                maxTime = Math.Max(maxTime, time);
            }

            for(int i=0; i < numDivisions; ++i)
            {
                windowedBps.Add(GenerateWindowedBPS(i, minTime, maxTime, csvTimes, csvPacketSizes));
            }
        }

        private static List<double> GenerateWindowedBPS(int numDivisions, double minTime, double maxTime, List<double> csvTimes, List<int> csvPacketSizes)
        {
            int numWindows = numDivisions + 1;
            double windowTime = (maxTime - minTime)/numWindows;

            List<double> windowedBps = new List<double>();
            List<double> timeWindows = new List<double>();

            timeWindows.Add(minTime);
            for (int i=0; i<numWindows; ++i)
            {
                windowedBps.Add(0);
                timeWindows.Add( Math.Min(windowTime * (1+i), maxTime) );
            }

            // parcel out each packet into the appropriate bin and count up bits
            for (int i=0; i<csvPacketSizes.Count; ++i)
            {
                double time = csvTimes[i];
                int packetSize = 8 * csvPacketSizes[i]; // packetsizes come in as bytes

                // Find the correct bin
                for (int j=0; j<numWindows; ++j)
                {
                    if (time >= timeWindows[j] && time <= timeWindows[j+1])
                    {
                        windowedBps[j] += packetSize;
                        break;
                    }

                    Debug.Assert(false);
                }
            }
            
            // Divide out by the length of time each bin has to get bits per second
            for( int i=0; i<numWindows; ++i)
            {
                windowTime = timeWindows[i+1] - timeWindows[i];
                windowedBps[i] /= windowTime;
            }

            return windowedBps;
        }
    }

    class TrafficAnalyzer
    {
        // User entered
        public double threshold;
        public double multiplier;
        public int min, max;

        public int bytesPerPayload;
        public int[] payloadBins;
        

        // From trace analysis
        public double[] payloadProbabilities;
        public BPSAnalysis windowedBps;


        public TrafficAnalyzer(int _min, int _max, double _multiplier, double _threshold, int _bytesPerPayload, int[] _payloadBins)
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
            AnalyzeBPS(csvTimes, csvPacketSizes);
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

        private void AnalyzeBPS(List<double> csvTimes, List<int> csvPacketSizes)
        {
            windowedBps = new BPSAnalysis();
            windowedBps.Analyze(2, csvTimes, csvPacketSizes);
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
