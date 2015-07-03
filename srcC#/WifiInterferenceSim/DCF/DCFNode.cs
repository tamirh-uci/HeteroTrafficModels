using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IO;

namespace WifiInterferenceSim.DCF
{
    class DCFNode
    {
        // How many packets are in the queue ready to be transmitted
        Queue<Packet> packetQueue;

        // For non-integer arrival rates
        double packetLeftovers;

        // Determines the number of steps to wait at each backoff level
        int[] backoffs;

        // Determine the likelyhood we'll fall into deep sleep
        double[] sleepCycles;

        // History of all steps taken
        List<DCFState> historyStates;

        // History of all our transmitted packets
        Queue<Packet> historyPackets;

        // How many steps we have taken in the simulation
        int curStep;

        // State of this node
        DCFState curr;
        DCFState prev;
        Packet currPacket;
        Random rand;
        string name;

        // All user modifyable parameters
        DCFParams cfg;

        public DCFNode(string _name, DCFParams _cfg, int randseed)
        {
            name = _name;
            cfg = _cfg;

            curStep = 0;
            packetLeftovers = 0;
            currPacket.Invalidate();
            
            if (randseed < 0)
                rand = new Random();
            else
                rand = new Random(randseed);
        }

        public void Init(int steps)
        {
            historyStates = new List<DCFState>(steps);
            historyPackets = new Queue<Packet>();
            packetQueue = new Queue<Packet>();

            if (cfg.minInterarrival <= 0)
            {
                cfg.pInterarrival = 0;
            }

            int backoffStages = 1 + (int)Math.Log((double)cfg.maxBackoff / cfg.minBackoff, 2.0);
            backoffs = new int[backoffStages];
            for (int backoffStage = 0; backoffStage < backoffStages; ++backoffStage)
            {
                // In the DCF model, 1 step is used for transmission so the actual number of possible
                // backoff steps is one less than the number of columns in that stage
                backoffs[backoffStage] = (int)Math.Pow(2.0, backoffStage) * cfg.minBackoff - 1;
            }

            sleepCycles = new double[cfg.awakeTime + cfg.drowsyTime + 1];

            int i = 0;
            for (; i < cfg.awakeTime; ++i)
                sleepCycles[i] = 0.0;

            for (; i < (cfg.awakeTime + cfg.drowsyTime); ++i)
                sleepCycles[i] = cfg.pDrowsySleep;

            // Force sleep if we went over entire drowsy period without sleeping
            sleepCycles[i] = 1.0;

            StartState();
        }

        public bool IsTransmitting()
        {
            return curr.type == DCFStateType.Transmit;
        }

        private void GeneratePacket()
        {
            // pSmallPayload chance we have the minimum payload size
            int payloadSize = cfg.minPayload;
            if (rand.NextDouble() >= cfg.pSmallPayload)
            {
                // We distribute evenly over other payload size options
                Debug.Assert(cfg.minPayload < cfg.maxPayload);
                payloadSize = rand.Next(cfg.minPayload + 1, cfg.maxPayload);
            }

            packetQueue.Enqueue(new Packet(curStep, payloadSize));
        }

        private void StartState()
        {
            // Tamest state to set, will find out soon if the buffer is not empty
            SetStateBufferEmpty();

            // Randomize our 'start' time a bit
            packetLeftovers = rand.NextDouble();
        }

        private void SetStateTransmit()
        {
            if (currPacket.IsValid())
            {
                // Coming back from a failed transmission, pick up where we left off
                curr.type = DCFStateType.Transmit;
            }
            else
            {
                if (packetQueue.Count == 0)
                {
                    // Empty buffer
                    SetStateBufferEmpty();
                }
                else
                {
                    // Are we going into interarrival?
                    if (packetQueue.Count < cfg.interarrivalCutoff && rand.NextDouble() < cfg.pInterarrival)
                    {
                        SetStateInterarrival();
                    }
                    else
                    {
                        // Attempt transmission of packet from buffer
                        currPacket = packetQueue.Dequeue();
                        currPacket.txAttempt = curStep;

                        curr.type = DCFStateType.Transmit;
                        curr.payloadTimer = currPacket.payloadSize;
                    }
                }
            }
        }

        private void StepTransmit()
        {
            curr.payloadTimer--;
            curr.sleepStage++;

            if (curr.payloadTimer <= 0)
            {
                // We have completed a transmission
                // TODO: pSingleSuccess

                // Add packet to history of completed packets, then remove from current buffer
                currPacket.txSuccess = curStep;
                historyPackets.Enqueue(currPacket);
                currPacket.Invalidate();

                if (cfg.minSleep > 0 && rand.NextDouble() < sleepCycles[Math.Min(curr.sleepStage, sleepCycles.Length - 1)])
                {
                    // Go into a long sleep instead of normal short backoff
                    SetStateSleep();
                }
                else
                {
                    // Backoff with shortest stage timer to try and transmit more
                    SetStateBackoff(1);
                }
            }
            // else nothing to do if we're in the middle of a transmission
        }

