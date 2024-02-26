classdef OnDemandProperty < matlab.mixin.CustomCompactDisplayProvider
% OnDemandProperty - Represents an on-demand property with specific data characteristics.
%
%   An instance of this class encapsulates information about an on-demand 
%   property for an NWB file, including its neuroDataType, dataSize, 
%   dataType, and on-demand state.

%   Question: 
%       Save data value on this object and use this class instead of the
%       OnDemandProps mixin?

    properties %(Access = {?bot.internal.behavior.LinkedFile, ?bot.internal.OnDemandProperty})
        DataSize double                       % Size of data (e.g., [256 256] for an image).
        DataType (1,1) string = missing       % Type of data (e.g., 'uint8').
        NeuroDataType (1,1) string = missing  % Name of NWB Neurodata type
        OnDemandState (1,1) string = missing  % Todo: bot.item.internal.enum.OnDemandState
    end

    properties (Access = private)
        DataSizeImmutable = []
        DataTypeImmutable = ''
    end

    properties (Access = private)
        DataAndClassRepresentation
    end
    
    methods
        function obj = OnDemandProperty(dataSize, dataType, onDemandState, neuroDataType)
        % OnDemandProperty Constructor for the OnDemandProperty class.
        %
        %   Syntax:
        %       obj = OnDemandProperty(dataSize, dataType, onDemandState, neuroDataType)
        %
        %   Input Arguments:
        %       - dataSize      : Size of the data (e.g., [256 256] for an image).
        %       - dataType      : Type of the data (e.g., 'uint8').
        %       - onDemandState : On-demand state indicating if the data is available.
        %       - neuroDataType : Name of NWB neurodata type.

            arguments
                dataSize double = []                  % Size of data (e.g., [256 256] for an image).
                dataType (1,1) string = missing       % Type of data (e.g., 'uint8').
                onDemandState (1,1) string = missing  % Todo: bot.item.internal.enum.OnDemandState
                neuroDataType (1,1) string = missing  % Name of NWB Neurodata type
            end

            obj.DataSize = dataSize;
            obj.DataType = dataType;
            obj.OnDemandState = onDemandState;
            obj.NeuroDataType = neuroDataType;

            if ~isempty(dataSize)
                obj.DataSizeImmutable = dataSize;
            end
            if ~isempty(dataType) && ~ismissing(dataType) && dataType ~= ""
                obj.DataTypeImmutable = dataType;
            end
        end
    end

    methods 
        function obj = markComputationRequired(obj)
            obj.OnDemandState = 'computation required';
        end

        function obj = updateFromData(obj, data)

            % Update immutable properties if they were assigned (data 
            % should be ground truth)
            if ~isempty(obj.DataSizeImmutable)
                obj.DataSizeImmutable = size(data);
            end
            if ~isempty(obj.DataTypeImmutable)
                obj.DataTypeImmutable = class(data);
            end

            obj.DataSize = size(data);
            obj.DataType = class(data);
            obj.OnDemandState = 'in-memory';
        end
    end
    
    methods 
        function obj = set.DataSize(obj, newValue)
            if isequal( obj.DataSize, newValue )
                return
            end

            if ~obj.assertSetDataSizeAllowed(newValue)
                return
            end

            % try
            %     obj.assertSetDataSizeAllowed(newValue);
            % catch ME
            %     warning(ME.message); return
            % end

            newValue = obj.updateFromImmutableSize(newValue);
            obj.DataSize = newValue;
            obj = obj.updateDataAndClassRepresentation();
        end

        function obj = set.DataType(obj, newValue)
            if newValue == ""; newValue = missing; end
            if ~obj.assertSetDataTypeAllowed(newValue)
                %warning(ME.message); 
                return
            end
            obj.DataType = newValue;
            obj = obj.updateDataAndClassRepresentation();
        end

        function obj = set.OnDemandState(obj, newValue)
            obj.OnDemandState = newValue;
        end
    end

    methods (Hidden) % % CustomCompactDisplayProvider - Method implementation
        function rep = compactRepresentationForSingleLine(obj, displayConfiguration, width)
            
            import matlab.display.PlainTextRepresentation

            if nargin < 2
                displayConfiguration = matlab.display.DisplayConfiguration();
            end
            
            if isempty(obj)
                rep = matlab.display.PlainTextRepresentation(obj, "unknown", ...
                    displayConfiguration, 'Annotation',  "download required");
                return
            end

            annotation = obj.OnDemandState;
            numObjects = numel(obj);

            dataRepresentation = obj.DataAndClassRepresentation;
            % Alternative to default annotation mode:
            dataRepresentation = sprintf('%-25s (%s)', dataRepresentation, annotation);
            if numObjects == 1
                rep = PlainTextRepresentation(obj, dataRepresentation, ...
                    displayConfiguration);%, 'Annotation', annotation);
            else
                error('Non scalar on-demand property not supported')
            end
        end
    end

    methods (Access = private)
        function obj = updateDataAndClassRepresentation(obj)
        % updateDataAndClassRepresentation - Updates property value
        
            if isempty(obj.DataSize) || ismissing(obj.DataType)
                dataRepresentation = '<unknown>';
            else
                sizeStr = string(obj.DataSize); 
                if any(ismissing(sizeStr))
                    sizeStr = fillmissing(sizeStr, 'constant', "?");
                end
                sizeStr = strjoin(sizeStr, 'x');
                classStr = obj.DataType;
                dataRepresentation = sprintf('[%s %s]', sizeStr, classStr);
            end
            obj.DataAndClassRepresentation = dataRepresentation;
        end

        function newSize = updateFromImmutableSize(obj, newSize)
            if ~isempty(obj.DataSizeImmutable)
                IND = ~isnan(obj.DataSizeImmutable);
                if ~all(obj.DataSizeImmutable(IND) == newSize(IND))
                    newSize(IND) = obj.DataSizeImmutable(IND);
                    if numel(newSize) > numel(obj.DataSizeImmutable)
                        newSize = newSize(1:numel(obj.DataSizeImmutable));
                    end
                end
            end
        end

        function tf = assertSetDataSizeAllowed(obj, newValue)
            tf = true;
            if ~isempty(obj.DataSizeImmutable)
                if ~any( isnan(obj.DataSizeImmutable) )
                    if ~isequal(obj.DataSizeImmutable, newValue)
                        tf = false;
                        %error('Can not change size of OnDemandProperty because it''s size is immutable')
                    else
                        tf = true;
                    end
                end
            end
        end

        function tf = assertSetDataTypeAllowed(obj, newType)
            tf = true;
            if ~isempty(obj.DataTypeImmutable)
                if ~strcmp(obj.DataTypeImmutable, newType)
                    tf = false;
                    %error('Can not change type of OnDemandProperty because it''s type is immutable')
                end
            end
        end
    end
end
