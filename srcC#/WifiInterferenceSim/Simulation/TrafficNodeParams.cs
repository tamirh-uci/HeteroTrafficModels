using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.TraceAnalysis;

namespace WifiInterferenceSim.Simulation
{
    struct TrafficNodeParams
    {
        public int minSimulateNodes;
        public int maxSimulateNodes;
        public double arrivalRateMultiplier;
        public double lateThreshold;
        public int bytesPerPayload;
        public int[] payloadBins;

        public TrafficAnalyzer trafficAnalyzer;

        public TrafficNodeParams(int _minSimulateNodes, int _maxSimulateNodes, double _arrivalRateMultiplier, double _lateThreshold, int _bytesPerPayload, int[] _payloadBins, int _maxNumBpsDivisions, NeuralNetParams nnParams)
        {
            minSimulateNodes = _minSimulateNodes;
            maxSimulateNodes = _maxSimulateNodes;
            arrivalRateMultiplier = _arrivalRateMultiplier;
            lateThreshold = _lateThreshold;
            bytesPerPayload = _bytesPerPayload;
            payloadBins = _payloadBins;

            PayloadProbabilities payloadProbabilities = new PayloadProbabilities(payloadBins);
            BPSWindows bpsWindows = new BPSWindows(_maxNumBpsDivisions);
            TimeSeriesNN neuralNetwork = new TimeSeriesNN(nnParams);

            trafficAnalyzer = new TrafficAnalyzer(payloadProbabilities, bpsWindows, neuralNetwork);
        }
    }
}
