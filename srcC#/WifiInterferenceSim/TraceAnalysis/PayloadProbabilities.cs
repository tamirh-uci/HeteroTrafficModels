using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.TraceAnalysis
{
    class PayloadProbabilities
    {
        // in
        private int[] payloadBins;

        // out
        private double[] probabilities;


        public PayloadProbabilities(int[] _payloadBins)
        {
            payloadBins = _payloadBins;
            probabilities = new double[payloadBins.Length];
        }

        public double[] Probabilities { get { return probabilities; } }

        public void Analyze(List<int> csvPacketSizes)
        {
            // Init
            for (int i = 0; i < probabilities.Length; ++i)
            {
                probabilities[i] = 0;
            }

            // If we're empty, just make all equal probabilities
            if (csvPacketSizes.Count == 0)
            {
                for (int i = 0; i < payloadBins.Length; ++i)
                {
                    csvPacketSizes.Add(payloadBins[i]);
                }
            }

            // Add up how many times we're in each bin
            foreach (int packetsize in csvPacketSizes)
            {
                // If we're bigger than our bins, then dump into the last one
                if (packetsize >= payloadBins[payloadBins.Length - 1])
                {
                    probabilities[payloadBins.Length - 1]++;
                    continue;
                }

                bool foundBin = false;
                for (int i = 0; i < payloadBins.Length; ++i)
                {
                    if (packetsize <= payloadBins[i])
                    {
                        probabilities[i]++;
                        foundBin = true;
                        break;
                    }
                }

                Debug.Assert(foundBin);
            }

            // Divide by numPackets to get probability we're in each bin
            for (int i = 0; i < probabilities.Length; ++i)
            {
                probabilities[i] /= csvPacketSizes.Count;
            }

            // Generate a cumulitive sum for easier random distribution
            for (int i = 1; i < probabilities.Length; ++i)
            {
                probabilities[i] += probabilities[i - 1];
            }

            Debug.Assert(probabilities[probabilities.Length - 1] > 0.9999 && probabilities[probabilities.Length - 1] < 1.0001);
            probabilities[probabilities.Length - 1] = 1.0;
        }
    }
}
