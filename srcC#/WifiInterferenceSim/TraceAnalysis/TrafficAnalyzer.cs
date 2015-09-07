using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace WifiInterferenceSim.TraceAnalysis
{
    class TrafficAnalyzer
    {
        // From trace analysis
        private PayloadProbabilities payloadProbabilities;
        private BPSWindows bpsWindows;
        private TimeSeriesNN neuralNetwork;
        

        public TrafficAnalyzer(PayloadProbabilities _payloadProbabilities, BPSWindows _bpsWindows, TimeSeriesNN _neuralNetwork)
        {
            payloadProbabilities = _payloadProbabilities;
            bpsWindows = _bpsWindows;
            neuralNetwork = _neuralNetwork;
        }

        public PayloadProbabilities PayloadProbabilities { get { return payloadProbabilities; } }
        public BPSWindows BPSWindows { get { return BPSWindows; } }
        public TimeSeriesNN NeuralNetwork { get { return neuralNetwork; } }

        public void AnalyzeTrace(string filename)
        {
            List<double> csvTimes = new List<double>();
            List<int> csvPacketSizes = new List<int>();

            try
            {
                ReadCSV(filename, csvTimes, csvPacketSizes);
            }
            catch (IOException e)
            {
                Console.WriteLine("Error reading trace: {0}", filename);
                Console.WriteLine(e.ToString());
            }

            if (csvTimes.Count == 0 || csvPacketSizes.Count == 0)
            {
                Console.WriteLine("Error reading trace: {0}", filename);
                Console.WriteLine("Could not find valid CSV lines");
            }

            // Find the time bounds of our trace
            double minTime = Double.MaxValue;
            double maxTime = Double.MinValue;
            foreach (double time in csvTimes)
            {
                minTime = Math.Min(minTime, time);
                maxTime = Math.Max(maxTime, time);
            }

            if (payloadProbabilities != null)
            {
                payloadProbabilities.Analyze(csvPacketSizes);
            }

            if (bpsWindows != null)
            {
                bpsWindows.Analyze(csvTimes, csvPacketSizes, minTime, maxTime);
            }

            if (neuralNetwork != null)
            {
                neuralNetwork.Analyze(csvTimes, csvPacketSizes, minTime, maxTime);
            }
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
    }
}