        private void FailTransmit()
        {
            // We keep the same packet data, but we will backoff at a longer stage
            SetStateBackoff(curr.backoffStage + 1);
        }

        private void SetStateBufferEmpty()
        {
            // Buffer is empty, go into a sleep to wait for it to fill up
            curr.type = DCFStateType.BufferEmpty;
            curr.sleepStage = 0;
            curr.sleepTimer = rand.Next(cfg.minBufferEmptySleep, cfg.maxBufferEmptySleep);

            Debug.Assert( !currPacket.IsValid() );
        }

        private void StepBufferEmpty()
        {
            curr.sleepTimer--;

            if (curr.sleepTimer <= 0)
            {
                // Check if buffer is still empty, if not then proceed in transmission attempt
                if (packetQueue.Count != 0)
                {
                    // TODO: Do we transmit immediately, or go into stage=1 backoff?
                    SetStateBackoff(1);
                }
                else
                {
                    // If buffer was still empty, go back to sleep
                    SetStateBufferEmpty();
                }
            }
        }

        private void SetStateInterarrival()
        {
            curr.type = DCFStateType.Interarrival;
            curr.interarrivalTimer = rand.Next(cfg.minInterarrival, cfg.maxInterarrival);

            if (curr.interarrivalTimer <= 0)
            {
                // There actually was no interarrival
                SetStateTransmit();
            }
            // else we have nothing to do
        }

        private void StepInterarrival()
        {
            curr.interarrivalTimer--;

            if (curr.interarrivalTimer <= 0)
            {
                // Attempt to transmit again once our interarrival is over
                SetStateTransmit();
            }
        }

        private void SetStateBackoff(int backoffStage)
        {
            if (backoffStage > backoffs.Length)
            {
                backoffStage = backoffs.Length;
            }

            // Even distribution over interarrival stage
            curr.type = DCFStateType.Backoff;
            curr.backoffStage = backoffStage;
            curr.backoffTimer = rand.Next(1, backoffs[curr.backoffStage - 1]);
        }

        private void StepBackoff()
        {
            curr.backoffTimer--;
            if (curr.backoffTimer <= 0)
            {
                // We have completed waiting for the required backoff window, attempt to send
                SetStateTransmit();
            }
            // else, we do nothing and wait for backoff to complete
        }

        private void SetStateSleep()
        {
            // Even distribution over 
            curr.type = DCFStateType.Sleep;
            curr.sleepStage = 0;
            curr.sleepTimer = rand.Next(cfg.minSleep, cfg.maxSleep);
        }

        private void StepSleep()
        {
            curr.sleepTimer--;
            if (curr.sleepTimer <= 0)
            {
                // Once we come back from sleep, we with an attempt to transmit
                curr.sleepStage = 0;
                SetStateTransmit();
            }
        }

        public void Step()
        {
            // Increment our packet buffer
            packetLeftovers += cfg.packetArrivalRate;
            while(packetLeftovers >= 1.0)
            {
                GeneratePacket();

                // For larger packets, we need to eb the datarate accordingly
                // Allow the 'leftovers' to dip into negative vales for this
                packetLeftovers -= packetQueue.Peek().payloadSize;
            }

            // Step forward based on what state type we're in
            switch (curr.type)
            {
                case DCFStateType.Transmit: StepTransmit(); break;
                case DCFStateType.BufferEmpty: StepBufferEmpty(); break;
                case DCFStateType.Interarrival: StepInterarrival(); break;
                case DCFStateType.Backoff: StepBackoff(); break;
                case DCFStateType.Sleep: StepSleep(); break;
                default:
                    Debug.Assert(false);
                    break;
            }
        }

        public void PostStep()
        {
            // Record current state into history
            historyStates.Add(curr);
            prev = curr;
            curStep++;
        }

        public void Fail()
        {
            switch (curr.type)
            {
                case DCFStateType.Transmit:
                    FailTransmit();
                    break;

                case DCFStateType.Interarrival:
                case DCFStateType.BufferEmpty:
                case DCFStateType.Backoff:
                case DCFStateType.Sleep:
                    // Nothing happens
                    break;

                default:
                    Debug.Assert(false);
                    break;
            }
        }

