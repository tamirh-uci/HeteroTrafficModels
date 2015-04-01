classdef weighted_sample < handle
    %WEIGHTED_SAMPLE replacement for randsample
    % Precompute an array for quick randsample lookups
    
    properties
        %original values
        %pi;
        
        % Cumulative probabilities (slower than the direct index)
        %piCumulative;
        
        % Directly index into value with given precision
        piIndexer;
        piPrecision;
    end
    
    methods
        function obj = weighted_sample(piIn)
            precision = 10000;
            
            obj = obj@handle();
            %obj.pi = piIn;
            %obj.piCumulative = cumsum(piIn)/sum(piIn);
            obj.piIndexer = zeros(1,precision);
            obj.piPrecision = precision;
            
            indexerStart = 0;
            indexerEnd = 1;
            for i=1:size(piIn,2)
                if (piIn(i) > 0)
                    indexerEnd = floor( indexerStart + piIn(i) * precision );
                    obj.piIndexer(indexerStart+1:indexerEnd) = i;
                    indexerStart = indexerEnd;
                end
            end
            
            %truncated = floor(piIn*precision)/precision;
            %error = abs(piIn - truncated);
            %errorsum = sum(error);

            obj.piIndexer(indexerEnd:size(piIn,2)) = size(piIn,2);
        end
        
        function index = sample(this)
            %index = find( rand <= this.piCumulative, 1 );
            index = this.piIndexer( randi(this.piPrecision) );
        end
    end
end
