classdef Item < handle & matlab.mixin.CustomDisplay
    
% Changes from bot.item.internal.abstract.Item:
% - Simplified constructor
% - Added method for assigning manifest
% - Changed display of non-scalar objects

    %% PROPERTIES
    properties (SetAccess = public)
        id;           % ID of this item
        info;         % Struct containing info about this item
    end
    
    %% HIDDEN PROPERTIES
    
    properties (Hidden, Access = protected)
        manifest; % Handle to pertinent manifest containing all available Items of this class
    end
    
    properties (Abstract, Hidden, Access = public, Constant)
        DATASET (1,1) bot.item.internal.enum.Dataset
        DATASET_TYPE(1,1) bot.item.internal.enum.DatasetType
        ITEM_TYPE(1,1) bot.item.internal.enum.ItemType
    end
    
    properties (Abstract, SetAccess = protected, Hidden)
        CORE_PROPERTIES (1,:) string;
        LINKED_ITEM_PROPERTIES (1,:) string;
    end
    
    properties (Hidden, SetAccess=protected, GetAccess = protected)
        ITEM_INFO_VALUE_PROPERTIES (1,:) string = string.empty(1,0);
        LINKED_ITEM_VALUE_PROPERTIES (1,:) string = string.empty(1,0);
    end

    %% CONSTRUCTOR
    
    methods
        
        function obj = Item(itemIDSpec)
            
            arguments
                itemIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec} = [];                
            end
            
            % No Input Argument Constructor Requirement
            if nargin == 0 || isempty(itemIDSpec)
                return;
            end
            
            numItems = countItems(itemIDSpec); % Local function;

            if numItems > 1
                itemClass = class(obj);
                obj(numItems) = feval(itemClass);

                for idx = 1:numItems                 
                    if istable(itemIDSpec)
                        obj(idx) = feval(itemClass, itemIDSpec(idx, :));
                    else
                        obj(idx) = feval(itemClass, itemIDSpec(idx));
                    end
                end
                return
            end
            
            obj.assignManifest()
            
            % Identify the manifest table row(s) associated to itemIDSpec
            if istable(itemIDSpec)                
                manifestTableRow = itemIDSpec;
            elseif isnumeric(itemIDSpec)
                itemIDSpec = uint32(round(itemIDSpec));
                
                manifestTablePrefix = string(obj.DATASET_TYPE);
                manifestTableSuffix = string(obj.ITEM_TYPE) + "s";
                
                manifestTable = obj.manifest.(manifestTablePrefix + manifestTableSuffix);
                             
                matchingRow = manifestTable.id == itemIDSpec;
                manifestTableRow = manifestTable(matchingRow, :);                          
            else
                assert(false);
            end
            
            assert(~isempty(manifestTableRow),"BOT:Item:idNotFound","Specified numeric ID not found within manifest(s) of all available Items of class %s", mfilename('class'));
            
            % - Assign the table data to the metadata structure
            obj.info = table2struct(manifestTableRow);
            obj.id = obj.info.id;

            obj.initLinkedItems()
        end
    end

    methods (Access = protected)
        function initLinkedItems(obj)
            % Subclasses may implement
        end
    end

    methods (Access = private)
        
        function assignManifest(obj)
        % assignManifest - Assign item manifest for specified object.  
            datasetName = obj.DATASET;
            datasetType = obj.DATASET_TYPE;

            manifestClassName = sprintf("%s%sManifest", datasetName, datasetType);
            fullManifestClassName = sprintf('bot.internal.metadata.%s.instance', manifestClassName);

            obj.manifest = feval(fullManifestClassName);                  
        end
    end
    
    methods
        function datasetType = getDatasetType(obj)
            datasetType = char(obj.DATASET_TYPE);
        end

        function datasetName = getDatasetName(obj)
            datasetName = char(obj.DATASET);
        end
    end
    
    
    %% HIDDEN METHODS  SUPERCLASS IMPLEMENTATION (matlab.mixin.CustomDisplay)
    methods (Hidden, Access = protected)

        function str = getHeader(obj)
            str = getHeader@matlab.mixin.CustomDisplay(obj);
            str = replace(str, 'with properties', sprintf('(%s) with properties', obj.getDatasetName()));
        end

        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                
                % Core properties
                mc = metaclass(obj);
                dcs = [mc.PropertyList.DefiningClass];
                corePropsLocal = findobj(mc.PropertyList(string({dcs.Name}) == mfilename('class')),'GetAccess','public','-and','Hidden',false);
                groups(1) = matlab.mixin.util.PropertyGroup([corePropsLocal.Name obj.CORE_PROPERTIES]);
                
                % Derived properties from Info
                if ~isempty(obj.ITEM_INFO_VALUE_PROPERTIES)
                    groups(end+1) = matlab.mixin.util.PropertyGroup(obj.ITEM_INFO_VALUE_PROPERTIES, 'Info Derived Values');
                end
                
                % Linked item tables
                groups(end+1) = matlab.mixin.util.PropertyGroup(obj.LINKED_ITEM_PROPERTIES, 'Linked Items');
                
                % Derived properties from Linked Item Tables
                if ~isempty(obj.LINKED_ITEM_VALUE_PROPERTIES)
                    groups(end+1) = matlab.mixin.util.PropertyGroup(obj.LINKED_ITEM_VALUE_PROPERTIES, 'Linked Item Derived Values');
                end
            end
        end
        
        function displayNonScalarObject(obj)
            %TODO: Refactor to use String, if keeping this nonscalar display format
            
            % - Only display limited data
            % arr_size = size(obj);
            % size_str = sprintf("%d×", arr_size(1:end-1)) + sprintf("%d", arr_size(end));
            % 
            % class_name = strsplit(class(obj), '.');
            % class_name = class_name{end};
            % class_name_part = sprintf('<a href="matlab:helpPopup %s">%s</a>', class(obj), class_name);
            % 
            % fprintf("   %s %s array\n", size_str, class_name_part);
            % 
            % ids_part = "[" + sprintf('%d, ', [obj(1:end-1).id]) + sprintf('%d]', obj(end).id);
            % 
            % fprintf('     ids: %s\n', ids_part);

            numObjects = numel(obj);
            stringRep = cell(1, numObjects);

            for i = 1:numObjects
                status = obj(i).getLinkedFilesStatus();
                stringRep{i} = sprintf('    Experiment (%d) of type "%s" [%s]', obj(i).id, obj(i).SessionType, status);
            end

            str = obj.getHeader;
            str = strrep(str, ' with properties:', '');
            disp(str)
            fprintf( '%s\n\n', strjoin(stringRep, '    \n') );
        end
    end

    
    %% HIDDEN METHODS - STATIC
    
    methods (Hidden, Static)        
        function  mustBeItemIDSpec(val)
            %MUSTBEITEMIDSPEC Validation function for items specified to BOT item factory functions for item object array construction
                        
            eidTypePrefix = "mustBeBOTItemId:";
            eidTypeSuffix = "";
            msgType = "";
            
            if istable(val)
                
                eidTypeSuffix = "invalidItemTable";
                
                if ~any(ismember(val.Properties.VariableNames, 'id')) && ~any(ismember(val.Properties.VariableNames, 'behavior_session_id'))
                    msgType = "Table supplied not recognized as a valid BOT Item information table";
                end
                