        private void EvalPacketHistory(Int64 thresholdTimeSlots, out Int64 packetsSent, out Int64 packetsUnsent, out Int64 packetsOverThreshold, out Int64 timeSlotsOverThreshold, out Int64 maxTimeSlotsOverThreshold, out double avgTimeSlotsOverThreshold)
        {
            packetsSent = 0;
            packetsUnsent = 0;
            packetsOverThreshold = 0;
            timeSlotsOverThreshold = 0;
            maxTimeSlotsOverThreshold = 0;
            avgTimeSlotsOverThreshold = 0;

            foreach(Packet p in historyPackets)
            {
                packetsSent += p.payloadSize;
                int wait = p.txSuccess - p.queueArrival;
                Debug.Assert(wait > 0);

                maxTimeSlotsOverThreshold = Math.Max(maxTimeSlotsOverThreshold, wait);

                if (wait > thresholdTimeSlots)
                {
                    packetsOverThreshold++;
                    timeSlotsOverThreshold += wait - thresholdTimeSlots;
                }
            }

            if (historyPackets.Count > 0)
            {
                avgTimeSlotsOverThreshold = timeSlotsOverThreshold / historyPackets.Count;
            }

            foreach(Packet p in packetQueue)
            {
                packetsUnsent += p.payloadSize;
            }
        }

        private void EvalStateHistory(out int maxSleepStage, out double avgSleepStage)
        {
            maxSleepStage = 0;
            avgSleepStage = 0;

            Int64 totalSleepStage = 0;
            foreach (DCFState state in historyStates)
            {
                maxSleepStage = Math.Max(maxSleepStage, state.sleepStage);
                totalSleepStage += state.sleepStage;
            }

            if (historyStates.Count > 0)
            {
                avgSleepStage = totalSleepStage / historyStates.Count;
            }
        }

        public void PrintResults(Physical80211 network, bool overviewInfo, double thresholdSeconds)
        {
            double secondsPerSlot = Physical80211.TransactionTime(network.type, network.payloadBits) / 1000000.0;
            double timeSpent = curStep * secondsPerSlot;
            Int64 thresholdSlots = (Int64)(( thresholdSeconds / secondsPerSlot ) + 0.5);

            if (overviewInfo)
            {
                Console.WriteLine("Steps: {0}", curStep);
                Console.WriteLine("Slot Duration: {0:F2} milliseconds", secondsPerSlot * 1000.0);
                Console.WriteLine("Threshold: {0:F2} milliseconds (~{1} slots)", thresholdSeconds * 1000.0, thresholdSlots);
                Console.WriteLine("Time elapsed: {0:F3} seconds", timeSpent);
                Console.WriteLine("\n");
            }

            Int64 packetsSent, packetsUnsent, packetsOverThreshold, timeSlotsOverThreshold, maxTimeSlotsOverThreshold;
            double avgTimeSlotsOverThreshold;
            EvalPacketHistory(thresholdSlots, out packetsSent, out packetsUnsent, out packetsOverThreshold, out timeSlotsOverThreshold, out maxTimeSlotsOverThreshold, out avgTimeSlotsOverThreshold);

            int maxSleepStage;
            double avgSleepStage;
            EvalStateHistory(out maxSleepStage, out avgSleepStage);

            Int64 bitsSent = packetsSent * network.payloadBits;
            double datarate = bitsSent / timeSpent;

            Console.WriteLine(" ==Sim Node '{0}'==", name);
            Console.WriteLine(" Packets Sent: {0} ({1} still in buffer)", packetsSent, packetsUnsent);
            Console.WriteLine(" Data Sent: {0:F1} bits ({1:F2} Mbits)", bitsSent, bitsSent / 1000000.0);
            Console.WriteLine(" Datarate: {0:F1} bps ({1:F2} Mbps)", datarate, datarate / 1000000.0);
            Console.WriteLine(" Packets over threshold: {0}", packetsOverThreshold);
            Console.WriteLine(" Time spent over threshold: {0:F2} milliseconds ({1} slots)", secondsPerSlot * timeSlotsOverThreshold * 1000.0, timeSlotsOverThreshold);
            Console.WriteLine(" Time spent over threshold per packet: {0:F2} milliseconds ({1:F2} slots)", secondsPerSlot * avgTimeSlotsOverThreshold * 1000.0, avgTimeSlotsOverThreshold);
            Console.WriteLine(" Max time spent over threshold: {0:F2} milliseconds ({1} slots)", secondsPerSlot * maxTimeSlotsOverThreshold * 1000.0, maxTimeSlotsOverThreshold);
            Console.WriteLine(" Average sleep stage: {0:F2} (max {1})", avgSleepStage, maxSleepStage);
        }

        public void WriteCSVResults(Physical80211 network, string filebase)
        {
            string filename = String.Format("{0}-{1}.csv", filebase, name);
            StreamWriter w = new StreamWriter(filename);

            double secondsPerSlot = Physical80211.TransactionTime(network.type, network.payloadBits) / 1000000.0;
            foreach (Packet p in historyPackets)
            {
                double time = p.txSuccess * secondsPerSlot;
                w.WriteLine("{0},{1}", time, p.payloadSize*network.payloadBits/8);
            }

            w.Flush();
            w.Close();
        }
    }
}
