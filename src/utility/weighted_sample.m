classdef weighted_sample < handle
    %WEIGHTED_SAMPLE replacement for randsample
    % Precompute an array for quick randsample lookups
    
    properties
        %original values
        %pi;
        
        % Cumulative probabilities (slower than the direct index)
        % piCumulative;
        
        % Directly index into value with given precision
        piIndexer;
        piPrecision;
    end
    
    methods
        % A much faster way to sample through weighted probabilities
        % Choose a precision, and pre-divide a fixed size array
        % Indexing into this array randomly will be a weighted probability
        % of getting any of the values
        % Example: weighted probabilities = [0.25 0.25 0.5], precision = 8
        % Resulting indexing array = [1 1 2 2 3 3 3 3]
        function obj = weighted_sample(precision, piIn)
            obj = obj@handle();
            obj.piPrecision = precision;
            
            % Loop through our probabilities, mapping them onto indices
            % Ignore 0 probability indicies
            lastValidIndex = 1;
            maxIndex = size(piIn,2);
            
            minP = min(piIn(piIn>0));
            minPrecision = 2 * ceil( 1.0 / minP );
            if (minPrecision > precision)
                obj.piPrecision = minPrecision;
            end
            obj.piIndexer = zeros(1, obj.piPrecision);
            
            indexerStart = 0;
            indexerEnd = 1;
            for i=1:maxIndex
                currentProbability = piIn(i);
                if (currentProbability > 0)
                    indexerEnd = floor( 0.5 + indexerStart + (currentProbability * obj.piPrecision) );
                    
                    % For very small probabilities we're restricted to
                    % 1/PRECISION chance
                    if (indexerStart==indexerEnd)
                        %fprintf('WARN: Probability %f rounded up to %f\n', currentProbability, 1.0/PRECISION);
                        indexerEnd = 1 + indexerStart;
                    end
                    
                    obj.piIndexer(indexerStart+1:indexerEnd) = i;
                    indexerStart = indexerEnd;
                    lastValidIndex = i;
                end
            end
            
            % With leftover indices, map them onto the last valid index
            obj.piIndexer(indexerEnd:obj.piPrecision) = lastValidIndex;
        end
        
        function index = sample(this)
            index = this.piIndexer(randi(this.piPrecision));
        end
    end
end
