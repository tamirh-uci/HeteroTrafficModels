using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    struct SimParams
    {
        public TrafficType type;
        public int minNodes, maxNodes;
        public double arrivalBps;
        public double qualityThreshold;
        public int randSeed;

        public SimParams(TrafficType _type, int _minNodes, int _maxNodes, double _arrivalBps, double _qualityThreshold, int _randSeed)
        {
            type = _type;
            minNodes = _minNodes;
            maxNodes = _maxNodes;
            arrivalBps = _arrivalBps;
            qualityThreshold = _qualityThreshold;
            randSeed = _randSeed;
        }

        public SimParams(TrafficType _type, int _numNodes, double _arrivalBps, double _qualityThreshold, int _randSeed)
        {
            type = _type;
            minNodes = maxNodes = _numNodes;
            arrivalBps = _arrivalBps;
            qualityThreshold = _qualityThreshold;
            randSeed = _randSeed;
        }
    }
}
