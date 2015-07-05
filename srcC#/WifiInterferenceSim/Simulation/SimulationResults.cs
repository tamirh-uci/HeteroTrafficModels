using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.Simulation;

namespace WifiInterferenceSim.DCF
{
    class SimulationResults
    {
        List<SimulationNodeResults> results;

        public SimulationResults()
        {
            results = new List<SimulationNodeResults>();
        }

        public void Add(SimulationNodeResults nodeResults)
        {
            results.Add(nodeResults);
        }

        public SimulationNodeResults GetResults(int index)
        {
            return results[index];
        }
    }
}
