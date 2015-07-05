using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Diagnostics;
using System.IO;
using WifiInterferenceSim.Simulation;

namespace WifiInterferenceSim.DCF
{
    class DCFNode
    {
        static int NEXT_UID = 1;

        // For non-integer arrival rates
        double packetLeftovers;

        // Determines the number of steps to wait at each backoff level
        int[] backoffs;

        // Determine the likelyhood we'll fall into deep sleep
        double[] sleepCycles;

        // History of everything that happend to this node
        SimulationTrace trace;

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
        double qualityThreshold;

        // Internal result stuff
        SimulationNodeResults results;
        int uid;

        public DCFNode(string _name, DCFParams _cfg, int randseed, double _qualityThreshold)
        {
            uid = NEXT_UID++;

            name = _name;
            cfg = _cfg;
            qualityThreshold = _qualityThreshold;

            curStep = 0;
            packetLeftovers = 0;
            currPacket.Invalidate();
            
            if (randseed < 0)
                rand = new Random(uid + ((int)DateTime.Now.Ticks & 0x0000FFFF));
            else
                rand = new Random(randseed);
        }

        public void Init(int steps, Physical80211 network)
        {
            trace = new SimulationTrace(steps, network);

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

            trace.queue.Enqueue(new Packet(curStep, payloadSize));
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
                if (trace.queue.Count == 0)
                {
                    // Empty buffer
                    SetStateBufferEmpty();
                }
                else
                {
                    // Are we going into interarrival?
                    if (trace.queue.Count < cfg.interarrivalCutoff && rand.NextDouble() < cfg.pInterarrival)
                    {
                        SetStateInterarrival();
                    }
                    else
                    {
                        // Attempt transmission of packet from buffer
                        currPacket = trace.queue.Dequeue();
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
                trace.sent.Add(currPacket);
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
                if (trace.queue.Count != 0)
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
                packetLeftovers -= trace.queue.Peek().payloadSize;
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
            trace.states.Add(curr);
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

            foreach(Packet p in trace.sent)
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

            if (trace.sent.Count > 0)
            {
                avgTimeSlotsOverThreshold = timeSlotsOverThreshold / trace.sent.Count;
            }

            foreach(Packet p in trace.queue)
            {
                packetsUnsent += p.payloadSize;
            }
        }

        private void EvalStateHistory(out Int64 maxSleepStage, out double avgSleepStage)
        {
            maxSleepStage = 0;
            avgSleepStage = 0;

            Int64 totalSleepStage = 0;
            foreach (DCFState state in trace.states)
            {
                maxSleepStage = Math.Max(maxSleepStage, state.sleepStage);
                totalSleepStage += state.sleepStage;
            }

            if (trace.states.Count > 0)
            {
                avgSleepStage = totalSleepStage / trace.states.Count;
            }
        }
        
        public SimulationNodeResults CalculateResults(bool keepTrace)
        {
            results = new SimulationNodeResults();
            results.name = name;

            if (keepTrace)
            {
                results.trace = trace;
            }

            results.qualityThreshold = qualityThreshold;

            results.secondsPerSlot = Physical80211.TransactionTime(trace.network.type, trace.network.payloadBits) / 1000000.0;
            results.timeSpent = curStep * results.secondsPerSlot;
            results.thresholdSlots = (Int64)((qualityThreshold / results.secondsPerSlot) + 0.5);

            EvalPacketHistory(results.thresholdSlots, out results.packetsSent, out results.packetsUnsent, out results.packetsOverThreshold, out results.timeSlotsOverThreshold, out results.maxTimeSlotsOverThreshold, out results.avgTimeSlotsOverThreshold);
            EvalStateHistory(out results.maxSleepStage, out results.avgSleepStage);

            results.bitsSent = results.packetsSent * trace.network.payloadBits;
            results.datarate = results.bitsSent / results.timeSpent;

            return results;
        }

        public SimulationTrace GetTrace()
        {
            return trace;
        }
    }
}
