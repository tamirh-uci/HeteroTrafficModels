using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using WifiInterferenceSim.lib;

namespace WifiInterferenceSim.TraceAnalysis
{
    /// <summary>
    /// Analyze a series of network traffic by time and create neural network to represent the data
    /// </summary>
    class TimeSeriesNN
    {
        // const
        private static double TRAIN_PERCENT = 0.8;
        private static int SEED_SPLIT_TRAIN = 1;

        // in
        private double divisionTimeSlice;
        private int numInput;
        private int numOutput;
        private int numHidden;
        private int maxEpochs;
        private double learnRate;
        private double momentum;

        // out
        private double[] trainedWeights;

        public TimeSeriesNN(NeuralNetParams nnParams)
        {
            divisionTimeSlice = nnParams.divisionTimeSlice;
            numInput = nnParams.numInputs;
            numOutput = nnParams.numOutputs;
            numHidden = nnParams.numHidden;

            maxEpochs = nnParams.maxEpochs;
            learnRate = nnParams.learnRate;
            momentum = nnParams.momentum;
        }
        
        public double[] TrainedWeights { get { return trainedWeights; } }

        public void Analyze(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            // Convert our input data into a format the neural network can use
            double[][] nnAllData = GenerateNNInputMatrix(csvTimes, csvPacketSizes, minTime, maxTime);
            
            // Split our data set into training and test data
            double[][] nnTrainingData;
            double[][] nnTestData;
            NeuralNetwork.SplitTrainTest(nnAllData, TRAIN_PERCENT, SEED_SPLIT_TRAIN, out nnTrainingData, out nnTestData);

            NeuralNetwork nn = new NeuralNetwork(numInput, numHidden, numOutput);

            trainedWeights = nn.Train(nnTrainingData, maxEpochs, learnRate, momentum);

            double accuracyTrain = nn.Accuracy(nnTrainingData);
            double accuracyTest = nn.Accuracy(nnTestData);

            Console.WriteLine("Final accuracy on training data = {0}", accuracyTrain);
            Console.WriteLine("Final accuracy on test data = {0}", accuracyTest);
        }
        
        private double[][] GenerateNNInputMatrix(List<double> csvTimes, List<int> csvPacketSizes, double minTime, double maxTime)
        {
            BPSWindow bpsData = new BPSWindow(divisionTimeSlice);
            bpsData.Analyze(csvTimes, csvPacketSizes, minTime, maxTime);

            int windowSize = numInput + numOutput;
            int numRows = bpsData.WindowedBPS.Count - windowSize + 1;

            double[][] nnInput = new double[numRows][];
            for (int i = 0; i < numRows; ++i)
            {
                nnInput[i] = new double[windowSize];
            }

            // We use a window size of nnNumInputs values, and roll it along all of our bps results
            // The output value is the next BPS value
            int windowStart = 0;
            int windowEnd = windowSize;

            while (windowEnd <= bpsData.WindowedBPS.Count)
            {
                double[] currentRow = nnInput[windowStart];
                int offset = windowStart;

                for (int i = 0; i < numInput; ++i)
                {
                    currentRow[i] = bpsData.WindowedBPS[i + offset];
                }

                offset = windowStart + numInput;
                for (int i=0; i < numOutput; ++i)
                {
                    currentRow[i + numInput] = bpsData.WindowedBPS[i + offset];
                }

                windowStart += 1;
                windowEnd += 1;
            }

            return nnInput;
        }
    }
}
