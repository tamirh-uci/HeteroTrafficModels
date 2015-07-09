using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.Simulation
{
    class SimResultAggregate
    {
        private List<SimRunResult> raw;
        
        // public fields to output to CSV
        public double Datarate;
        public double PacketsOverThreshold;
        
        public SimResultAggregate(List<SimRunResult> _raw)
        {
            raw = _raw;

            Datarate = 0;
            PacketsOverThreshold = 0;

            CalculateAggregates();
        }

        private void CalculateAggregates()
        {
            foreach(SimRunResult runResult in raw)
            {
                SimNodeResult nodeResult = runResult.Get(0);
                Datarate += nodeResult.datarate;
                PacketsOverThreshold += nodeResult.packetsOverThreshold;
            }

            Datarate /= raw.Count;
            PacketsOverThreshold /= raw.Count;
        }

        public static FieldInfo[] CSVFields()
        {
            SimResultAggregate dummy = new SimResultAggregate(new List<SimRunResult>());
            return dummy.GetType().GetFields(BindingFlags.Public | BindingFlags.Instance);
        }

        public object CSVFieldData(string name)
        {
            return this.GetType().GetField(name).GetValue(this);
        }
    }
}
