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
            
            % fixed for now
            dcf_model.bFixedInterarrivalChain = currentValues.bFixedInterarrival;
            dcf_model.bFixedPacketchain = false;
            dcf_model.bCurvedInterarrivalChain = true;
            
            % user changable values
            dcf_model.wMin = currentValues.wMin;
            dcf_model.nPkt = currentValues.nMaxPackets;
            dcf_model.pInterarrival = currentValues.pInterarrival;
            dcf_model.pRawArrive = currentValues.pArrive;
            dcf_model.pSleep = currentValues.pSleep;
            dcf_model.nInterarrival = currentValues.nInterarrival;
            
            % Calculate the rest of the params
            bps = dcf_model.CalculateSleep(currentValues.bps, currentValues.nSleep, simulator.physical_type, simulator.physical_payload, simulator.physical_speed);

            this.nodeName = sprintf('%s (%d @%.0fbps)', this.name, this.cartesianParams.nVariations, bps);
            fprintf('Generated data node: %s\n', this.nodeName);
            
            sleepProps = [currentValues.sleepProps1, currentValues.sleepProps2, currentValues.sleepProps3, currentValues.sleepProps4];
            simulator.add_plain_node(this.nodeName, sleepProps, dcf_model);
        end
        
        function Reset(this)
            this.cartesianParams.Reset();
        end
        
        function IncrementCartesianIndices(this)
            this.cartesianParams.IncrementCartesianIndices();
        end
    end
end
