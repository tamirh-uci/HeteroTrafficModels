classdef phys80211_type < int32
    % Type of physical standard for radio transmissions
    % Determines SIFS/DIFS/Transmission Rate
    enumeration
        Null(0)
        FHSS(1)
        DHSS(2)
        B(3)
        A(4)
        G_short(5)
        G_long(6)
        N24_short(7)
        N24_long(8)
        N50(9)
        AC(10)
    end
end
