namespace WifiInterferenceSim.DCF
{
    enum DCFStateType
    {
        Null = 0,

        Interarrival,
        BufferEmpty,
        Transmit,
        Backoff,
        Sleep,
    }

    struct DCFState
    {
        // What we're currently doing
        public DCFStateType type;

        public int payloadTimer;

        public int interarrivalTimer;

        public int backoffStage;
        public int backoffTimer;

        public int sleepStage;
        public int sleepTimer;
    }
}
