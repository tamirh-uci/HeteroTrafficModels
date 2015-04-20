classdef nodegen_file_download < handle
    properties
        pArrive = 1.0;
        pEnter = 0;
        nMaxPackets = 1;
        nInterarrival = 0;
        wMin = 32;
        wMax = 1024;
        
        name = 'f';
    end
    
    properties (SetAccess = protected)
        nVars;
        varSizes;
        varIndices;
        varCount;
    end
    
    methods
        function nVariations = NumVariations(this)
            pArriveSize = size(this.pArrive, 2);
            pEnterSize = size(this.pEnter, 2);
            nMaxPacketsSize = size(this.nMaxPackets, 2);
            nInterarrivalSize = size(this.nInterarrival, 2);
            wMinSize = size(this.wMin, 2);
            wMaxSize = size(this.wMax, 2);
            
            this.varSizes = [pArriveSize pEnterSize nMaxPacketsSize nInterarrivalSize wMinSize wMaxSize];
            this.nVars = size(this.varSizes,2);
            this.Reset();

            nVariations = prod(this.varSizes);
        end
        
        function Reset(this)
            this.varIndices = ones(1, this.nVars);
            this.varCount = 1;
        end
        
        function AddCurrentVariation(this, simulator)
            pArriveValue = this.pArrive( this.varIndices(1) );
            pEnterValue = this.pEnter( this.varIndices(2) );
            nMaxPacketsValue = this.nMaxPackets( this.varIndices(3) );
            nInterarrivalValue = this.nInterarrival( this.varIndices(4) );
            wMinValue = this.wMin( this.varIndices(5) );
            wMaxValue = this.wMax( this.varIndices(6) );
            
            dcf_model = dcf_markov_model();
            
            [m, ~] = dcf_markov_model.CalculateDimensions(wMinValue, wMaxValue);
            
            dcf_model.m = m;
            dcf_model.wMin = wMinValue;
            dcf_model.nPkt = nMaxPacketsValue;
            dcf_model.nInterarrival = nInterarrivalValue;
            dcf_model.pEnterInterarrival = pEnterValue;
            dcf_model.pRawArrive = pArriveValue;

            nodeName = sprintf('%s%d', this.name, this.varCount);
            simulator.add_plain_node(nodeName, dcf_model);
        end
        
        function IncrementCartesianIndices(this)
            % Increment index of rightmost index
            this.varCount = 1 + this.varCount;
            this.varIndices(this.nVars) = 1 + this.varIndices(this.nVars);
            
            % Propegate any overflow from right to left
            for i = this.nVars:-1:2
                if ( this.varIndices(i) >= this.varSizes(i) )
                    this.varIndices(i) = 1;
                    this.varIndices(i-1) = 1 + this.varIndices(i-1);
                end
            end
        end
    end
end

