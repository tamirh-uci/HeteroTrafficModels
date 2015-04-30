classdef cartesian_params < handle
    %CARTESIAN_PARAMS Summary of this class goes here
    %   Detailed explanation goes here
    properties
        values;
        
        paramNames;
        nParams;
        paramSizes;
        currIndices;
        nVariations;
    end
    
    methods
        function obj = cartesian_params()
            obj = obj@handle;
        end
        
        function PreCalc(this)
            this.paramNames = properties( this.values );
            this.nParams = size( this.paramNames, 1 );
            this.paramSizes = zeros(1, this.nParams);
            this.Reset();
            
            for i = 1:this.nParams
                paramName = this.paramNames{i};
                param = this.values.(paramName);
                this.paramSizes(i) = size(param, 2);
            end
        end
        
        function Reset(this)
            this.currIndices = ones(1, this.nParams);
        end
        
        function nVars = NumVariations(this)
            nVars = prod( this.paramSizes );
            this.nVariations = nVars;
        end
        
        function current = CurrentValues(this)
            current = struct();
            
            for i = 1:this.nParams
                paramName = this.paramNames{i};
                param = this.values.(paramName);
                currentIndex = this.currIndices(i);
                
                if (currentIndex <= size(param,2))
                    current.(paramName) = param(currentIndex);
                else
                    current.(paramName) = 'INVALID';
                end
            end
        end
        
        function IncrementCartesianIndices(this)
            % Increment index of rightmost index
            this.currIndices(this.nParams) = 1 + this.currIndices(this.nParams);
            
            % Propegate any overflow from right to left
            for i = this.nParams:-1:2
                if ( this.currIndices(i) > this.paramSizes(i) )
                    this.currIndices(i) = 1;
                    this.currIndices(i-1) = 1 + this.currIndices(i-1);
                end
            end
        end
        
        function uid = UID(this, current, linePrefix)
            if (current)
                uidValues = this.CurrentValues();
            else
                uidValues = this.values;
            end
            
            uid = '';
            for i = 1:this.nParams
                paramName = this.paramNames{i};
                param = uidValues.(paramName);
                uid = sprintf('%s%s%s=%s\n', uid, linePrefix, paramName, mat2str(param));
            end
        end
    end
end

