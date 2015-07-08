using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.Simulation
{
    class SimResultAggregate
    {
        List<SimRunResult> raw;

        public int NumRuns;

        public SimResultAggregate(List<SimRunResult> _raw)
        {
            raw = _raw;
            CalculateAggregates();
        }

        private void CalculateAggregates()
        {
            NumRuns = raw.Count;
        }

        private void HeaderToCSV(StreamWriter w)
        {
            w.Write("{0}", "NumRuns");
        }

        private void ToCSV(StreamWriter w)
        {
            w.Write("{0}", NumRuns);
        }
    }
}
