classdef nodegen_data_nodes < handle
    % NODEGEN_DATA_NODES Create any number of identical nodes which will
    % use the standard DCF model paramaters
    properties
        params@nodegen_data_params;
        nGenerators = 1;
        name = 'data node';
    end
    
    properties (SetAccess = protected)
        cartesianParams@cartesian_params;
        nodeName;
    end
    
    methods
        function obj = nodegen_data_nodes()
            obj = obj@handle;
            obj.params = nodegen_data_params();
        end
        
        function PreCalc(this)
            this.cartesianParams = cartesian_params();
            this.cartesianParams.values = this.params;
            this.cartesianParams.PreCalc();
        end
        
        function nVariations = NumVariations(this)
            nVariations = this.nGenerators * this.cartesianParams.NumVariations();
        end
        
        function uid = UID(this, current, linePrefix)
            paramsUID = this.cartesianParams.UID(current, linePrefix);
            uid = sprintf('%s\n%snGenerators=%d\n%s', ...
                this.name, linePrefix, this.nGenerators, paramsUID);
        end
        
        function AddCurrentVariation(this, simulator)
            currentValues = this.cartesianParams.CurrentValues();
            
            [m, ~] = dcf_markov_model.CalculateDimensions(currentValues.wMin, currentValues.wMax);
            
            dcf_model = dcf_markov_model();
            dcf_model.m = m;
            dcf_model.wMin = currentValues.wMin;
            dcf_model.nPkt = currentValues.nMaxPackets;
            dcf_model.nInterarrival = currentValues.nInterarrival;
            dcf_model.pEnterInterarrival = currentValues.pEnter;
            dcf_model.pRawArrive = currentValues.pArrive;
            dcf_model.bCurvedInterarrivalChain = true;

            this.nodeName = sprintf('%s (%d)', this.name, this.cartesianParams.nVariations);
            simulator.add_plain_node(this.nodeName, dcf_model);
        end
        
        function Reset(this)
            this.cartesianParams.Reset();
        end
        
        function IncrementCartesianIndices(this)
            this.cartesianParams.IncrementCartesianIndices();
        end
    end
end
