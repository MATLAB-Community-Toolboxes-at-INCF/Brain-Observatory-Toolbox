classdef OnDemandProperty < matlab.mixin.CustomCompactDisplayProvider & handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        DataSize
        DataType
        OnDemandState
    end

    properties (Access = private)
        DisplayString
    end
    
    methods
        function obj = OnDemandProperty(dataSize, dataType, state)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.DataSize = dataSize;
            obj.DataType = dataType;
            obj.OnDemandState = state;

            obj.updateDisplayString()
        end
    end
    
    methods (Hidden) % % CustomCompactDisplayProvider - Method implementation
        
        function rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
   
            if nargin < 2
                displayConfiguration = matlab.display.DisplayConfiguration();
            end
            
            if isempty(obj)
                rep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', "download reqiured", 'Annotation',  "download required");
                %rep = compactRepresentationForSingleLine@matlab.mixin.CustomCompactDisplayProvider(obj,displayConfiguration,80);
                return
            end

            annotation = obj.OnDemandState;
            numObjects = numel(obj);
            if numObjects == 1
                rep = fullDataRepresentation(obj, displayConfiguration, 'StringArray', obj.DisplayString, 'Annotation', annotation);
            else
                error('Non scalar on-demand property not supported')
            end
        end
    end

    methods 
        function str = getDisplayString(obj)
            if isempty(obj.DisplayString)
                obj.DisplayString = obj.updateDisplayString();
            end

            str = obj.DisplayString;
        end
    end

    methods (Access = private)
        function updateDisplayString(obj)
            sizeStr = strjoin(string(obj.DataSize ), 'x');
            classStr = obj.DataType;
            obj.DisplayString = sprintf('%s %s', sizeStr, classStr);
        end
    end

end
