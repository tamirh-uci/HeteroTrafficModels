using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WifiInterferenceSim.TraceAnalysis
{
    struct NeuralNetParams
    {
        public double divisionTimeSlice;
        public int numInputs;
        public int numOutputs;
        public int numHidden;
        public int maxEpochs;
        public double learnRate;
        public double momentum;

        public NeuralNetParams(double _divisionTimeSlice, int _numInputs, int _numOutputs, int _numHidden, int _maxEpochs, double _learnRate, double _momentum)
        {
            divisionTimeSlice = _divisionTimeSlice;
            numInputs = _numInputs;
            numOutputs = _numOutputs;
            numHidden = _numHidden;
            maxEpochs = _maxEpochs;
            learnRate = _learnRate;
            momentum = _momentum;
        }
    }
}