%                 if height(val) ~= 1
%                     msgType = "Table supplied must have one and only one row";
%                 end                                               
                
            elseif ~isnumeric(val) || ~isvector(val) || ~all(isfinite(val)) || any(val<=0)
                eidTypeSuffix = "invalidItemIDs";
                msgType = "Must specify BOT item object(s) to create with either a numeric vector of valid ID values or a valid Item information table";
            elseif ~isinteger(val) && ~all(round(val)==val)
                eidTypeSuffix = "invalidItemIDs";
                msgType = "Must specify BOT item object(s) to create with either a numeric vector of valid ID values or a valid Item information table";
            end
            
            
            % Throw error
            if strlength(msgType) > 0
                throwAsCaller(MException(eidTypePrefix + eidTypeSuffix,msgType));
            end
        end         
    
        function tf = isItemIDSpecScalar(itemIDSpec)
            if istable(itemIDSpec)
                tf = height(itemIDSpec) == 1;
            else
                tf = numel(itemIDSpec) == 1;
            end
        end
    end
    
    %    methods (Static)
    %
    %        function tbl = removeUnusedCategories(tbl)
    %        % TODO: Consider if it's a desired behavior for category lists to be narrowed for linked item tables? Or better to retain the "global" view of all available in the container session?
    %
    %            if isempty(tbl)
    %                return;
    %            end
    %
    %            varTypes = string(cellfun(@class,table2cell(tbl(1,:)),'UniformOutput',false));
    %            varNames = string(tbl.Properties.VariableNames);
    %
    %            catVarIdxs = find(varTypes.matches("categorical"));
    %
    %            for idx = catVarIdxs
    %                varName = varNames(idx);
    %
    %                validCats = unique(tbl.(varName));
    %                allCats = categories(tbl{1,varName});
    %                invalidCats = setdiff(allCats,validCats);
    %
    %                tbl.(varName) = removecats(tbl.(varName),invalidCats);
    %
    %            end
    %
    %        end
    %    end
    
end

function nItems = countItems(itemIDSpec)
    if istable(itemIDSpec) 
        nItems = height(itemIDSpec);
    else
        nItems = numel(itemIDSpec);
    end
end