using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;

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

            RandomizeStartState();
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

        private void RandomizeStartState()
        {
            // Not the best random start state because we're giving equal weight to each state which doesn't make sense
            DCFStateType startState = (DCFStateType)rand.Next(1, Enum.GetValues(typeof(DCFStateType)).Length - 1);
            switch(startState)
            {
                case DCFStateType.Transmit:
                    if (SetStateTransmit())
                    {
                        // Overwrite with a random location in completion of payload
                        curr.payloadTimer = rand.Next(1, currPacket.payloadSize);
                    }
                    break;

                case DCFStateType.Interarrival:
                    SetStateInterarrival();
                    break;

                // For empty buffer, just pretend we're in backoff, it makes more sense for an initial condition
                case DCFStateType.BufferEmpty:
                case DCFStateType.Backoff: 
                    SetStateBackoff(rand.Next(1, backoffs.Length));
                    break;

                case DCFStateType.Sleep:
                    SetStateSleep();
                    break;

                default:
                    Debug.Assert(false);
                    break;
            }
        }

        private bool SetStateTransmit()
        {
            if (packetQueue.Count == 0)
            {
                // Empty buffer
                SetStateBufferEmpty();
                return false;
            }
            else
            {
                Debug.Assert(!currPacket.IsValid());

                // Attempt transmission of packet from buffer
                currPacket = packetQueue.Dequeue();
                currPacket.txAttempt = curStep;

                curr.type = DCFStateType.Transmit;
                curr.payloadTimer = currPacket.payloadSize;
                
                return true;
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

                
                if (rand.NextDouble() < sleepCycles[ Math.Max(curr.sleepStage, sleepCycles.Length-1) ])
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
            SetStateBackoff(backoffs.Length);
        }

        private void SetStateBufferEmpty()
        {
            // stage/timer variables unused in this state
            curr.type = DCFStateType.BufferEmpty;

            Debug.Assert( !currPacket.IsValid() );
        }

        private void StepBufferEmpty()
        {
            // Check if buffer is still empty, if not then proceed in transmission attempt
            if (packetQueue.Count != 0)
            {
                // TODO: Do we transmit immediately, or go into stage=1 backoff?
                SetStateBackoff(1);
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

            }
        }

        private void SetStateBackoff(int backoffStage)
        {
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
                packetLeftovers -= 1.0;
            }

            // Step forward based on what state type we're in
            switch (curr.type)
            {
                case DCFStateType.Transmit:     StepTransmit(); break;
                case DCFStateType.BufferEmpty:  StepBufferEmpty(); break;
                case DCFStateType.Backoff:      StepBackoff(); break;
                case DCFStateType.Sleep:        StepSleep(); break;
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

        public void EvalPacketHistory(Int64 thresholdTimeSlots, out Int64 packetsSent, out Int64 packetsOverThreshold, out Int64 timeSlotsOverThreshold)
        {
            packetsSent = 0;
            packetsOverThreshold = 0;
            timeSlotsOverThreshold = 0;

            foreach(Packet p in historyPackets)
            {
                packetsSent += p.payloadSize;
                int wait = p.txSuccess - p.queueArrival;
                Debug.Assert(wait > 0);
                if (wait > thresholdTimeSlots)
                {
                    packetsOverThreshold++;
                    timeSlotsOverThreshold += wait - thresholdTimeSlots;
                }
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

            Int64 packetsSent, packetsOverThreshold, timeSlotsOverThreshold;
            EvalPacketHistory(thresholdSlots, out packetsSent, out packetsOverThreshold, out timeSlotsOverThreshold);

            Int64 bitsSent = packetsSent * network.payloadBits;
            double datarate = bitsSent / timeSpent;

            Console.WriteLine(" ==Sim Node '{0}'==", name);
            Console.WriteLine(" Data Sent: {0:F1} bits ({1:F2} Mbits)", bitsSent, bitsSent / 1000000.0);
            Console.WriteLine(" Datarate: {0:F1} bps ({1:F2} Mbps)", datarate, datarate / 1000000.0);
            Console.WriteLine(" Packets over threshold: {0}", packetsOverThreshold);
            Console.WriteLine(" Time spent over threshold: {0:F2}", secondsPerSlot * timeSlotsOverThreshold);
        }
    }
}
