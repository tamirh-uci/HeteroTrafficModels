using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.TraceAnalysis
{
    class WindowedByteTransfer
    {
        // in
        private int numDivisions;
        private double divisionTimeSlice;

        // computed
        private int numWindows;

        // out
        // list of bytes at each window
        private List<double> windowedBytes;
        private List<double> windowedBPS;
        
        public WindowedByteTransfer(int _numDivisions)
        {
            numDivisions = _numDivisions;
            divisionTimeSlice = -1;           
        }

        public WindowedByteTransfer(double _divisionTimeSlice)
        {
            numDivisions = -1;
            divisionTimeSlice = _divisionTimeSlice;
        }

        public List<double> WindowedBytes
        {
            get
            {
                return windowedBytes;
            }
        }

        public List<double> WindowedBPS
        {
            get
            {
                if (windowedBPS == null)
                    GenerateBPS();

                return windowedBPS;
            }
        }

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

            GenerateWindowed(csvTimes, csvPacketSizes, minTime, maxTime);
            GenerateBPS();
        }

        private void GenerateWindowed(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            List<double> timeWindows = new List<double>(numWindows);
            windowedBytes = new List<double>(numWindows);

            timeWindows.Add(minTime);
            for (int i = 0; i < numWindows; ++i)
            {
                windowedBytes.Add(0);
                timeWindows.Add(Math.Min(minTime + divisionTimeSlice * (1 + i), maxTime));
            }

            // parcel out each packet into the appropriate bin and count up bits
            for (int i = 0; i < csvPacketSizes.Count; ++i)
            {
                double time = csvTimes[i];
                int packetSize = csvPacketSizes[i]; // packetsizes come in as bytes
                int index = (int)Math.Floor((time - minTime) / divisionTimeSlice);

                // If we didn't find a bin, we're probably within a small margin from the min or max
                if (index < 0 || index >= numWindows)
                {
                    double min = timeWindows[0] - 0.001;
                    double max = timeWindows[numWindows] + 0.001;
                    double mid = (max + min) / 2.0;

                    // We were just under the min time
                    if (time >= min && time <= mid)
                    {
                        windowedBytes[0] += packetSize;
                    }
                    // We were just over the max time
                    else if (time <= max && time >= mid)
                    {
                        windowedBytes[numWindows - 1] += packetSize;
                    }
                    else
                    {
                        // Something happened and we were way off
                        Debug.Assert(false);
                    }
                }
            }
        }

        private void GenerateBPS()
        {
            windowedBPS = new List<double>(numWindows);

            // Divide out by the length of time each bin has to get bits per second
            for (int i = 0; i < numWindows; ++i)
            {
                // Convert bytes -> bits and divide out by the length of time for this window
                windowedBPS.Add(8 * windowedBytes[i] / divisionTimeSlice);
            }
        }
    }
}
