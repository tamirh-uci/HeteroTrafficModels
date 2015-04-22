classdef nodegen_mpeg4_nodes < handle
    % NODEGEN_MPEG4_NODES Create any number of identical nodes which will
    % use the standard DCF model paramaters seondary MPEG4 params
    properties
        pArrive = 1.0;
        wMin = 32;
        wMax = 64;
        
        bps = 1000000 * 4;
        gopAnchorFrameDistance = 3;
        gopFullFrameDistance = 12;
        
        nGenerators = 1;
        name = 'mpeg4 node';
    end
    
    properties (SetAccess = protected)
        nVars;
        varSizes;
        varIndices;
        varCount;
        
        nodeName;
    end
    
    methods
        function obj = nodegen_mpeg4_nodes()
            obj = obj@handle;
        end
        
        function nVariations = NumVariations(this)
            pArriveSize = size(this.pArrive, 2);
            wMinSize = size(this.wMin, 2);
            wMaxSize = size(this.wMax, 2);
            bpsSize = size(this.bps, 2);
            gopAnchorFrameDistanceSize = size(this.gopAnchorFrameDistance, 2);
            gopFullFrameDistanceSize = size(this.gopFullFrameDistance, 2);
            
            this.varSizes = [pArriveSize wMinSize wMaxSize bpsSize gopAnchorFrameDistanceSize gopFullFrameDistanceSize];
            this.nVars = size(this.varSizes,2);
            this.Reset();

            nVariations = this.nGenerators * prod(this.varSizes);
        end
        
        function Reset(this)
            this.varIndices = ones(1, this.nVars);
            this.varCount = 1;
        end
        
        function uid = UID(this)
            arrayStrings = sprintf(...
                '  pArrive=%s\n  wMin=%s\n  wMax%s\n  bps=%s\n  gopAnchorFrameDistance=%s\n  gopFullFrameDistance=%s\n', ...
                mat2str(this.pArrive), mat2str(this.wMin), ...
                mat2str(this.wMax), mat2str(this.bps), ...
                mat2str(this.gopAnchorFrameDistance), mat2str(this.gopFullFrameDistance)...
                );
            
            uid = sprintf('%s\n  nGenerators=%d\n%s', this.name, this.nGenerators, arrayStrings);
        end
        
        function AddCurrentVariation(this, simulator)
            pArriveValue = this.pArrive( this.varIndices(1) );
            wMinValue = this.wMin( this.varIndices(2) );
            wMaxValue = this.wMax( this.varIndices(3) );
            bpsValue = this.bps( this.varIndices(4) );
            gopAnchorFrameDistanceValue = this.gopAnchorFrameDistance( this.varIndices(5) );
            gopFullFrameDistanceValue = this.gopFullFrameDistance( this.varIndices(6) );
            
            [m, ~] = dcf_markov_model.CalculateDimensions(wMinValue, wMaxValue);
        
            % These variables are fixed for multimedia nodes
            dcf_model = dcf_markov_model();
            dcf_model.bFixedInterarrivalChain = true;
            dcf_model.bFixedPacketchain = true;
            dcf_model.nPkt = 1;
            dcf_model.pEnterInterarrival = 1;
            
            % User changable variables
            dcf_model.m = m;
            dcf_model.wMin = wMinValue;
            dcf_model.pRawArrive = pArriveValue;
            dcf_model.CalculateInterarrival(bpsValue, simulator.physical_type, simulator.physical_payload, simulator.physical_speed);
            
            % MPEG4 stream variables
            mpeg4_model = mpeg4_frame_model();
            mpeg4_model.gopAnchorFrameDistance = gopAnchorFrameDistanceValue;
            mpeg4_model.gopFullFrameDistance = gopFullFrameDistanceValue;
            mpeg4_model.bps = bpsValue;
            mpeg4_model.physical_type = simulator.physical_type;
            mpeg4_model.physical_payload = simulator.physical_payload;
            mpeg4_model.physical_speed = simulator.physical_speed;
            
            this.nodeName = sprintf('%s (%d)', this.name, this.varCount);
            simulator.add_video_node(this.nodeName, dcf_model, mpeg4_model);
        end
        
        function IncrementCartesianIndices(this)
            % Increment index of rightmost index
            this.varCount = 1 + this.varCount;
            this.varIndices(this.nVars) = 1 + this.varIndices(this.nVars);
            
            % Propegate any overflow from right to left
            for i = this.nVars:-1:2
                if ( this.varIndices(i) > this.varSizes(i) )
                    this.varIndices(i) = 1;
                    this.varIndices(i-1) = 1 + this.varIndices(i-1);
                end
            end
        end
    end
end
