%% CLASS VisualBehaviorOphysManifest
%
% This class can be used to obtain various `tables of items´ from the 
% Visual Behavior 2P dataset [1] obtained with the Allen Brain Observatory 
% platform [2].
%
% Item tables contain overview information about individual items belonging 
% to the dataset and tables for the following item types are available:
%
%       ophys_experiments  : Container for multiple experimenal sessions
%       ophys_sessions     : Experimental sessions
%       ophys_cells        : Recorded neurons
%   
%
% USAGE:
%
% Construction:
% >> bom = bot.item.internal.Manifest.instance('ophys-vb')
% >> bom = bot.item.internal.VisualBehaviorOphysManifest.instance()
%
% Get information about all OPhys experimental sessions:
% >> bom.ophys_sessions
% ans =
%      date_of_acquisition      experiment_container_id    fail_eye_tracking  ...
%     ______________________    _______________________    _________________  ...
%     '2016-03-31T20:22:09Z'    5.1151e+08                 true               ...
%     '2016-07-06T15:22:01Z'    5.2755e+08                 false              ...
%     ...
%
% Force an update of the manifest representing Allen Brain Observatory 
% dataset contents:
% >> bom.UpdateManifests()
%
% Access data from an experimental session:
% >> nSessionID = bom.ophys_sessions(1, 'id');
% >> bos = bot.getSessions(nSessionID)
% bos =
%   ophyssession with properties:
%
%                sSessionInfo: [1x1 struct]
%     local_nwb_file_location: []
%
% (See documentation for the `bot.item.concrete.OphysSession` class for more information)
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. 
%       Available from: portal.brain-map.org/explore/circuits/visual-coding-2p.
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
        OphysCells        % Table of all OPhys cells
    end

% %     properties (SetAccess = private, Dependent = true) % Todo: rename?
% %         Experiments   % Table of all OPhys experiment containers
% %         Sessions      % Table of all OPhys experimental sessions
% %         Cells         % Table of all OPhys cells
% %     end

    properties (Constant, Access = protected, Hidden)
        DATASET_NAME = "VisualBehavior"
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
        ITEM_TYPES = ["BehaviorSession", "OphysSession", "OphysExperiment", "OphysCell"]
        DOWNLOAD_FROM = containers.Map(...
            bot.internal.metadata.VisualBehaviorOphysManifest.ITEM_TYPES, ...
            ["S3", "S3", "S3", "S3"])
    end

    properties (Access = protected)
        FileResource = bot.internal.fileresource.visualbehavior.S3Bucket.instance()
    end  

    
    %% Constructor
    methods (Access = private)
        function oManifest = VisualBehaviorOphysManifest()
            oManifest@bot.item.internal.Manifest()
            oManifest.ON_DEMAND_PROPERTIES = oManifest.ITEM_TYPES + "s";     % Property names are plural
        end
    end
    
    %% Method for interacting with singleton instance
    methods (Static = true)
        function manifest = instance(action)
            % instance Get or clear singleton instance of the OPhys manifest
            %
            %   manifest = bot.item.internal.OphysManifest.instance()
            %   returns a singleton instance of the OphysManifest class
            %        
            %   bot.item.internal.OphysManifest.instance("clear") will 
            %   clear the singleton instance from memory
            
            arguments
                action (1,1) string {mustBeMember(action, ...
                    ["get", "clear", "reset"])} = "get";
            end
            
            persistent ophysmanifest % singleton instance
            
            % - Clear the manifest if requested
            if ismember(action, ["clear", "reset"])
                delete(ophysmanifest); ophysmanifest = [];
            end

            if ismember(action, ["get", "reset"])
                % - Construct the manifest if singleton instance is not present
                if isempty(ophysmanifest)
                    ophysmanifest = bot.internal.metadata.VisualBehaviorOphysManifest();
                end

                % - Return the instance
                manifest = ophysmanifest; 
            end
        end
    end

    %% Getters for manifest item tables (on-demand properties)
    methods

        function sessionTable = get.BehaviorSessions(oManifest)
            sessionTable = oManifest.fetch_cached('BehaviorSessions', ...
                    @(itemType) oManifest.fetch_item_table('BehaviorSession') );
        end
        
        function sessionTable = get.OphysSessions(oManifest)
            sessionTable = oManifest.fetch_cached('OphysSessions', ...
                    @(itemType) oManifest.fetch_item_table('OphysSession') );
        end

        function experimentTable = get.OphysExperiments(oManifest)
            experimentTable = oManifest.fetch_cached('OphysExperiments', ...
                    @(itemType) oManifest.fetch_item_table('OphysExperiment') );
        end

        function cellTable = get.OphysCells(oManifest)
            cellTable = oManifest.fetch_cached('OphysCells', ...
                    @(itemType) oManifest.fetch_item_table('OphysCell') );
        end

    end

    %% Low-level getter method for OPhys manifest item tables
    methods (Access = public)

        function itemTable = fetch_item_table(oManifest, itemType)
        %fetch_item_table Fetch item table (get from cache or download)

            cache_key = oManifest.getManifestCacheKey(itemType);

            if oManifest.cache.IsObjectInCache(cache_key)
                itemTable = oManifest.cache.RetrieveObject(cache_key);

            else
                itemTable = oManifest.download_item_table(itemType);
                
                % Process downloaded item table
                fcnName = sprintf('%s.preprocess_%s_table', class(oManifest), lower(itemType)); % Static method
                itemTable = feval(fcnName, itemTable);
                
                oManifest.cache.InsertObject(cache_key, itemTable);
                oManifest.clearTempTableFromCache(itemType)
            end

            % Apply standardized table display logic
            itemTable = oManifest.applyUserDisplayLogic(itemTable); 
        end

    end

    methods (Static, Access = protected)
        
        function itemTable = readS3ItemTable(cacheFilePath)
        %readS3ItemTable Read table from file downloaded from S3 bucket
        %
        %   Ophys item tables are stored in json files
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
        function ophys_session_table = preprocess_ophyssession_table(ophys_session_table)
            ophys_session_table.id = uint32(ophys_session_table.behavior_session_id);
        end

        function ophys_experiment_table = preprocess_ophysexperiment_table(ophys_experiment_table)
            return
            % - Convert variables to useful types
            ophys_experiment_table.id = uint32(ophys_experiment_table.id);
            ophys_experiment_table.failed_facet = uint32(ophys_experiment_table.failed_facet);
            ophys_experiment_table.isi_experiment_id = uint32(ophys_experiment_table.isi_experiment_id);
            ophys_experiment_table.specimen_id = uint32(ophys_experiment_table.specimen_id);
        end
    
        function ophys_session_table = preprocess_behaviorsession_table(ophys_session_table)
            
            num_sessions = size(ophys_session_table, 1);
            
% % %             % - Label as ophys sessions
% % %             ophys_session_table = addvars(ophys_session_table, ...
% % %                 repmat(categorical({'OPhys'}, {'EPhys', 'OPhys'}), num_sessions, 1), ...
% % %                 'NewVariableNames', 'type', ...
% % %                 'before', 1);
% % %             
% % %             % - Create `cre_line` variable from specimen field of session
% % %             %  table and append it back to session table.
% % %             % `cre_line` is important, makes life easier if it's explicit
% % %             cre_line = cell(num_sessions, 1);
% % %             for i = 1:num_sessions
% % %                 donor_info = ophys_session_table(i, :).specimen.donor;
% % %                 transgenic_lines_info = struct2table(donor_info.transgenic_lines);
% % %                 cre_line(i, 1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
% % %                     & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
% % %             end
% % %             
% % %             ophys_session_table = addvars(ophys_session_table, cre_line, ...
% % %                 'NewVariableNames', 'cre_line');
            
            % - Convert variables to useful types
            ophys_session_table.behavior_session_id = uint32(ophys_session_table.behavior_session_id);
            ophys_session_table.file_id = uint32(ophys_session_table.file_id);
            %ophys_session_table.date_of_acquisition = datetime(ophys_session_table.date_of_acquisition,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
            ophys_session_table.mouse_id = uint32(ophys_session_table.mouse_id);
            
            ophys_session_table.session_type = string(ophys_session_table.session_type);
            ophys_session_table.indicator = categorical(string(ophys_session_table.indicator)); 
            ophys_session_table.sex = string(ophys_session_table.sex);
            ophys_session_table.reporter_line = string(ophys_session_table.reporter_line);  
            ophys_session_table.cre_line = string(ophys_session_table.cre_line);  

        end

        function ophys_cell_table = preprocess_ophyscell_table(ophys_cell_table)
            return
            % - Convert variables to useful types
            ophys_cell_table.experiment_container_id = uint32(ophys_cell_table.experiment_container_id);
            ophys_cell_table.id = uint32(ophys_cell_table.cell_specimen_id); % consider renaming on query
            ophys_cell_table = removevars(ophys_cell_table, 'cell_specimen_id');
            ophys_cell_table.specimen_id = uint32(ophys_cell_table.specimen_id);
            
            ophys_cell_table.tlr1_id = uint32(ophys_cell_table.tlr1_id);
            ophys_cell_table.tld1_id = uint32(ophys_cell_table.tld1_id);            

            % - Convert metric (replace empty with nan)
            metric_varnames = {'reliability_dg', 'reliability_nm1_a', 'reliability_nm1_b', ...
                'reliability_nm2', 'reliability_nm3', 'reliability_ns', 'reliability_sg', ...
                'dsi_dg', 'g_dsi_dg', 'g_osi_dg', 'g_osi_sg', 'image_sel_ns', 'osi_dg', ...
                'osi_sg', 'p_dg', 'p_ns', 'p_run_mod_dg', 'p_run_mod_ns', 'p_run_mod_sg', ...
                'p_sg', 'peak_dff_dg', 'peak_dff_ns', 'peak_dff_sg', 'pref_dir_dg', 'pref_image_ns', ...
                'pref_ori_sg', 'pref_phase_sg', 'pref_sf_sg', 'pref_tf_dg', 'rf_area_off_lsn', ...
                'rf_area_on_lsn', 'rf_center_off_x_lsn', 'rf_center_off_y_lsn', 'rf_center_on_x_lsn', ...
                'rf_center_on_y_lsn', 'rf_chi2_lsn', 'rf_distance_lsn', 'rf_overlap_index_lsn', ...
                'run_mod_dg', 'run_mod_ns', 'run_mod_sg', 'sfdi_sg', 'tfdi_dg', 'time_to_peak_ns', ...
                'time_to_peak_sg', 'tld2_id', 'reliability_nm1_c'};
                
            ophys_cell_table = convert_metric_vars(ophys_cell_table, metric_varnames);  
            
            ophys_cell_table.tld2_id = uint32(ophys_cell_table.tld2_id);

            function table = convert_metric_vars(table, varnames)

                function metric = convert_cell_metric(metric)
                    metric(cellfun(@isempty, metric)) = {nan};
                    metric = [metric{:}]';
                end
                
                for var = varnames
                    table.(var{1}) = convert_cell_metric(table.(var{1}));
                end
            end
        end
    end
end