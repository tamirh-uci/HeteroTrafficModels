using System;
using System.Collections.Generic;
using System.Diagnostics;

namespace WifiInterferenceSim.TraceAnalysis
{
    class BPSWindows
    {
        private int maxNumDivisions;
        
        // 1st index tells the number of divisions made
        // 2nd index tells you all of the bps's at the different windows created by the divisions
        private List<WindowedByteTransfer> bpsWindows;

        public int MaxDivisions { get { return maxNumDivisions; } }

        public BPSWindows(int _maxNumDivisions)
        {
            maxNumDivisions = _maxNumDivisions;
            bpsWindows = new List<WindowedByteTransfer>(maxNumDivisions);
        }

        public List<WindowedByteTransfer> Windows { get { return bpsWindows; } }
        
        public void Analyze(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            for (int i = 0; i < maxNumDivisions; ++i)
            {
                bpsWindows.Add(new WindowedByteTransfer(i));
                bpsWindows[i].Analyze(csvTimes, csvPacketSizes, minTime, maxTime);
            }
        }
    }
}
