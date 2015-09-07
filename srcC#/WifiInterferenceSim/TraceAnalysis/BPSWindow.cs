using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.TraceAnalysis
{
    class BPSWindow
    {
        // in
        private int numDivisions;
        private double divisionTimeSlice;

        // computed
        private int numWindows;

        // out
        // list of BPS at each division index
        private List<double> windowedBps;


        public BPSWindow(int _numDivisions)
        {
            numDivisions = _numDivisions;
            divisionTimeSlice = -1;           
        }

        public BPSWindow(double _divisionTimeSlice)
        {
            numDivisions = -1;
            divisionTimeSlice = _divisionTimeSlice;
        }

        public List<double> WindowedBPS { get { return windowedBps; } }

        public void Analyze(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            if (numDivisions < 0)
            {
                // We need to calculate the number of divisions based on the timeslice
                Debug.Assert(divisionTimeSlice > 0);

                numWindows = (int)Math.Ceiling( ((maxTime - minTime) / divisionTimeSlice) );
                numDivisions = numWindows - 1;
            }
            else
            {
                // We need to calculate the timeslice based on the number of divisions
                Debug.Assert(numDivisions >= 0);
                Debug.Assert(divisionTimeSlice < 0);

                numWindows = numDivisions + 1;
                divisionTimeSlice = (maxTime - minTime) / numWindows;
            }

            Debug.Assert(numDivisions >= 0);
            Debug.Assert(numWindows >= 1);
            Debug.Assert(divisionTimeSlice > 0);
            
            GenerateWindowedBPS(csvTimes, csvPacketSizes, minTime, maxTime);
        }

        private void GenerateWindowedBPS(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            List<double> timeWindows = new List<double>(numWindows);
            windowedBps = new List<double>(numWindows);
            
            timeWindows.Add(minTime);
            for (int i = 0; i < numWindows; ++i)
            {
                windowedBps.Add(0);
                timeWindows.Add(Math.Min(minTime + divisionTimeSlice * (1 + i), maxTime));
            }

            // parcel out each packet into the appropriate bin and count up bits
            for (int i = 0; i < csvPacketSizes.Count; ++i)
            {
                double time = csvTimes[i];
                int packetSize = 8 * csvPacketSizes[i]; // packetsizes come in as bytes

                // Find the correct bin
                bool foundBin = false;
                for (int j = 0; j < numWindows; ++j)
                {
                    if (time >= timeWindows[j] && time <= timeWindows[j + 1])
                    {
                        windowedBps[j] += packetSize;
                        foundBin = true;
                        break;
                    }
                }

                // If we didn't find a bin, we're probably within a small margin from the min or max
                if (!foundBin)
                {
                    double min = timeWindows[0] - 0.001;
                    double max = timeWindows[numWindows] + 0.001;
                    double mid = (max + min) / 2.0;

                    // We were just under the min time
                    if (time >= min && time <= mid)
                    {
                        windowedBps[0] += packetSize;
                    }
                    // We were just over the max time
                    else if (time <= max && time >= mid)
                    {
                        windowedBps[numWindows - 1] += packetSize;
                    }
                    else
                    {
                        // Something happened and we were way off
                        Debug.Assert(false);
                    }
                }
            }

            // Divide out by the length of time each bin has to get bits per second
            for (int i = 0; i < numWindows; ++i)
            {
                divisionTimeSlice = timeWindows[i + 1] - timeWindows[i];
                windowedBps[i] /= divisionTimeSlice;
            }
        }
    }
}
