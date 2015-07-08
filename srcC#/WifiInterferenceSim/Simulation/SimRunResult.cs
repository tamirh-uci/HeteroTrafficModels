using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.DCF;

namespace WifiInterferenceSim.Simulation
{
    class SimRunResult
    {
        string simName;
        string groupName;
        int runIndex;

        List<SimNodeResult> nodeResults;

        public int NumNodes { get { return nodeResults.Count; } }
        public string IndexedName { get { return String.Format("{0}-run{1}", simName, runIndex); } }
        public string UnIndexedName { get { return simName; } }
        public string GroupName {  get { return groupName; } }

        public SimRunResult(string _simName, string _groupName, int _runIndex)
        {
            simName = _simName;
            groupName = _groupName;
            runIndex = _runIndex;

            nodeResults = new List<SimNodeResult>();
        }

        public void Add(SimNodeResult newResult)
        {
            nodeResults.Add(newResult);
        }

        public SimNodeResult Get(int index)
        {
            return nodeResults[index];
        }

        public string NodeNames()
        {
            Dictionary<TrafficType, int> numNodeTypes = new Dictionary<TrafficType,int>();

            foreach(SimNodeResult nodeResult in nodeResults)
            {
                if (numNodeTypes.ContainsKey(nodeResult.type))
                {
                    numNodeTypes[nodeResult.type]++;
                }
                else
                {
                    numNodeTypes[nodeResult.type] = 1;
                }
            }

            StringBuilder s = new StringBuilder();
            foreach (TrafficType type in Enum.GetValues(typeof(TrafficType)))
            {
                if (numNodeTypes.ContainsKey(type))
                {
                    if (s.Length > 0)
                        s.Append('_');

                    s.AppendFormat("{0}{1}", TrafficUtil.ShortName(type), numNodeTypes[type]);
                }
            }

            return s.ToString();
        }
    }
}
