%% CLASS OphysManifest
%
% This class can be used to obtain a list of available experimental
% sessions from the Visual Coding 2P dataset [1] obtained with the Allen
% Brain Observatory platform [2].
%
% Construction:
% >> bom = bot.item.internal.Manifest('ophys')
% >> bom = bot.item.internal.OphysManifest.instance()
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
% Force an update of the manifest representing Allen Brain Observatory dataset contents:
% >> bom.UpdateManifests()
%
% Access data from an experimental session:
% >> nSessionID = bom.ophys_sessions(1, 'id');
% >> bos = bot.session(nSessionID)
% bos =
%   ophyssession with properties:
%
%                sSessionInfo: [1x1 struct]
%     local_nwb_file_location: []
%
% (See documentation for the `bot.item.ophyssession` class for more information)
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: portal.brain-map.org/explore/circuits/visual-coding-2p.
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits
%

%% Class definition

classdef OphysManifest < handle
    properties (Access = private, Transient = true)
        cache = bot.internal.cache;        % BOT Cache object
        api_access;                         % Function handles for low-level API access
    end
    
    properties (SetAccess = private, Dependent = true)
        ophys_sessions;                   % Table of all OPhys experimental sessions
        ophys_experiments;                % Table of all OPhys experiments
        ophys_cells;                      % Table of all OPhys cells
    end
    
    %% Constructor
    methods (Access = private)
        function oManifest = OphysManifest()
            % Memoize manifest getter
            oManifest.api_access.fetch_cached_ophys_manifests = memoize(@oManifest.fetch_cached_ophys_manifests);
        end
    end
    
    methods (Static = true)
        function manifest = instance(clear_manifest)
            % instance - STATIC METHOD Retrieve or reset the singleton instance of the OPhys manifest
            %
            % Usage: manifest = instance()
            %        instance(clear_manifest)
            %
            % `manifest` will be a singleton manifest object.
            %
            % If `clear_manifest` = `true` is provided, then the single
            % instance will be cleared and reset.
            
            arguments
                clear_manifest = false
            end
            
            persistent ophysmanifest
            
            % - Construct the manifest if single instance is not present
            if isempty(ophysmanifest)
                ophysmanifest = bot.item.internal.OphysManifest();
            end
            
            % - Return the instance
            manifest = ophysmanifest;
            
            % - Clear the manifest if requested
            if clear_manifest
                ophysmanifest = [];
                clear manifest;
            end
        end
    end
    
    %% Getters for manifest tables
    methods
        function ophys_sessions = get.ophys_sessions(oManifest)
            ophys_manifests = oManifest.api_access.fetch_cached_ophys_manifests();
            
            % Apply standardized table display logic
            ophys_sessions = bot.item.internal.Manifest.applyUserDisplayLogic(ophys_manifests.ophys_session_manifest); 
        end
        
        function ophys_experiments = get.ophys_experiments(oManifest)
            ophys_manifests = oManifest.api_access.fetch_cached_ophys_manifests();
            
            % Apply standardized table display logic
            ophys_experiments = bot.internal.manifest.applyUserDisplayLogic(ophys_manifests.ophys_experiment_manifest); 
        end
        
        function ophys_cells = get.ophys_cells(oManifest)
            ophys_manifests = oManifest.api_access.fetch_cached_ophys_manifests();
           
            % Apply standardized table display logic
            ophys_cells = bot.internal.manifest.applyUserDisplayLogic(ophys_manifests.ophys_cells_manifest); 
        end
    end
    
    %% Manifest update method
    methods
        function UpdateManifests(manifest,clearMemoOnly)
            
            arguments
                manifest (1,1) bot.item.internal.OphysManifest
                clearMemoOnly (1,1) logical = true
            end
            
            if ~clearMemoOnly
                % - Invalidate API manifests in cache
                manifest.cache.ccCache.RemoveURLsMatchingSubstring('criteria=model::ExperimentContainer');
                manifest.cache.ccCache.RemoveURLsMatchingSubstring('criteria=model::OphysExperiment');
                
                % - Remove cached manifest tables
                manifest.cache.RemoveObject('allen_brain_observatory_ophys_manifests')
            end
            
            % - Clear all caches for memoized access functions
            for strField = fieldnames(manifest.api_access)'
                manifest.api_access.(strField{1}).clearCache();
            end
            
            % - Reset singleton instance
            bot.item.internal.OphysManifest.instance(true);
        end
    end
    
    methods (Access = private)
        %% Low-level getter method for OPhys manifests
        function [ophys_manifests] = fetch_ophys_manifests_info_from_api(manifest)
            % fetch_ophys_manifests_info_from_api - PRIVATE METHOD Download manifests of content from Allen Brain Observatory dataset via the Allen Brain Atlas API
            %
            % Usage: [ophys_manifests] = fetch_ophys_manifests_info_from_api(return_table)
            %
            % Download `experiment_container_manifest`, `session_manifest`,
            % `cell_id_mapping` as MATLAB tables. Returns the tables as fields
            % of a structure. Converts various columns to appropriate formats,
            % including categorical arrays.
            
            disp('Fetching OPhys manifests...');
            
            % - Specify URLs for download
            cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';
            
            %% - Fetch OPhys experiment container manifest
            ophys_experiment_manifest = manifest.cache.CachedAPICall('criteria=model::ExperimentContainer', 'rma::include,ophys_experiments,isi_experiment,specimen(donor(conditions,age,transgenic_lines)),targeted_structure');
            
            % - Convert varibales to useful types
            ophys_experiment_manifest.id = uint32(ophys_experiment_manifest.id);
            ophys_experiment_manifest.failed_facet = uint32(ophys_experiment_manifest.failed_facet);
            ophys_experiment_manifest.isi_experiment_id = uint32(ophys_experiment_manifest.isi_experiment_id);
            ophys_experiment_manifest.specimen_id = uint32(ophys_experiment_manifest.specimen_id);
            
            ophys_manifests.ophys_experiment_manifest = ophys_experiment_manifest;
            
            %% - Fetch OPhys session manifest
            ophys_session_manifest = manifest.cache.CachedAPICall('criteria=model::OphysExperiment', 'rma::include,experiment_container,well_known_files(well_known_file_type),targeted_structure,specimen(donor(age,transgenic_lines))');
            
            % - Label as ophys sessions
            ophys_session_manifest = addvars(ophys_session_manifest, ...
                repmat(categorical({'OPhys'}, {'EPhys', 'OPhys'}), size(ophys_session_manifest, 1), 1), ...
                'NewVariableNames', 'type', ...
                'before', 1);
            
            % - Create `cre_line` variable from specimen field of session
            % manifests and append it back to session_manifest tables.
            % `cre_line` is important, makes life easier if it's explicit
            
            % - Extract from OPhys sessions manifest
            all_sessions = ophys_session_manifest;
            cre_line = cell(size(all_sessions, 1), 1);
            for i = 1:size(all_sessions, 1)
                donor_info = all_sessions(i, :).specimen.donor;
                transgenic_lines_info = struct2table(donor_info.transgenic_lines);
                cre_line(i,1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
                    & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
            end
            
            ophys_session_manifest = addvars(ophys_session_manifest, cre_line, ...
                'NewVariableNames', 'cre_line');
            
            % - Convert experiment containiner variables to useful types
            ophys_session_manifest.experiment_container_id = uint32(ophys_session_manifest.experiment_container_id);
            ophys_session_manifest.id = uint32(ophys_session_manifest.id);
            ophys_session_manifest.date_of_acquisition = datetime(ophys_session_manifest.date_of_acquisition,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
            ophys_session_manifest.specimen_id = uint32(ophys_session_manifest.specimen_id);
            
            ophys_session_manifest.name = string(ophys_session_manifest.name);
            ophys_session_manifest.stimulus_name = categorical(string(ophys_session_manifest.stimulus_name)); 
            ophys_session_manifest.storage_directory = string(ophys_session_manifest.storage_directory);
            ophys_session_manifest.cre_line = string(ophys_session_manifest.cre_line);                                               
            
            ophys_manifests.ophys_session_manifest = ophys_session_manifest;
            
            %% - Fetch cell ID mapping
            
            options = weboptions('ContentType', 'table', 'TimeOut', 60);
            ophys_manifests.cell_id_mapping = manifest.cache.ccCache.webread(cell_id_mapping_url, [], options);
            
            %% - Fetch cell speciments manifest
            ophys_cells_manifest = manifest.cache.CachedAPICall('q=model::ApiCamCellMetric', [], [], [], [], [], [], "cell_specimen_id");
            
            ophys_cells_manifest.experiment_container_id = uint32(ophys_cells_manifest.experiment_container_id);
            ophys_cells_manifest.id = uint32(ophys_cells_manifest.cell_specimen_id);
            ophys_cells_manifest = removevars(ophys_cells_manifest, 'cell_specimen_id');
            ophys_cells_manifest.specimen_id = uint32(ophys_cells_manifest.specimen_id);
            
            ophys_cells_manifest.tlr1_id = uint32(ophys_cells_manifest.tlr1_id);
            ophys_cells_manifest.tld1_id = uint32(ophys_cells_manifest.tld1_id);            
            
            function table = convert_metric_vars(table, varnames)

                function metric = convert_cell_metric(metric)
                    metric(cellfun(@isempty, metric)) = {nan};
                    metric = [metric{:}]';
                end
                
                for var = varnames
                    table.(var{1}) = convert_cell_metric(table.(var{1}));
                end
            end
            
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
                
            ophys_cells_manifest = convert_metric_vars(ophys_cells_manifest, metric_varnames);  
            
            ophys_cells_manifest.tld2_id = uint32(ophys_cells_manifest.tld2_id);
            
            ophys_manifests.ophys_cells_manifest = ophys_cells_manifest;
        end
        
        function ophys_manifests = fetch_cached_ophys_manifests(manifest)
            % fetch_cached_ophys_manifests - METHOD Fetch (possibly cached) OPhys manifest
            %
            % Usage: ophys_manifests = fetch_cached_ophys_manifests(manifest)
            nwb_key = 'allen_brain_observatory_ophys_manifests';
            
            if manifest.cache.IsObjectInCache(nwb_key)
                ophys_manifests = manifest.cache.RetrieveObject(nwb_key);
                
            else
                ophys_manifests = fetch_ophys_manifests_info_from_api(manifest);
                manifest.cache.InsertObject(nwb_key, ophys_manifests);
            end            

        end
    end
end