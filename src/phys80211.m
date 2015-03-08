classdef phys80211 < handle
    methods (Static)
        % calculate how many bits are sent at given datarate over time
        % time = (microseconds)
        % datarate = (bits/second)
        function bits = Bits(time, datarate)
            bits = time * 1000000 / datarate;
        end
        
        % How many bits are sent each time a slot is transmitting
        function bits = BitsPerSlot(type)
            bits = Bits( phys80211.SlotTime(type) * phys80211.RawDatarate(type) );
        end
        
        % What is the maximum datarate of a DCF given no other nodes
        % type = the type physical type of 802.11 transmission
        % wMin = number of columns/states in the first stage of DCF
        % speed = [0,1] %capacity of max
        % rate = (bits/second)
        function rate = MaxSingleNodeDatarate(type, wMin, speed)
            transmitTime = phys80211.SlotTime(type);
            backoffTime = (wMin-1)*phys80211.SIFS(type);
            percentTransmitting = transmitTime / (transmitTime + backoffTime);
            
            rate = phys80211.RawDatarate(type, speed) * percentTransmitting;
        end
        
        % how fast individual transmissions send
        % given the system is working at %capacity of max
        % speed = [0,1] %capacity of max
        function datarate = RawDatarate(type, speed)
            [min, max] = RawMinMaxDatarate(type);
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
                case phys80211_type.G % 1-54 Mbit
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
                case phys80211_type.G
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
