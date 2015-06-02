classdef nodegen_mpeg4_nodes < handle
    % NODEGEN_MPEG4_NODES Create any number of identical nodes which will
    % use the standard DCF model paramaters seondary MPEG4 params
    properties
        params@nodegen_mpeg4_params;
        nGenerators = 1;
        name = 'data node';
    end
    
    properties (SetAccess = protected)
        cartesianParams@cartesian_params;
        nodeName;
    end
    
    methods
        function obj = nodegen_mpeg4_nodes()
            obj = obj@handle;
            obj.params = nodegen_mpeg4_params();
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
            
            % fixed for multimedia nodes
            dcf_model.bFixedInterarrivalChain = true;
            dcf_model.bFixedPacketchain = true;
            dcf_model.nPkt = 1;
            dcf_model.pEnterInterarrival = 1;
            
            % user changable values
            dcf_model.wMin = currentValues.wMin;
            dcf_model.pRawArrive = currentValues.pArrive;
            dcf_model.CalculateInterarrival(currentValues.bps, simulator.physical_type, simulator.physical_payload, simulator.physical_speed);

            % MPEG4 stream variables
            mpeg4_model = mpeg4_frame_model();
            mpeg4_model.gopAnchorFrameDistance = currentValues.gopAnchorFrameDistance;
            mpeg4_model.gopFullFrameDistance = currentValues.gopFullFrameDistance;
            mpeg4_model.bps = currentValues.bps;
            mpeg4_model.physical_type = simulator.physical_type;
            mpeg4_model.physical_payload = simulator.physical_payload;
            mpeg4_model.physical_speed = simulator.physical_speed;
            
            this.nodeName = sprintf('%s (%d)', this.name, this.cartesianParams.nVariations);
            simulator.add_video_node(this.nodeName, dcf_model, mpeg4_model);
        end
        
        function Reset(this)
            this.cartesianParams.Reset();
        end
        
        function IncrementCartesianIndices(this)
            this.cartesianParams.IncrementCartesianIndices();
        end
    end
end
