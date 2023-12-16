%% CLASS VisualBehaviorOphysManifest
%
% This class can be used to obtain various `tables of items´ from the 
% Visual Behavior 2P dataset [1] obtained with the Allen Brain Observatory 
% platform [2].
%
% Item tables contain overview information about individual items belonging 
% to the dataset and tables for the following item types are available:
%
%       BehaviorSessions   % Behavior only session
%       OphysSessions      % OPhys session 
%       OphysExperiments   % OPhys experiments (single imaging planes)
%       OphysCells         % Detected cell (region of interest)
%   
%
% USAGE:
%
% Construction:
% >> vbom = bot.internal.Manifest.instance('Ophys', 'VisualBehavior')
% >> vbom = bot.internal.metadata.VisualBehaviorOphysManifest.instance()
%
% Get information about all OPhys experimental sessions:
% >> vbom.OphysSessions
% ans =
%        id        behavior_session_id    mouse_id  ...
%    __________    ___________________    ________  ...
%
%     951410079         951520319          457841   ...
%     952430817         952554548          457841   ...
%     ...
%
% Force an update of the manifest representing Allen Brain Observatory 
% dataset contents:
% >> vbom.updateManifest()
%
% Access data from an experimental session:
% >> nSessionID = vbom.OphysSessions(1, 'id');
% >> vbos = bot.getSessions(nSessionID)
% vbos =
%   OphysSession with properties:
% 
%                       id: 951410079
%                     info: [1×1 struct]
%              SessionType: OPHYS_1_images_A
%                       ...
%
% (See documentation for the `bot.behavior.item.OphysSession` class for more information)
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Behavior 2P dataset. 
%       Available from: portal.brain-map.org/explore/circuits/visual-behavior-2p.
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: portal.brain-map.org/explore/circuits

% Todo
%   Include CellIdMappingId?

%% Class definition

classdef VisualBehaviorOphysManifest < bot.item.internal.Manifest

    properties (SetAccess = private, Dependent = true)
        BehaviorSessions   % Table of all Behavior session
        OphysSessions      % Table of all OPhys sessions
        OphysExperiments   % Table of all OPhys experiments
        OphysCells         % Table of all OPhys cells
    end

    properties (Constant, Access = protected, Hidden)
        DATASET_NAME = "VisualBehavior"
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
        ITEM_TYPES = ["BehaviorSession", "OphysSession", "OphysExperiment", "OphysCell"]
        DOWNLOAD_FROM = containers.Map(...
            bot.internal.metadata.VisualBehaviorOphysManifest.ITEM_TYPES, ...
            ["S3", "S3", "S3", "S3"])
    end

    properties (Access = protected)
        FileResource = bot.internal.fileresource.visualbehavior.VBOphysS3Bucket.instance()
    end  

    
    %% Constructor
    methods (Access = private)
        function obj = VisualBehaviorOphysManifest()
            obj@bot.item.internal.Manifest()
            obj.ON_DEMAND_PROPERTIES = obj.ITEM_TYPES + "s";     % Property names are plural
        end
    end
    
    %% Method for interacting with singleton instance
    methods (Static = true)
        function manifest = instance(action)
            % instance Get or clear singleton instance of the OPhys manifest
            %
            %   manifest = bot.internal.metadata.VisualBehaviorOphysManifest.instance()
            %   returns a singleton instance of the VisualBehaviorOphysManifest class
            %        
            %   bot.internal.metadata.VisualBehaviorOphysManifest.instance("clear") will 
            %   clear the singleton instance from memory
            
            arguments
                action (1,1) string {mustBeMember(action, ...
                    ["get", "clear", "reset"])} = "get";
            end
            
            persistent manifestInstance % singleton instance
            
            % - Clear the manifest if requested
            if ismember(action, ["clear", "reset"])
                delete(manifestInstance); manifestInstance = [];
            end

            if ismember(action, ["get", "reset"])
                % - Construct the manifest if singleton instance is not present
                if isempty(manifestInstance)
                    manifestInstance = bot.internal.metadata.VisualBehaviorOphysManifest();
                end

                % - Return the instance
                manifest = manifestInstance; 
            end
        end
    end

    %% Getters for manifest item tables (on-demand properties)
    methods

        function sessionTable = get.BehaviorSessions(obj)
            sessionTable = obj.fetch_cached('BehaviorSessions', ...
                    @(itemType) obj.fetch_item_table('BehaviorSession') );
        end
        
        function sessionTable = get.OphysSessions(obj)
            sessionTable = obj.fetch_cached('OphysSessions', ...
                    @(itemType) obj.fetch_item_table('OphysSession') );
        end

        function experimentTable = get.OphysExperiments(obj)
            experimentTable = obj.fetch_cached('OphysExperiments', ...
                    @(itemType) obj.fetch_item_table('OphysExperiment') );
        end

        function cellTable = get.OphysCells(obj)
            cellTable = obj.fetch_cached('OphysCells', ...
                    @(itemType) obj.fetch_item_table('OphysCell') );
        end

    end

    methods
        function fetchAll(obj)
        %fetchAll Fetches all of the item tables of the manifest
        %
        %   fetchAll(manifest) will fetch all item tables of the concrete
        %   manifest.

            for itemType = obj.ITEM_TYPES
                obj.(itemType+"s");
            end
        end
    end

    %% Low-level getter method for OPhys manifest item tables
    methods (Access = public)

        function itemTable = fetch_item_table(obj, itemType)
        %fetch_item_table Fetch item table (get from cache or download)

            cache_key = obj.getManifestCacheKey(itemType);

            if obj.cache.isObjectInCache(cache_key)
                itemTable = obj.cache.retrieveObject(cache_key);

            else
                itemTable = obj.download_item_table(itemType);
                
                % Process downloaded item table
                fcnName = sprintf('%s.preprocess_%s_table', class(obj), lower(itemType)); % Static method
                itemTable = feval(fcnName, itemTable);
                
                fcnName = sprintf('postprocess_%s_table', lower(itemType)); % Static method
                itemTable = feval(fcnName, obj, itemTable);
                
                obj.cache.insertObject(cache_key, itemTable);
                obj.clearTempTableFromCache(itemType)
            end

            % Apply standardized table display logic
            itemTable = obj.applyUserDisplayLogic(itemTable); 
        end

    end

    methods (Static, Access = protected)
        
        function itemTable = readS3ItemTable(cacheFilePath)
        %readS3ItemTable Read table from file downloaded from S3 bucket
        %
        %   Visual behavior ophys item tables are stored in csv files
            % opts = detectImportOptions(cacheFilePath)
            itemTable = readtable(cacheFilePath, "Delimiter", ',');
        end

    end

    methods(Access=private)
        function ophys_session_table = postprocess_ophyssession_table(obj, ophys_session_table)

            ophys_session_table = fetch_grouped_uniques(ophys_session_table, obj.OphysExperiments, ...
                'id', 'ophys_session_id', 'targeted_structure', 'targeted_structure_acronyms'); 
            %ophys_session_table.targeted_structure_acronyms = cellfun(@(e) strjoin(e,'; '), ophys_session_table.targeted_structure_acronyms, 'UniformOutput', false);
            %ophys_session_table.targeted_structure_acronyms = string(ophys_session_table.targeted_structure_acronyms);
        end
        
        function ophys_experiment_table = postprocess_ophysexperiment_table(obj, ophys_experiment_table)
        end

        function ophys_session_table = postprocess_behaviorsession_table(obj, ophys_session_table)
        end
   
        function ophys_cell_table = postprocess_ophyscell_table(obj, ophys_cell_table)
        end
   
    end

    methods (Static, Access = private) % Postprocess manifest item tables
        function ophys_session_table = preprocess_ophyssession_table(ophys_session_table)
            
            import bot.item.internal.Manifest.recastTableVariables
            ophys_session_table = recastTableVariables(ophys_session_table);

            % Assign the item id.
            ophys_session_table.id = ophys_session_table.ophys_session_id;
        end

        function ophys_experiment_table = preprocess_ophysexperiment_table(ophys_experiment_table)
            import bot.item.internal.Manifest.recastTableVariables
            
            varNamesToInt = {'ophys_experiment_id'};

            ophys_experiment_table = bot.internal.util.castTableVariables(...
                ophys_experiment_table, varNamesToInt, 'uint32');

            ophys_experiment_table = recastTableVariables(ophys_experiment_table);

            % Assign the item id.
            ophys_experiment_table.id = ophys_experiment_table.ophys_experiment_id;
        end
    
        function ophys_session_table = preprocess_behaviorsession_table(ophys_session_table)
            import bot.item.internal.Manifest.recastTableVariables
            
            ophys_session_table.date_of_acquisition = datetime(ophys_session_table.date_of_acquisition, ...
                'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSZZZZZ','TimeZone','UTC');

            ophys_session_table = recastTableVariables(ophys_session_table);
            ophys_session_table.id = ophys_session_table.behavior_session_id;
        end

        function ophys_cell_table = preprocess_ophyscell_table(ophys_cell_table)
            
            import bot.item.internal.Manifest.recastTableVariables
            
            varNamesToInt = {'ophys_experiment_id'};


            ophys_cell_table.id = ophys_cell_table.cell_specimen_id;

            ophys_cell_table = bot.internal.util.castTableVariables(...
                ophys_cell_table, varNamesToInt, 'uint64');

            ophys_cell_table = recastTableVariables(ophys_cell_table);
        end
    end

    methods (Static)

        function tbl = applyUserDisplayLogic(tbl)
            tbl = bot.item.internal.Manifest.applyUserDisplayLogic(tbl);
            tbl.Properties.UserData.type = 'VisualBehaviorOphys';
        end
    end
end

function return_table = fetch_grouped_uniques(source_table, scan_table, source_grouping_var, scan_grouping_var, scan_var, source_new_var)
% fetch_grouped_uniques - FUNCTION Find unique values in a table, grouped by a particular key
%
% return_table = fetch_grouped_uniques(source_table, scan_table, strGroupingVarSource, scan_grouping_var, scan_var, source_new_var)
%
% `source_table` and `scan_table` are both tables, which can be joined by matching
% variables `source_table.(strGroupingVarSource)` with
% `scan_table.(strGroupingVarScan)`.
%
% This function finds all `scan_table` rows that match `source_table` rows
% (essentially a join on source_grouping_var ==> scan_grouping_var),
% then collects all unique values of `scan_table.(scan_var)` in those rows.
% The collection of unique values is then copied to the new variable
% `source_table.(source_new_var)` for all those matching source rows in
% `source_table`.

% - Get list of keys in `scan_table`.(`scan_grouping_var`)
all_keys_scan = scan_table.(scan_grouping_var);

% - Get list of keys in `source_table`.(`source_grouping_var`)
all_keys_source = source_table.(source_grouping_var);

% - Make a new cell array for `source_table` to contain unique values
groups = cell(size(source_table, 1), 1);

% - Loop over unique scan keys
for source_row_index = 1:numel(all_keys_source)
    % - Get the key for this row
    this_key = all_keys_source(source_row_index);
    
    % - Find rows in scan matching this group (can be cells; `==` doesn't work)
    if iscell(all_keys_scan)
        vbScanGroupRows = arrayfun(@(o)isequal(o, this_key), all_keys_scan);
    else
        vbScanGroupRows = all_keys_scan == this_key;
    end
    
    % - Extract all values in `scan_table`.(`scan_var`) for the matching rows
    all_values = reshape(scan_table{vbScanGroupRows, scan_var}, [], 1);
    
    % - Find unique values for this group
    if iscell(all_values)
        % - Handle "empty" values
        is_empty_value = cellfun(@isempty, all_values);
        if any(is_empty_value)
            unique_values = [unique(all_values(~is_empty_value)); {[]}];
        else
            unique_values = unique(all_values);
        end
    else
        unique_values = unique(all_values);
        if iscolumn(unique_values); unique_values = unique_values'; end
    end
    
    % - Assign these unique values to row in `source_Table`
    groups(source_row_index) = {unique_values};
end

% - Add the groups to `source_table`
return_table = addvars(source_table, groups, 'NewVariableNames', source_new_var);
end
