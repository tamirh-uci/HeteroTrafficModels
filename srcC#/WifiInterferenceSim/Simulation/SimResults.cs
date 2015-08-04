using System.Collections.Generic;

namespace WifiInterferenceSim.Simulation
{
    class SimResults
    {
        Dictionary<string, List<SimRunResult>> unindexed;
        Dictionary<string, List<SimRunResult>> indexed;
        Dictionary<string, List<SimRunResult>> group;

        List<SimRunResult> all;

        public SimResults()
        {
            all = new List<SimRunResult>();
            unindexed = new Dictionary<string, List<SimRunResult>>();
            group = new Dictionary<string, List<SimRunResult>>();
            indexed = new Dictionary<string, List<SimRunResult>>();
        }

        private void Add(Dictionary<string, List<SimRunResult>> dictionary, string key, SimRunResult runResult)
        {
            if (!dictionary.ContainsKey(key))
            {
                dictionary[key] = new List<SimRunResult>();
            }

            dictionary[key].Add(runResult);
        }

        public void Add(SimRunResult runResult)
        {
            all.Add(runResult);
            Add(unindexed, runResult.UnIndexedName, runResult);
            Add(indexed, runResult.IndexedName, runResult);
            Add(group, runResult.GroupName, runResult);
        }

        public Dictionary<string, List<SimRunResult>> UnindexedNameResults { get { return unindexed; } }
        public Dictionary<string, List<SimRunResult>> IndexedNameResults { get { return indexed; } }
        public Dictionary<string, List<SimRunResult>> GroupNameResults { get { return group; } }

    }
}
