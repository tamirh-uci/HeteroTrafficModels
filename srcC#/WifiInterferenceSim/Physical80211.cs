using System;
using System.Diagnostics;

namespace WifiInterferenceSim
{
    enum NetworkType
    {
        FHSS, // 1-2 Mbit
        DHSS, // 1-2 Mbit
        B, // 1-11 Mbit
        A, // 1.5-54 Mbit
        G_short, // 1-54 Mbit
        G_long, // 1-54 Mbit
        N24, // 1-600 Mbit
        N50, // 1-600 Mbit
        AC, // 1-500 Mbit
    }

    struct Physical80211
    {
        public NetworkType type;
        public Int64 payloadBits;

        public Physical80211(NetworkType _type, Int64 _payloadBits)
        {
            this.type = _type;
            this.payloadBits = _payloadBits;
        }

        /// <summary>
        /// Number of packets which are arriving per transaction period based on given arrival bits/second
        /// </summary>
        /// <param name="arrivalBps">Incoming bits/second</param>
        /// <param name="payloadBits">Data payload in one packet</param>
        /// <returns>packets/timestep</returns>
        public double PacketArrivalRate(double arrivalBps)
        {
            double packetsPerSecond = arrivalBps / payloadBits;
            double transmitTime = TransactionTime(type, payloadBits) / 1000000;

            return packetsPerSecond * transmitTime;
        }

        public double StepsPerSecond()
        {
            return 1000000.0 / TransactionTime(type, payloadBits);
        }

        /// <summary>
        /// What is the maximum theoretical datarate of a DCF given no other nodes
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <param name="payloadBits">Number of payload bits sent per packet</param>
        /// <param name="wMin">Average number of slots of backoff after transmit</param>
        /// <returns>datarate in bits per second</returns>
        public static double MaxEffectiveDatarate(NetworkType type, Int64 payloadBits, int avgBackoff)
        {
            // Time for a single packet to send in seconds
            double transmitTime = 1000000 * TransactionTime(type, payloadBits);

            // Figure out how long we wait between sending packets
            double backoffTime = avgBackoff * BackoffTime(type, payloadBits);
            double percentTransmitting = transmitTime / (transmitTime + backoffTime);

            // Our effective datarate only concerning payload bits
            return payloadBits * percentTransmitting / transmitTime;
        }

        /// <summary>
        /// What is the maximum theoretical datarate of the fully saturated channel?
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <param name="payloadBits">Number of payload bits sent per packet</param>
        /// <returns>datarate in bits per second</returns>
        public static double MaxChannelDatarate(NetworkType type, Int64 payloadBits)
        {
            return MaxEffectiveDatarate(type, payloadBits, 0);
        }

        /// <summary>
        /// Time it takes to completely send a packet
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <param name="payloadBits">Number of payload bits sent per packet</param>
        /// <returns>time in microseconds</returns>
        public static double TransactionTime(NetworkType type, Int64 payloadBits)
        {
            // Find how long it takes for the payload to send
            double bps = RawDatarate(type);
            double bpus = bps / 1000000;
            double time = payloadBits / bpus;

            // Add in all of the overhead costs
            time += DIFS(type);
            time += OverheadTime(type);
            time += SIFS(type);
            time += ACK(type);

            return time;
        }

        /// <summary>
        /// Time it takes for a single backkoff window
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <param name="payloadBits">Number of payload bits sent per packet</param>
        /// <returns></returns>
        public static double BackoffTime(NetworkType type, Int64 payloadBits)
        {
            return TransactionTime(type, payloadBits);
        }

        public static string Name(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return "802.11 FHSS";
                case NetworkType.DHSS: return "802.11 DHSS";
                case NetworkType.B: return "802.11 B";
                case NetworkType.A: return "802.11 A";
                case NetworkType.G_short: return "802.11 G (short)";
                case NetworkType.G_long: return "802.11 G (long)";
                case NetworkType.N24: return "802.11 N (24)";
                case NetworkType.N50: return "802.11 N (24)";
                case NetworkType.AC: return "802.11 AC";

                default:
                    Debug.Assert(false);
                    return "error";
            }
        }

        /// <summary>
        /// The maximum number of bits transmitted by the network per second in theoretically perfect conditions
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>datarate in bits per second</returns>
        public static double RawDatarate(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return 2000000;
                case NetworkType.DHSS: return 2000000;
                case NetworkType.B: return 11000000;
                case NetworkType.A: return 54000000;
                case NetworkType.G_short: return 54000000;
                case NetworkType.G_long: return 54000000;
                case NetworkType.N24: return 600000000;
                case NetworkType.N50: return 600000000;
                case NetworkType.AC: return 500000000;

                default:
                    Debug.Assert(false);
                    return 0;
            }
        }

        /// <summary>
        /// Extra time spent on overhead bits spent on every payload
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double OverheadTime(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return 200;
                case NetworkType.DHSS: return 200;
                case NetworkType.B: return 192;
                case NetworkType.A: return 20;
                case NetworkType.G_short: return 20;
                case NetworkType.G_long: return 20;
                case NetworkType.N24: return 20;
                case NetworkType.N50: return 20;
                case NetworkType.AC: return 20;

                default:
                    Debug.Assert(false);
                    return 0;
            }
        }

        /// <summary>
        /// Time it takes to send ACK bits
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double ACK(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return 200;
                case NetworkType.DHSS: return 200;
                case NetworkType.B: return 203;
                case NetworkType.A: return 24;
                case NetworkType.G_short: return 24;
                case NetworkType.G_long: return 24;
                case NetworkType.N24: return 24;
                case NetworkType.N50: return 24;
                case NetworkType.AC: return 24;

                default:
                    Debug.Assert(false);
                    return 0;
            }
        }

        /// <summary>
        /// Time each packet has to wait for SIFS
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double SIFS(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return 28;
                case NetworkType.DHSS: return 10;
                case NetworkType.B: return 10;
                case NetworkType.A: return 16;
                case NetworkType.G_short: return 10;
                case NetworkType.G_long: return 10;
                case NetworkType.N24: return 10;
                case NetworkType.N50: return 16;
                case NetworkType.AC: return 16;

                default:
                    Debug.Assert(false);
                    return 0;
            }
        }

        /// <summary>
        /// Time each packet has to wait for Slot
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double SlotTime(NetworkType type)
        {
            switch (type)
            {
                case NetworkType.FHSS: return 50;
                case NetworkType.DHSS: return 20;
                case NetworkType.B: return 20;
                case NetworkType.A: return 9;
                case NetworkType.G_short: return 9;
                case NetworkType.G_long: return 20;
                case NetworkType.N24: return 20;
                case NetworkType.N50: return 9;
                case NetworkType.AC: return 9;

                default:
                    Debug.Assert(false);
                    return 0;
            }
        }

        /// <summary>
        /// Time each packet has to wait for DIFS
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double DIFS(NetworkType type)
        {
            return SIFS(type) + (2 * SlotTime(type));
        }

        /// <summary>
        /// Time each packet has to wait for PIFS
        /// </summary>
        /// <param name="type">802.11 network type</param>
        /// <returns>time in microseconds</returns>
        public static double PIFS(NetworkType type)
        {
            return SIFS(type) + SlotTime(type);
        }
    }
}
