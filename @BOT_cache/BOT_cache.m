%% CLASS BOT_cache - Cache and cloud acces class for Brain Observatory Toolbox
%
% Usage: oBOCache = BOT_cache()
% 
% Primary interface to the Allen Brain Observatory toolbox. 

%% Class definition
classdef BOT_cache < handle
   
   properties (SetAccess = immutable)
      strVersion = '0.02 alpha';       % Version string for cache class
   end
   
   properties (SetAccess = private)
      strCacheDir;                     % Path to location of cached Brain Observatory data
      sCacheFiles;                     % Structure containing file paths of cached files, as well as cloud cacher
   end
   
   properties (SetAccess = private, Dependent = true)
      tAllSessions;                   % Table of all experimental sessions
      tAllContainers;                 % Table of all experimental containers
   end
   
   properties (Access = private, Transient = true)
      bManifestsLoaded = false;         % Flag that indicates whether manifests have been loaded
      manifests;                        % Structure containing Allen Brain Observatory manifests
   end
   
   properties
      strABOBaseUrl = 'http://api.brain-map.org';  % Base URL for Allen Brain Observatory
   end
   
   %% - Properties for global filtering of sessions table, included for backwards compatibility
   properties (SetAccess = private, Transient = true, Hidden = false)
      filtered_session_table;    % A table of sessions that is progressively filtered
      stimulus;                  % A categorical array containing all the stimulus types from filtered_session_table
      targeted_structure;        % A categorical array containing all the brain areas from filtered_session_table
      imaging_depth;             % A categorical array containing all the cortical depths from filtered_session_table
      container_id;              % A vector containing all the container ids from filtered_session_table
      session_id;                % A vector containing all the session ids from filtered_session_table
      session_type;              % A categorical array containing all the session types from filtered_session_table
      cre_line;                  % A categorical array containing all the cre lines from filtered_session_table
      eye_tracking_avail;        % A boolean vector containing all condtions if eye tracking is available or not from filtered_session_table
      
      % I don't think failed experiment containers can be used, so I just go and exclude them
      failed = false;            % Boolean flag: should failed sessions be included?
   end
   
   
   %% Constructor
   methods
      function oCache = BOT_cache
         % CONSTRUCTOR - Returns an object for managing data access to the Allen Brain Observatory
         %
         % Usage: oCache = BOT_cache()
         
         % - Find and return the global cache object, if one exists
         sUserData = get(0, 'UserData');
         if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
               isa(sUserData.BOT_GLOBAL_CACHE, 'BOT_cache') && ...
               isequal(sUserData.BOT_GLOBAL_CACHE.strVersion, oCache.strVersion)
            
            % - A global class instance exists, and is the correct version
            oCache = sUserData.BOT_GLOBAL_CACHE;
         end
         
         %% - Set up a cache object, if no object exists
         
         % - Get the cache directory
         strBOTDir = fileparts(which('BOT_cache'));
         oCache.strCacheDir = [strBOTDir filesep 'Cache'];
         
         % - Ensure the cache directory exists
         if ~exist(oCache.strCacheDir, 'dir')
            mkdir(oCache.strCacheDir);
         end
         
         % - Populate cached filenames
         oCache.sCacheFiles.manifests = [oCache.strCacheDir filesep 'manifests.mat'];
         oCache.sCacheFiles.ccCache = CloudCacher(oCache.strCacheDir);
         
         % - Reset filtered sessions table
         oCache.clear_filters();
         
         % - Assign the cache object to a global cache
         sUserData.BOT_GLOBAL_CACHE = oCache;
         set(0, 'UserData', sUserData);
      end
   end
   
   
   %% Getter and Setter methods
   
   methods
      function tAllSessions = get.tAllSessions(oCache)
         % METHOD - Return the table of all experimental sessions
         
         % - Make sure the manifest has been loaded
         oCache.EnsureManifestsLoaded();
         
         % - Return sessions table
         tAllSessions = oCache.manifests.session_manifest;         
      end
      
      function tAllContainers = get.tAllContainers(oCache)
         % METHOD - Return the table of all experimental containers
         
         % - Make sure the manifest has been loaded
         oCache.EnsureManifestsLoaded();
         
         % - Return container table
         tAllContainers = oCache.manifests.container_manifest;         
      end      
   end

   
   %% Methods to manage manifests and caching
   
   methods
      function EnsureManifestsLoaded(oCache)
         % METHOD - Read the manifest from the cache, or download
         %
         % Usage: oCache.EnsureManifestsLoaded();
         
         % - Check to see if the manifest has been loaded
         if oCache.bManifestsLoaded
            return;
         end
         
         try
            % - Do the manifests exist on disk?
            if ~exist(oCache.sCacheFiles.manifests, 'file')
               % - No, so force an update of the cached manifests
               oCache.manifests = BOT_cache.UpdateManifest();
            else
               % - Yes, so load them directly from disk
               sData = load(oCache.sCacheFiles.manifests, 'manifests');
               oCache.manifests = sData.manifests;
            end
            
         catch mE_cause
            % - Throw an error if manifests could not be loaded
            mEBase = MException('BOT:LoadManifestsFailed', ...
               'Unable to load Allen BRain Observatory manifests.');
            mEBase.addCause(mE_cause);
            throw(mEBase);
         end
         
         oCache.bManifestsLoaded = true;
      end
      
      function strFile = CacheFile(oCache, strURL, strLocalFile)
         % CacheFile - METHOD Check for cached version of Brain Observatory file, and return location
         %
         % Usage: strFile = CacheFile(oCache, strURL, strLocalFile)
         
         strFile = oCache.sCacheFiles.ccCache.websave(strLocalFile, strURL);
      end
      
      function CacheFilesForSessionIDs(oCache, vnSessionIDs)
         % CacheFilesForSessionIDs - METHOD Download NWB files containing experimental data for the given session IDs
         %
         % Usage: CacheFilesForSessionIDs(oCache, vnSessionIDs)
         
         % - Loop over session IDs
         for nSessIndex = 1:numel(vnSessionIDs)
            % - Find this session in the sessions table
            tSession = oCache.tAllSessions(oCache.tAllSessions.id == vnSessionIDs(nSessIndex), :);
            
            % - Cache the corresponding NWB file
            if ~isempty(tSession)
               strURL = [oCache.strABOBaseUrl tSession.well_known_files.download_link];
               strLocalFile = tSession.well_known_files.path;
               
               % - Provide some progress text
               fprintf('Caching URL: [%s]...\n', strURL);
               
               try
                  % - Try to cache the NWB file
                  oCache.CacheFile(strURL, strLocalFile);
               
               catch mE_Cause
                  % - Raise an error on failure
                  mE_Base = MException('BOT:CouldNotCacheURL', ...
                     'The NWB file for a session could not be cached.');
                  mE_Base.addCause(mE_Cause);
                  throw(mE_Base);
               end
            end
         end
      end
   end
   
   
   %% Methods for returning a session object
   
   methods

   end
   
   
   %% Session table filtering properties and methods
   
   methods
      function clear_filters(boc)
         % clear_filters - METHOD Clear all session table filters
         boc.filtered_session_table = boc.tAllSessions;
         
         % - Exclude failed sessions, if requested
         if ~boc.failed
            failed_container_id = boc.tAllContainers((boc.tAllContainers.failed == 1), :).id;
            boc.filtered_session_table = boc.tAllSessions(~ismember(boc.tAllSessions.experiment_container_id, failed_container_id), :);
         end
      end
      
      function result = get_total_num_of_containers(boc,varargin)
         % get_total_num_of_containers - METHOD Return the total number of experiment containers from tAllSessions
         result = size(boc.tAllSessions, 1) * 3;
      end
      
      
      function result = get_all_imaging_depths(boc)
         % get_all_imaging_depths - METHOD Return all the cortical depths from tAllSessions
         result = unique(boc.tAllSessions.imaging_depth);
      end
      
      
      function result = get_all_targeted_structures(boc)
         % get_all_targeted_structures - METHOD Return all the brain areas from tAllSessions
         
         targeted_structure_table = struct2table(boc.tAllSessions.targeted_structure);
         result = categories(categorical(targeted_structure_table.acronym));
      end
      
      
      function result = get_all_session_types (boc)
         % get_all_session_types - METHOD Return all the session types from tAllSessions
         result = categories(categorical(boc.tAllSessions.stimulus_name));
      end
      
      
      function result = get_all_stimuli(boc)
         % get_all_stimuli - METHOD Return all stimulus types from tAllSessions
         
         session_by_stimuli = boc.get_session_by_stimuli();
         result = [];
         for iSession = 1: length(boc.session_type)
            result = [result, session_by_stimuli.(char(boc.session_type(iSession)))]; %#ok<AGROW>
         end
         result = categories(categorical(result));
      end
      
      function result = get_all_cre_lines (boc)
         % get_all_cre_lines - METHOD Return all cre lines from tAllSessions
         result = categories(categorical(boc.tAllSessions.cre_line));
      end
      
      
      function get_summary_of_containers_along_imaging_depths(boc)
         % get_summary_of_containers_along_imaging_depths - METHOD Return the number of experiment containers recorded at each cortical depth
         summary(categorical(cellstr(num2str((boc.tAllContainers.imaging_depth)))))
      end
      
      function get_summary_of_containers_along_targeted_structures (boc)
         % get_summary_of_containers_along_targeted_structures - METHOD Return the number of experiment containers recorded in each brain region
         container_targeted_structure_table = struct2table(boc.tAllContainers.targeted_structure);
         summary(categorical(cellstr(container_targeted_structure_table.acronym)))
      end
      
      function summary_table = get_summary_of_containers_along_depths_and_structures(boc)
         % get_summary_of_containers_along_depths_and_structures - METHOD Return the number of experiment containers recorded at each cortical depth in each brain region
         
         % - Preallocate the summary matrix
         summary_matrix = nan(length(boc.get_all_imaging_depths()), length(boc.get_all_targeted_structures()));
         
         % - Get list of all imaging depths and targeted structures for table variable names
         all_depths =  boc.get_all_imaging_depths();
         all_structures = boc.get_all_targeted_structures;
         
         % - Loop over imaging depths and structures to build summary
         for cur_depth = 1: size(boc.get_all_imaging_depths(),1)
            for cur_structure = 1: size(boc.get_all_targeted_structures,1)
               % - Find matching imaging depths
               vbMatchImDepth = boc.tAllSessions.imaging_depth == all_depths(cur_depth);

               % - Find matching targeted structures
               exp_targeted_structure_session_table = [boc.tAllSessions.targeted_structure];
               vbMatchTargeted = ismember({exp_targeted_structure_session_table.acronym}, all_structures{cur_structure})';
               
               % - Build summary matrix
               summary_matrix(cur_depth,cur_structure) = nnz(vbMatchImDepth & vbMatchTargeted) / 3;
            end
         end

         % - Build summary table
         summarize_by_depths = sum(summary_matrix,2);
         summary_matrix = [summary_matrix,summarize_by_depths];
         summarize_by_structures = sum(summary_matrix,1);
         summary_matrix = [summary_matrix; summarize_by_structures];
         summary_table = array2table(summary_matrix);
         summary_table.Properties.VariableNames = [all_structures;'total'];
         summary_table.Properties.RowNames = [cellstr(num2str(all_depths));'total'];
      end
      
      function boc = filter_session_by_eye_tracking(boc, need_eye_tracking)
         % filter_session_by_eye_tracking - METHOD Eliminates sessions in filtered_session_table that don't have eye tracking, if eye tracking is desired
         
         if need_eye_tracking
            boc.filtered_session_table = boc.filtered_session_table(boc.filtered_session_table.fail_eye_tracking == false, :);            
         end
      end
      
      function boc = filter_sessions_by_session_id(boc, session_id)
         % filter_sessions_by_session_id - METHOD Eliminates sessions in filtered_session_table that don't have the session id provided
         
         boc.filtered_session_table = boc.filtered_session_table(boc.filtered_session_table.id == session_id, :);
      end
      
      function boc = filter_session_by_cre_line(boc, cre_line)
         % filter_session_by_cre_line - METHOD Eliminates sessions in filtered_session_table that don't have the cre line provided
         
         boc.filtered_session_table = boc.filtered_session_table(ismember(boc.filtered_session_table.cre_line, cre_line),:);
      end
      
      function boc = filter_sessions_by_container_id(boc,container_id)
         % filter_sessions_by_container_id - METHOD Eliminates sessions in filtered_session_table thadon't have the container id provided
         
         boc.filtered_session_table = boc.filtered_session_table(boc.filtered_session_table.experiment_container_id == container_id, :);
      end
      
      function boc = filter_sessions_by_stimuli(boc,stimulus)
         % filter_sessions_by_stimuli - METHOD Eliminates sessions in filtered_session_table that don't have the stimulus type provided
         
         session_by_stimuli = boc.get_session_by_stimuli();
         % filter sessions by stimuli
         boc.filtered_session_table =  boc.filtered_session_table(ismember(boc.filtered_session_table.stimulus_name,...
            boc.find_session_for_stimuli(stimulus,session_by_stimuli)), :);
      end
      
      function boc = filter_sessions_by_imaging_depth(boc,depth)
         % filter_sessions_by_imaging_depth - METHOD Eliminates sessions in filtered_session_table that don't have the cortical depth provided
         
         % filter sessions by imaging_depth
         boc.filtered_session_table = boc.filtered_session_table(boc.filtered_session_table.imaging_depth == depth, :);
      end
            
      function acronym = get_targeted_structure_acronyms(boc)
         % get_targeted_structure_acronyms - METHOD Return targeted structure acronyms for sessions in filtered_session_table
         exp_targeted_structure_session_table = struct2table(boc.filtered_session_table.targeted_structure);
         acronym = categorical(exp_targeted_structure_session_table.acronym);
      end
      
      function boc = filter_sessions_by_targeted_structure(boc, structure)
         % filter_sessions_by_targeted_structure - METHOD Eliminates sessions in filtered_session_table that don't have the brain area provided
         
         % filter sessions by targeted_structure
         acronyms = get_targeted_structure_acronyms(boc);
         vbMatchAcronym = ismember(acronyms, structure);
         boc.filtered_session_table = boc.filtered_session_table(vbMatchAcronym, :);         
      end
      
      function boc = filter_sessions_by_session_type(boc,session_type)
         % filter_sessions_by_session_type - METHOD Eliminates sessions in filtered_session_table that don't have the session type provided
         
         boc.filtered_session_table = boc.filtered_session_table(strcmp(boc.filtered_session_table.stimulus_name,session_type),:);
      end
      
      %% -- Method to return session objects for filtered sessions
      
      function vbsSessions = get_filtered_sessions(boc)
         % get_filtered_sessions - METHOD Return session objects for the filtered experimental sessions
         %
         % Usage: vbsSessions = get_filtered_sessions(boc)
         
         % - Get the current table of filtered sessions, construct objects
         vbsSessions = BOT_BOsession(boc.filtered_session_table.id);
      end
      
      %% -- Getter methods for dependent filtered sessions properties
      
      function result = get.filtered_session_table(boc)
         % get.filtered_session_table - GETTER METHOD Access `filtered_session_table` property
         if isempty(boc.filtered_session_table)
            error('BOT:NoSessionsRemain', 'No sessions remain after filtering.');
         else
            result = boc.filtered_session_table;
         end
      end
      
      function stimulus = get.stimulus(boc)
         % get.stimulus - GETTER METHOD Access `stimulus` property
         stimulus = boc.get_all_stimuli();
      end
      
      function session_type = get.session_type(boc)
         % get.session_type - GETTER METHOD Access `session_type` property
         session_type = categorical(boc.filtered_session_table{:, 'stimulus_name'});
      end
      
      function targeted_structure = get.targeted_structure(boc)
         % get.targeted_structure - GETTER METHOD Access `targeted_structure` property
         targeted_structure = categories(boc.get_targeted_structure_acronyms());
      end

      function imaging_depth = get.imaging_depth(boc)
         % get.imaging_depth - GETTER METHOD Access `imaging_depth` property
         imaging_depth = unique(boc.filtered_session_table.imaging_depth);
      end

      function container_id = get.container_id(boc)
         % get.container_id - GETTER METHOD Access `container_id` property
         container_id = unique(boc.filtered_session_table.experiment_container_id);
      end

      function session_id = get.session_id(boc)
         % get.session_id - GETTER METHOD Access `session_id` property
         session_id = boc.filtered_session_table.id;
      end

      function cre_line = get.cre_line(boc)
         % get.cre_line - GETTER METHOD Access `cre_line` property
         cre_line = categories(categorical(boc.filtered_session_table.cre_line));
      end

      function eye_tracking_avail = get.eye_tracking_avail(boc)
         % get.eye_tracking_avail - GETTER METHOD Access `eye_tracking_avail` property
         eye_tracking_avail = ~unique(boc.filtered_session_table.fail_eye_tracking);
      end      
   end

   
   %% Static class methods
   
   methods (Static)
      function manifests = UpdateManifest
         % STATIC METHOD - Check and update file manifest from Allen Brain Observatory API
         %
         % Usage: manifests = BOT_cache.UpdateManifest()
         
         % TODO: Force download of the manifest, if the manifest has been updated
         
         try
            % - Get a cache object
            oCache = BOT_cache();
            
            % - Download the manifest from the Allen Brain API
            manifests = BOT_cache.get_manifests_info_from_api();
            
            % - Save the manifest to the cache directory
            save(oCache.sCacheFiles.manifests, 'manifests');
         
         catch mE_cause
            % - Throw an error if manifests could not be updated
            mEBase = MException('BOT:UpdateManifestsFailed', ...
                 'Unable to update the Allen Brain Observatory manifests.');
            mEBase.addCause(mE_cause);
            throw(mEBase);
         end
      end
   end
   
   %% Private methods
   
   methods (Access = private, Static = true)
      
      function [manifests] = get_manifests_info_from_api
         
         % get_manifests_info_from_api - PRIVATE METHOD Download the Allen Brain Observatory manifests from the web
         %
         % Usage: [manifests] = get_manifests_info_from_api
         %
         % Download `container_manifest`, `session_manifest`, `cell_id_mapping`
         % from brain observatory api as matlab tables. Returns the tables as fields
         % of a structure. Converts various columns to appropriate formats,
         % including categorical arrays.
         
         % - Specify URLs for download
         container_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::ExperimentContainer,rma::include,ophys_experiments,isi_experiment,specimen%28donor%28conditions,age,transgenic_lines%29%29,targeted_structure,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
         session_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::OphysExperiment,rma::include,experiment_container,well_known_files%28well_known_file_type%29,targeted_structure,specimen%28donor%28age,transgenic_lines%29%29,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
         cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';
         
         % - Download container manifest
         options1 = weboptions('ContentType','JSON','TimeOut',60);
         
         container_manifest_raw = webread(container_manifest_url,options1);
         manifests.container_manifest = struct2table(container_manifest_raw.msg);
         
         % - Download session manifest
         session_manifest_raw = webread(session_manifest_url,options1);
         manifests.session_manifest = struct2table(session_manifest_raw.msg);
         
         % - Download cell ID mapping
         options2 = weboptions('ContentType','table','TimeOut',60);
         manifests.cell_id_mapping = webread(cell_id_mapping_url,options2);
         
         % - Create cre_line table from specimen field of session_manifest and
         % append it back to session_manifest table
         % cre_line is important, makes life easier if it's explicit
         
         tAllSessions = manifests.session_manifest;
         cre_line = cell(size(tAllSessions,1),1);
         for i = 1:size(tAllSessions,1)
            donor_info = tAllSessions(i,:).specimen.donor;
            transgenic_lines_info = struct2table(donor_info.transgenic_lines);
            cre_line(i,1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
               & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
         end
         
         manifests.session_manifest = [tAllSessions, cre_line];
         manifests.session_manifest.Properties.VariableNames{'Var15'} = 'cre_line';
         
         % - Convert columns to integer and categorical variables
         manifests.session_manifest{:, 2} = uint32(manifests.session_manifest{:, 2});
      end
      
      function filtered_session = find_session_for_stimuli(stimulus, session_by_stimuli)
         filtered_session = {};
         fields = fieldnames(session_by_stimuli);
         for i = 1 :length(fields)
            if sum(ismember(session_by_stimuli.(char(fields(i))),stimulus)) >= 1
               filtered_session(end+1) = cellstr(fields(i)); %#ok<AGROW>
            end
         end
      end
      
      function session_by_stimuli = get_session_by_stimuli()
         session_by_stimuli.three_session_A = {'drifting_gratings','natural_movie_one','natural_movie_three','spontaneous'};
         session_by_stimuli.three_session_B = {'static_gratings','natural_scenes','natural_movie_one','spontaneous'};
         session_by_stimuli.three_session_C = {'locally_sparse_noise_4deg','natural_movie_one','natural_movie_two','spontaneous'};
         session_by_stimuli.three_session_C2 = {'locally_sparse_noise_4deg','locally_sparse_noise_8deg', ...
            'natural_movie_one','natural_movie_two','spontaneous'};
      end
      
   end
   
end   
   