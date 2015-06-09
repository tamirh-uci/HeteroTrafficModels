classdef phys80211 < handle
    methods (Static)
        % calculate how many bits are sent at given datarate over time
        % time = (microseconds)
        % datarate = (bits/second)
        function bits = Bits(time, datarate)
            bits = time * 1000000 / datarate;
        end
        
        % What is the maximum datarate of a DCF given no other nodes
        % type = the type physical type of 802.11 transmission
        % payload = bits per data payload in a frame
        % speed = [0,1] %capacity of max
        % wMin = number of columns/states in the first stage of DCF
        % rate = (bits/second)
        function rate = EffectiveMaxDatarate(type, payload, speed, wMin)
            transmitTime = phys80211.TransactionTime(type, payload, speed);
            backoffTime = (wMin-1)*phys80211.BackoffTime(type);
            percentTransmitting = transmitTime / (transmitTime + backoffTime);
            
            rate = phys80211.RawDatarate(type, speed) * percentTransmitting;
        end
        
        % How long does it take for a full transmission send
        % payload = bits per data payload in a frame = 8*framesize
        % speed = [0,1] %capacity of max
        % unit = (microseconds)
        function time = TransactionTime(type, payload, speed)
            % How long does the payload take in microseconds
            bps = phys80211.RawDatarate(type, speed);
            bpus = bps / 1000000;
            time = payload / bpus;
            
            % Add in all of the other overhead
            time = time + phys80211.DIFS(type);
            time = time + phys80211.OverheadTime(type);
            time = time + phys80211.SIFS(type);
            time = time + phys80211.ACK(type);
        end
        
        % How long does a single backoff state take
        % unit = (microseconds)
        function time = BackoffTime(type)
            time = phys80211.DIFS(type);
        end
        
        % how fast individual transmissions send
        % given the system is working at %capacity of max
        % speed = [0,1] %capacity of max
        % datarate = bits/second
        function datarate = RawDatarate(type, speed)
            [min, max] = phys80211.RawMinMaxDatarate(type);
            datarate = speed * (max-min) + min;
        end
        
        % how fast individual transmissions send 
        % unit = [min, max] (bits/second)
        function [min, max] = RawMinMaxDatarate(type)
            switch(type)
                case phys80211_type.FHSS % 1-2 Mbit
                    min = 1000000;
                    max = 2000000;
                case phys80211_type.DHSS % 1-2 Mbit
                    min = 1000000;
                    max = 2000000;
                case phys80211_type.B % 1-11 Mbit
                    min = 1000000;
                    max = 11000000;
                case phys80211_type.A % 1.5-54 Mbit
                    min = 1500000;
                    max = 54000000;
                case phys80211_type.G_short % 1-54 Mbit
                    min = 1000000;
                    max = 54000000;
                case phys80211_type.G_long % 1-54 Mbit
                    min = 1000000;
                    max = 54000000;
                case phys80211_type.N24 % 1-600 Mbit
                    min = 1000000;
                    max = 600000000;
                case phys80211_type.N50 % 1-600 Mbit
                    min = 1000000;
                    max = 600000000;
                case phys80211_type.AC % 1-500 Mbit
                    min = 1000000;
                    max = 500000000;
            end
        end
        
        % Time added by sending header bits overhead with each payload
        % unit = (microseconds)
        function time = OverheadTime(type)
           switch(type)
                case phys80211_type.FHSS
                    time = 200;
                case phys80211_type.DHSS
                    time = 200;
                case phys80211_type.B
                    time = 192;
                case phys80211_type.A
                    time = 20;
                case phys80211_type.G_short
                    time = 20;
                case phys80211_type.G_long
                    time = 20;
                case phys80211_type.N24
                    time = 20;
                case phys80211_type.N50
                    time = 20;
                case phys80211_type.AC
                    time = 20;
            end 
        end
        
        % time it takes for physical ACK
        % unit = (microseconds)
        function ack = ACK(type)
            switch(type)
                case phys80211_type.FHSS
                    ack = 200;
                case phys80211_type.DHSS
                    ack = 200;
                case phys80211_type.B
                    ack = 203;
                case phys80211_type.A
                    ack = 24;
                case phys80211_type.G_short
                    ack = 24;
                case phys80211_type.G_long
                    ack = 24;
                case phys80211_type.N24
                    ack = 24;
                case phys80211_type.N50
                    ack = 24;
                case phys80211_type.AC
                    ack = 24;
            end
        end
        
        % unit = (microseconds)
        function sifs = SIFS(type)
            switch(type)
                case phys80211_type.FHSS
                    sifs = 28;
                case phys80211_type.DHSS
                    sifs = 10;
                case phys80211_type.B
                    sifs = 10;
                case phys80211_type.A
                    sifs = 16;
                case phys80211_type.G_short
                    sifs = 10;
                case phys80211_type.G_long
                    sifs = 10;
                case phys80211_type.N24
                    sifs = 10;
                case phys80211_type.N50
                    sifs = 16;
                case phys80211_type.AC
                    sifs = 16;
            end
        end
    
        % unit = (microseconds)
        function slotTime = SlotTime(type)
            switch(type)
                case phys80211_type.FHSS
                    slotTime = 50;
                case phys80211_type.DHSS
                    slotTime = 20;
                case phys80211_type.B
                    slotTime = 20;
                case phys80211_type.A
                    slotTime = 9;
                case phys80211_type.G_short
                    slotTime = 9;
                case phys80211_type.G_long
                    slotTime = 20;
                case phys80211_type.N24_short
                    slotTime = 9;
                case phys80211_type.N24_long
                    slotTime = 20;
                case phys80211_type.N50
                    slotTime = 9;
                case phys80211_type.AC
                    slotTime = 9;
            end
        end
        
        % unit = (microseconds)
        function difs = DIFS(type)
            difs = phys80211.SIFS(type) + ( 2*phys80211.SlotTime(type) );
        end
        
        % unit = (microseconds)
        function pifs = PIFS(type)
            pifs = phys80211.SIFS(type) + phys80211.SlotTime(type);
        end
    end % methods (Static)
end % classdef phys80211
