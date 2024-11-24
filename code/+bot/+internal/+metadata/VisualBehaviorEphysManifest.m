%% CLASS VisualBehaviorEphysManifest
%
% This class can be used to obtain various `tables of items´ from the 
% Visual Behavior neuropixels dataset [1] obtained with the Allen Brain 
% Observatory platform [2].
%
% Item tables contain overview information about individual items belonging 
% to the dataset and tables for the following item types are available:
%
%       BehaviorSessions   % Table of all Behavior-only sessions
%       EphysSessions      % Table of all EPhys sessions
%       Probes             % Table of all EPhys probes
%       Channels           % Table of all EPhys channels
%       Units              % Table of all EPhys units
%   
% USAGE:
%
% Construction:
% >> vbem = bot.internal.Manifest.instance('Ephys', 'VisualBehavior')
% >> vbem = bot.internal.metadata.VisualBehaviorEphysManifest.instance()
%
% Get information about all EPhys experimental sessions:
% >> vbem.EphysSessions
% ans =
%      date_of_acquisition      experiment_container_id    fail_eye_tracking  ...
%     ______________________    _______________________    _________________  ...
%     '2016-03-31T20:22:09Z'    5.1151e+08                 true               ...
%     '2016-07-06T15:22:01Z'    5.2755e+08                 false              ...
%     ...
%
% Force an update of the manifest representing Allen Brain Observatory 
% dataset contents:
% >> vbem.updateManifest()
%
% Access data from an experimental session:
% >> nSessionID = vbem.ephys_sessions(1, 'id');
% >> vbes = bot.getSessions(nSessionID)
% vbes =
%   ephyssession with properties:
%
%                sSessionInfo: [1x1 struct]
%     local_nwb_file_location: []
%
% (See documentation for the `bot.item.concrete.EphysSession` class for more information)
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Behavior 2P dataset. 
%       Available from: portal.brain-map.org/explore/circuits/visual-behavior-neuropixels.
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: portal.brain-map.org/explore/circuits


%% Class definition

classdef VisualBehaviorEphysManifest < bot.item.internal.Manifest

    properties (SetAccess = private, Dependent = true)
        BehaviorSessions   % Table of all Behavior-only sessions
        EphysSessions      % Table of all EPhys sessions
        Probes             % Table of all EPhys probes
        Channels           % Table of all EPhys channels
        Units              % Table of all EPhys units
    end

    properties (Constant, Access = protected, Hidden)
        DATASET_NAME = bot.item.internal.enum.Dataset("VisualBehavior")
        DATASET_TYPE = bot.item.internal.enum.DatasetType("Ephys");
        ITEM_TYPES = ["BehaviorSession", "EphysSession", "Probe", "Channel", "Unit"]
        DOWNLOAD_FROM = containers.Map(...
            bot.internal.metadata.VisualBehaviorEphysManifest.ITEM_TYPES, ...
            ["S3", "S3", "S3", "S3", "S3"])
    end

    properties (Access = protected)
        FileResource = bot.internal.fileresource.visualbehavior.VBEphysS3Bucket.instance()
    end  

    
    %% Constructor
    methods (Access = private)
        function obj = VisualBehaviorEphysManifest()
            obj@bot.item.internal.Manifest()
            obj.ON_DEMAND_PROPERTIES = obj.ITEM_TYPES + "s";     % Property names are plural
        end
    end
    
    %% Method for interacting with singleton instance
    methods (Static = true)
        function manifest = instance(action)
            % instance Get or clear singleton instance of the EPhys manifest
            %
            %   manifest = bot.internal.metadata.VisualBehaviorEphysManifest.instance()
            %   returns a singleton instance of the VisualBehaviorEphysManifest class
            %        
            %   bot.internal.metadata.VisualBehaviorEphysManifest.instance("clear") will 
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
                    manifestInstance = bot.internal.metadata.VisualBehaviorEphysManifest();
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
        
        function sessionTable = get.EphysSessions(obj)
            sessionTable = obj.fetch_cached('EphysSessions', ...
                    @(itemType) obj.fetch_item_table('EphysSession') );
        end

        function experimentTable = get.Probes(obj)
            experimentTable = obj.fetch_cached('Probes', ...
                    @(itemType) obj.fetch_item_table('Probe') );
        end

        function cellTable = get.Channels(obj)
            cellTable = obj.fetch_cached('Channels', ...
                    @(itemType) obj.fetch_item_table('Channel') );
        end

        function cellTable = get.Units(obj)
            cellTable = obj.fetch_cached('Units', ...
                    @(itemType) obj.fetch_item_table('Unit') );
        end

    end

    methods
        function fetchAll(manifest)
        %fetchAll Fetches all of the item tables of the manifest
        %
        %   fetchAll(manifest) will fetch all item tables of the concrete
        %   manifest.

            for itemType = manifest.ITEM_TYPES
                manifest.(itemType+"s");
            end
        end
    end

    %% Low-level getter method for EPhys manifest item tables
    methods (Access = public)

        function table = getItemTable(obj, itemType)
            arguments 
                obj (1,1) bot.item.internal.Manifest
                itemType (1,1) bot.item.internal.enum.ItemType
            end

            manifestTablePrefix = string(obj.DATASET_TYPE);
            manifestTableSuffix = string(itemType) + "s";
                
            if strcmp(string(itemType), "Session")
                tableName = manifestTablePrefix + manifestTableSuffix;
            else
                tableName = manifestTableSuffix;
            end

            table = obj.(tableName);
        end

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
                
                obj.cache.insertObject(cache_key, itemTable);
                obj.clearTempTableFromCache(itemType)
            end

            % Apply standardized table display logic
            itemTable = obj.applyUserDisplayLogic(itemTable);

            itemTable = obj.addDatasetInformation(itemTable);
        end

    end

    methods (Static, Access = protected)
        
        function itemTable = readS3ItemTable(cacheFilePath)
        %readS3ItemTable Read table from file downloaded from S3 bucket
        %
        %   Ephys item tables are stored in json files
            itemTable = readtable(cacheFilePath);
            return

            import bot.internal.util.structcat

            fprintf('Reading table from file...')
            data = jsondecode(fileread(cacheFilePath));

            if isa(data, 'cell')
                itemTable = struct2table( structcat(1, data{:}) );
            else
                itemTable = struct2table(data);
            end
            fprintf('done\n')
        end

    end

    methods (Static, Access = private) % Postprocess manifest item tables
        function ephys_session_table = preprocess_ephyssession_table(ephys_session_table)

            import bot.item.internal.Manifest.recastTableVariables
            import bot.item.internal.Manifest.renameTableVariables

            dateFormat = 'yyyy-MM-dd HH:mm:ss.SSSSSSZ';

            ephys_session_table.date_of_acquisition = ...
                 datetime(ephys_session_table.date_of_acquisition, 'InputFormat', dateFormat, 'TimeZone','UTC');

            ephys_session_table = renameTableVariables(ephys_session_table);
            ephys_session_table = recastTableVariables(ephys_session_table);

            % - Label as EPhys sessions
            [ephys_session_table.type(:)] = deal( categorical("Ephys", ["Ephys", "Ophys"]) );

            % Assign the item id.
            ephys_session_table.id = ephys_session_table.ephys_session_id;
        end

    
        function behavior_session_table = preprocess_behaviorsession_table(behavior_session_table)
            import bot.item.internal.Manifest.recastTableVariables
            import bot.item.internal.Manifest.renameTableVariables

            behavior_session_table.date_of_acquisition = datetime(behavior_session_table.date_of_acquisition, ...
                'InputFormat','yyyy-MM-dd HH:mm:ss.SSSSSSZZZZZ','TimeZone','UTC');
            
            behavior_session_table = renameTableVariables(behavior_session_table);
            behavior_session_table = recastTableVariables(behavior_session_table);
            behavior_session_table.id = behavior_session_table.behavior_session_id;
        end

        function ephys_probe_table = preprocess_probe_table(ephys_probe_table)
            import bot.item.internal.Manifest.recastTableVariables
            import bot.item.internal.Manifest.renameTableVariables

            ephys_probe_table = renameTableVariables(ephys_probe_table);
            ephys_probe_table = recastTableVariables(ephys_probe_table);
                        
            ephys_probe_table.name= categorical(ephys_probe_table.name);
            ephys_probe_table.id = ephys_probe_table.ephys_probe_id;
        end        
        
        function ephys_channel_table = preprocess_channel_table(ephys_channel_table)
            import bot.item.internal.Manifest.recastTableVariables
            import bot.item.internal.Manifest.renameTableVariables

            ephys_channel_table = renameTableVariables(ephys_channel_table);
            ephys_channel_table = recastTableVariables(ephys_channel_table);

            ephys_channel_table.id = ephys_channel_table.ephys_channel_id;
        end

        function ephys_unit_table = preprocess_unit_table(ephys_unit_table)
            import bot.item.internal.Manifest.recastTableVariables
            import bot.item.internal.Manifest.renameTableVariables

            ephys_unit_table = renameTableVariables(ephys_unit_table);
            ephys_unit_table = recastTableVariables(ephys_unit_table);

            ephys_unit_table.id = ephys_unit_table.unit_id;
        end
    end
end