classdef Item < handle & matlab.mixin.CustomDisplay
    
    %% PROPERTIES
    properties (SetAccess = public)
        id;           % ID of this item
        info;         % Struct containing info about this item
    end
    
    %% HIDDEN PROPERTIES
    
    properties (Hidden, Access = protected)
        manifest; % Handle to pertinent manifest containing all available Items of this class
    end
    
    properties (SetAccess = immutable, GetAccess = protected)
        DATASET (1,1) bot.item.internal.enum.Dataset
    end

    properties (Abstract, Constant, Access = protected)
        DATASET_TYPE (1,1) bot.item.internal.enum.DatasetType
        ITEM_TYPE (1,1) bot.item.internal.enum.ItemType
    end
    
    properties (Abstract, Hidden)
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
                itemIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec};
            end
            
            % No Input Argument Constructor Requirement
            if nargin == 0 
                return;
            end
            
            % Handle case of ID array
            item_type = obj(1).ITEM_TYPE;
            
            if ~istable(itemIDSpec) && numel(itemIDSpec) > 1
                for idx = 1:numel(itemIDSpec)
                   getItemFcn = str2func( sprintf("bot.get%ss", string(item_type)) ); %i.e @bot.getSessions
                   obj(idx) = getItemFcn(itemIDSpec(idx)); %#ok<AGROW>
                end
                return;
            elseif istable(itemIDSpec) && size(itemIDSpec, 1) > 1
                for idx = 1:size(itemIDSpec, 1)
                   getItemFcn = str2func( sprintf("bot.get%ss", string(item_type)) ); %i.e @bot.getSessions
                   obj(idx) = getItemFcn(itemIDSpec(idx, :)); %#ok<AGROW>
                end
                return;                
            end

            % Assign the dataset (name) enumeration
            if istable(itemIDSpec)
                obj.DATASET = itemIDSpec.Properties.CustomProperties.DatasetName;
            else
                obj.DATASET = obj.resolveDatasetName(itemIDSpec);
            end

            obj.manifest = bot.item.internal.Manifest.instance(...
                obj.DATASET_TYPE, obj.DATASET);

            % Identify the manifest table row(s) associated to itemIDSpec
            if istable(itemIDSpec)                
                manifestTableRow = itemIDSpec;
            elseif isnumeric(itemIDSpec)
                manifestTableRow = obj.findManifestTableRow(itemIDSpec);
            else
                assert(false);
            end
            
            assert(~isempty(manifestTableRow), "BOT:Item:idNotFound", ...
                "Specified numeric ID not found within manifest(s) of all available Items of class %s", mfilename('class'));
            
            % - Assign the table data to the metadata structure
            obj.info = table2struct(manifestTableRow);
            obj.id = obj.info.id;                                              
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
    
    methods (Access = protected) % Subclasses may override
        function datasetName = resolveDatasetName(obj, itemId)
            datasetName = ...
                bot.internal.util.resolveDataset(...
                    itemId, obj.DATASET_TYPE, obj.ITEM_TYPE);
        end

        function tableRow = findManifestTableRow(obj, itemId)
            % Ensure ID is correct type
            itemId = uint32(round(itemId));
            
            manifestTable = obj.manifest.getItemTable(obj.ITEM_TYPE);
            matchingRow = manifestTable.id == itemId;
            tableRow = manifestTable(matchingRow, :);
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
            arr_size = size(obj);
            size_str = sprintf("%d×", arr_size(1:end-1)) + sprintf("%d", arr_size(end));

            class_name = strsplit(class(obj), '.');
            class_name = class_name{end};
            class_name_part = sprintf('<a href="matlab:helpPopup %s">%s</a>', class(obj), class_name);

            fprintf("   %s %s array\n", size_str, class_name_part);
            
            ids_part = "[" + sprintf('%d, ', [obj(1:end-1).id]) + sprintf('%d]', obj(end).id);

            fprintf('     ids: %s\n', ids_part);
        end
    end

    
    %% HIDDEN METHODS - STATIC
    
    methods (Hidden, Static)
        function  mustBeItemIDSpec(val)
            %MUSTBEITEMIDSPEC Validation function for items specified to BOT item factory functions for item object array construction
                       
            if isempty(val); return; end

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