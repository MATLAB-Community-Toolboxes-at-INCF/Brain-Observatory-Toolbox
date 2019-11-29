%% CLASS bot.cache - Cache and cloud access class for Brain Observatory Toolbox
%
% This class is used internally by the Brain Observatory Toolbox. It can also be
% used to obtain a raw list of all available experimental sessions from the
% Allen Brain Observatory.
%
% Construction:
% >> boc = bot.cache()
%
% Get information about all experimental sessions:
% >> boc.tAllSessions
% ans = 
%      date_of_acquisition      experiment_container_id    fail_eye_tracking  ...  
%     ______________________    _______________________    _________________  ...  
%     '2016-03-31T20:22:09Z'    5.1151e+08                 true               ...  
%     '2016-07-06T15:22:01Z'    5.2755e+08                 false              ...
%     ...
%
% Force an update of the Allen Brain Observatory manifest:
% >> boc.UpdateManifest()
%
% Access data from an experimental session:
% >> nSessionID = boc.tAllSessions(1, 'id');
% >> bos = bot.session(nSessionID)
% bos = 
%   session with properties:
% 
%                sSessionInfo: [1x1 struct]
%     strLocalNWBFileLocation: []
%
% (See documentation for the `bot.session` class for more information)

%% Class definition
classdef cache < handle
   
   properties (SetAccess = immutable)
      strVersion = '0.4';              % Version string for cache class
   end
   
   properties (SetAccess = private)
      strCacheDir;                     % Path to location of cached Brain Observatory data
      sCacheFiles;                     % Structure containing file paths of cached files, as well as cloud cacher
   end
   
   properties (SetAccess = private, Dependent = true)
      tAllOPhysSessions;                   % Table of all OPhys experimental sessions
      tAllOPhysContainers;                 % Table of all OPhys experimental containers
      tAllECEPhysSessions;                 % Table of all ECEPhys experimental sessions
      tAllECEPhysChannels;                 % Table of all ECEPhys channels
      tAllECEPhysProbes;                   % Table of all ECEPhys probes
      tAllECEPhysUnits;                    % Table of all ECEPhys units
   end
   
   properties (Access = private, Transient = true)
      CACHED_ophys_manifests;
      CACHED_tECEPhysSessions;
      CACHED_tECEPhysChannels;
      CACHED_tECEPhysProbes;
      CACHED_tECEPhysUnits;
   end

   properties (Access = {?bot.cache, ?bot.session})
      strGATrackingID = 'UA-114632844-1';    % Tracking ID for Google Analytics
   end      
   
   properties
      strABOBaseUrl = 'http://api.brain-map.org';  % Base URL for Allen Brain Observatory
   end
   
   %% Constructor
   methods
      function oCache = cache(strCacheDir)
         % CONSTRUCTOR - Returns an object for managing data access to the Allen Brain Observatory
         %
         % Usage: oCache = bot.cache(<strCacheDir>)
         
         % - Check if a cache directory has been provided
         if ~exist('strCacheDir', 'var') || isempty(strCacheDir)
            % - Get the default cache directory
            strBOTDir = fileparts(which('bot.cache'));
            oCache.strCacheDir = [strBOTDir filesep 'Cache'];
         else
            oCache.strCacheDir = strCacheDir;
         end
         
         % - Find and return the global cache object, if one exists
         sUserData = get(0, 'UserData');
         if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
               isa(sUserData.BOT_GLOBAL_CACHE, 'BOT_cache') && ...
               isequal(sUserData.BOT_GLOBAL_CACHE.strVersion, oCache.strVersion) && ...
               ~exist('strCacheDir', 'var') || isempty(strCacheDir)
            
            % - A global class instance exists, and is the correct version,
            % and no "user" cache directory has been provided
            oCache = sUserData.BOT_GLOBAL_CACHE;
            return;
         end
         
         %% - Set up a cache object, if no object exists

         % - Ensure the cache directory exists
         if ~exist(oCache.strCacheDir, 'dir')
            mkdir(oCache.strCacheDir);
         end
         
         % - Populate cached filenames
         oCache.sCacheFiles.manifests = [oCache.strCacheDir filesep 'manifests.mat'];
         oCache.sCacheFiles.ccCache = bot.internal.CloudCacher(oCache.strCacheDir);
         
         % - Assign the cache object to a global cache
         sUserData.BOT_GLOBAL_CACHE = oCache;
         set(0, 'UserData', sUserData);
         
         % - Send a tracking hit to Google Analytics, once per installation
         fhGAHit = @()bot.internal.ga.event(oCache.strGATrackingID, ...
                        [], bot.internal.GetUniqueUID(), ...
                        'once-per-installation', 'cache.construct', 'bot.cache', [], ...
                        'bot', oCache.strVersion, ...
                        'matlab');
         bot.internal.call_once_ever(oCache.strCacheDir, 'first_toolbox_use', fhGAHit);

         fhGAPV = @()bot.internal.ga.collect(oCache.strGATrackingID, 'pageview', ...
             [], bot.internal.GetUniqueUID(), ...
             '', 'analytics.bot', 'first-installation/bot/cache/construct', 'First installation', ...
             [], [], [], [], [], 'bot', oCache.strVersion, 'matlab');            
         bot.internal.call_once_ever(oCache.strCacheDir, 'first_toolbox_use_pageview', fhGAPV);
         
%          % - Send a tracking hit to Google Analytics, once per session
%          fhGAHit = @()bot.internal.ga.event(oCache.strGATrackingID, ...
%                         bot.internal.GetUniqueUID(), [], ...
%                         'once-per-session', 'cache.construct', 'bot.cache', [], ...
%                         'bot', oCache.strVersion, ...
%                         'matlab');
%          bot.internal.call_once_per_session('toolbox_init_session', fhGAHit);      
      end
   end
   
   
   %% Getter and Setter methods
   
   methods
      function tOPhysSessions = get.tAllOPhysSessions(oCache)
         % METHOD - Return the table of all OPhys experimental sessions
         
         % - Fetch the ophys manifests
         if isempty(oCache.CACHED_ophys_manifests)
            oCache.CACHED_ophys_manifests = oCache.get_ophys_manifests_info_from_api();
         end
         
         % - Return sessions table
         tOPhysSessions = oCache.CACHED_ophys_manifests.ophys_session_manifest;         
      end
      
      function tOPhysContainers = get.tAllOPhysContainers(oCache)
         % METHOD - Return the table of all OPhys experimental containers
         
         % - Fetch the ophys manifests
         if isempty(oCache.CACHED_ophys_manifests)
            oCache.CACHED_ophys_manifests = oCache.get_ophys_manifests_info_from_api();
         end
         
         % - Return container table
         tOPhysContainers = oCache.CACHED_ophys_manifests.ophys_container_manifest;
      end      
      
      function tECEPhysSessions = get.tAllECEPhysSessions(oCache)
         % METHOD - Return the table of all ECEPhys experimental sessions

         % - Fetch the ecephys sessions menifest
         if isempty(oCache.CACHED_tECEPhysSessions)
            oCache.CACHED_tECEPhysSessions = oCache.get_ecephys_sessions();
         end
         
         tECEPhysSessions = oCache.CACHED_tECEPhysSessions;
         
         % - Count numbers of units, channels and probes
%          oCache.tECEPhysUnits
         
      end
      
      function tECEPhysUnits = get.tAllECEPhysUnits(oCache)
         % METHOD - Return the table of all ECEPhys recorded units

         % - Fetch the ecephys units menifest
         if isempty(oCache.CACHED_tECEPhysUnits)
            oCache.CACHED_tECEPhysUnits = oCache.get_ecephys_units();
         end
         
         % - Annotate units
         tECEPhysUnits = join(oCache.CACHED_tECEPhysUnits, oCache.tAllECEPhysChannels, ...
            'LeftKeys', 'ecephys_channel_id', 'RightKeys', 'id');
      end
      
      function tECEPhysProbes = get.tAllECEPhysProbes(oCache)
         % METHOD - Return the table of all ECEPhys recorded probes

         % - Fetch the ecephys units menifest
         if isempty(oCache.CACHED_tECEPhysProbes)
            oCache.CACHED_tECEPhysProbes = oCache.get_ecephys_probes();
         end
         
         % - Annotate probes and return
         tECEPhysProbes = join(oCache.CACHED_tECEPhysProbes, oCache.tAllECEPhysSessions, 'LeftKeys', 'ecephys_session_id', 'RightKeys', 'id');
      end
      
      function tECEPhysChannels = get.tAllECEPhysChannels(oCache)
         % METHOD - Return the table of all ECEPhys recorded channels

         % - Fetch the ecephys units menifest
         if isempty(oCache.CACHED_tECEPhysChannels)
            oCache.CACHED_tECEPhysChannels = oCache.get_ecephys_channels();
         end
         
         % - Return channels
         tECEPhysChannels = oCache.CACHED_tECEPhysChannels;      
         tECEPhysChannels = join(tECEPhysChannels, oCache.tAllECEPhysProbes, ...
            'LeftKeys', 'ecephys_probe_id', 'RightKeys', 'id');
      end
   end

   
   %% Methods to manage manifests and caching
   
   methods
      function cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs, bUseParallel, nNumTries)
         % CacheFilesForSessionIDs - METHOD Download data files containing experimental data for the given session IDs
         %
         % Usage: cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs <, bUseParallel, nNumTries>)
         %
         % `vnSessionIDs` is a list of session IDs obtained from the
         % sessions table. The data files for these sessions will be
         % downloaded and cached, if they have not already been cached.
         %
         % The optional argument `bUseParallel` allows you to specify
         % whether a pool of workers should be used to download several
         % data files simultaneously. A pool will *not* be created if one
         % does not already exist. By default, a pool will be used.
         %
         % The optional argument `nNumTries` allows you to specify how many
         % attempts should be made to download each file befire giving up.
         % Default: 3
         
         % - Default arguments
         if ~exist('bUseParallel', 'var') || isempty(bUseParallel)
             bUseParallel = true;
         end
         
         if ~exist('nNumTries', 'var') || isempty(nNumTries)
            nNumTries = 3;
         end
         
         % - Loop over session IDs
         for nSessIndex = numel(vnSessionIDs):-1:1
            % - Find this session in the sessions table
            tSession = oCache.tAllSessions(oCache.tAllSessions.id == vnSessionIDs(nSessIndex), :);
            
            % - Check to see if the session exists
            if isempty(tSession)
               error('BOT:InvalidSessionID', ...
                     'The provided session ID [%d] was not found in the Brain Observatory manifest.', ...
                     vnSessionIDs(nSessIndex));
            
            else
               % - Cache the corresponding session data files
               vs_well_known_files = tSession.well_known_files{1};
               cstrURLs{nSessIndex} = arrayfun(@(s)strcat(oCache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
               cstrLocalFiles{nSessIndex} = {vs_well_known_files.path}';
               cvbIsInCache{nSessIndex} = oCache.IsInCache(cstrURLs{nSessIndex});
            end
         end
         
         % - Consolidate all URLs to download
         cstrURLs = [cstrURLs{:}];
         cstrLocalFiles = [cstrLocalFiles{:}];
         vbIsInCache = [cvbIsInCache{:}];
         
         % - Cache all sessions in parallel
         if numel(vnSessionIDs) > 1 && bUseParallel && ~isempty(gcp('nocreate'))
            if any(~vbIsInCache)
               fprintf('Downloading URLs in parallel...\n');
            end
            
            bSuccess = false;
            while ~bSuccess && (nNumTries > 0)
               try
                  cstrCacheFiles = oCache.sCacheFiles.ccCache.pwebsave(cstrLocalFiles, [cstrURLs{:}], true);
                  bSuccess = true;
               catch
                  nNumTries = nNumTries - 1;
               end
            end
         
         else
            % - Cache sessions sequentially
            for nURLIndex = numel(cstrURLs):-1:1
               % - Provide some progress text
               if ~vbIsInCache(nURLIndex)
                  fprintf('Downloading URL: [%s]...\n', cstrURLs{nURLIndex});
               end

               % - Try to cache the data file
               bSuccess = false;
               while ~bSuccess && (nNumTries > 0)
                  try
                     cstrCacheFiles{nURLIndex} = oCache.CacheFile(cstrURLs{nURLIndex}, cstrLocalFiles{nURLIndex});
                     bSuccess = true;
                  catch mE_Cause
                     nNumTries = nNumTries - 1;
                  end
               end
               
               % - Raise an error on failure
               if ~bSuccess
                  mE_Base = MException('BOT:CouldNotCacheURL', ...
                     'A data file could not be cached.');
                  mE_Base = mE_Base.addCause(mE_Cause);
                  throw(mE_Base);
               end
            end
         end         
      end
   end
   
   %% Private methods
   
   methods (Access = {?bot.session})
      function strFile = CacheFile(oCache, strURL, strLocalFile)
         % CacheFile - METHOD Check for cached version of Brain Observatory file, and return local location on disk
         %
         % Usage: strFile = CacheFile(oCache, strURL, strLocalFile)
         
         strFile = oCache.sCacheFiles.ccCache.websave(strLocalFile, strURL);
      end
      
      function bIsInCache = IsInCache(oCache, strURL)
         % IsInCache - METHOD Is the provided URL already cached?
         %
         % Usage: bIsInCache = IsInCache(oCache, strURL)
         bIsInCache = oCache.sCacheFiles.ccCache.IsInCache(strURL);
      end
      
      function tResponse = CachedAPICall(oCache, strModel, strQueryString, nPageSize, strFormat, strRMAPrefix, strHost, strScheme)
         % CachedAPICall - METHOD Return the (hopefully cached) contents of
         % an Allen Brain Observatory API call
         
         DEF_strScheme = "http";
         DEF_strHost = "api.brain-map.org";
         DEF_strRMAPrefix = "api/v2/data";
         DEF_nPageSize = 5000;
         DEF_strFormat = "query.json";
         
         % -- Default arguments
         if ~exist('strScheme', 'var') || isempty(strScheme)
            strScheme = DEF_strScheme;
         end
         
         if ~exist('strHost', 'var') || isempty(strHost)
            strHost = DEF_strHost;
         end
         
         if ~exist('strRMAPrefix', 'var') || isempty(strRMAPrefix)
            strRMAPrefix = DEF_strRMAPrefix;
         end
         
         if ~exist('nPageSize', 'var') || isempty(nPageSize)
            nPageSize = DEF_nPageSize;
         end
         
         if ~exist('strFormat', 'var') || isempty(strFormat)
            strFormat = DEF_strFormat;
         end
         
         % - Build a URL
         strURL = string(strScheme) + "://" + string(strHost) + "/" + ...
            string(strRMAPrefix) + "/" + string(strFormat) + "?" + ...
            string(strModel);
         
         if ~isempty(strQueryString)
            strURL = strURL + "," + strQueryString;
         end
         
         % - Set up options
         options = weboptions('ContentType', 'JSON', 'TimeOut', 60);
         
         nTotalRows = [];
         nStartRow = 0;
         
         tResponse = table();
         
         while isempty(nTotalRows) || nStartRow < nTotalRows
            % - Add page parameters
            strURLQueryPage = strURL + ",rma::options[start_row$eq" + nStartRow + "][num_rows$eq" + nPageSize + "][order$eq'id']";
            
            % - Perform query
            response_raw = oCache.sCacheFiles.ccCache.webread(strURLQueryPage, [], options);
            
            % - Convert response to a table
            if isa(response_raw.msg, 'cell')
               response_page = cell_messages_to_table(response_raw.msg);
            else
               response_page = struct2table(response_raw.msg);
            end
            
            % - Append response page to table
            if isempty(tResponse)
               tResponse = response_page;
            else
               tResponse = bot.internal.merge_tables(tResponse, response_page);
            end
            
            % - Get total number of rows
            if isempty(nTotalRows)
               nTotalRows = response_raw.total_rows;
            end
            
            % - Move to next page
            nStartRow = nStartRow + nPageSize;
            
            % - Display progress if we didn't finish
            if (nStartRow < nTotalRows)
               fprintf('Downloading.... [%.0f%%]\n', round(nStartRow / nTotalRows * 100))
            end
         end
         
         function tMessages = cell_messages_to_table(cMessages)
            % - Get an exhaustive list of fieldnames
            cFieldnames = cellfun(@fieldnames, cMessages, 'UniformOutput', false);
            cFieldnames = unique(vertcat(cFieldnames{:}), 'stable');
            
            % - Make sure every message has all required field names
            function sData = enforce_fields(sData)
               vbHasField = cellfun(@(c)isfield(sData, c), cFieldnames);
               
               for strField = cFieldnames(~vbHasField)'
                  sData.(strField{1}) = [];
               end
            end
            
            cMessages = cellfun(@(c)enforce_fields(c), cMessages, 'UniformOutput', false);
            
            % - Convert to a table
            tMessages = struct2table([cMessages{:}]);
         end
      end
   end
   
   %% Private methods
   
   methods (Access = private)
      function [ophys_manifests] = get_ophys_manifests_info_from_api(oCache)
         
         % get_ophys_manifests_info_from_api - PRIVATE METHOD Download the Allen Brain Observatory manifests from the web
         %
         % Usage: [ophys_manifests] = get_ophys_manifests_info_from_api(oCache)
         %
         % Download `container_manifest`, `session_manifest`, `cell_id_mapping`
         % from brain observatory api as matlab tables. Returns the tables as fields
         % of a structure. Converts various columns to appropriate formats,
         % including categorical arrays.
         
         disp('Fetching OPhys manifests...');

         % - Specify URLs for download
         cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';         

         %% - Fetch OPhys container manifest
         ophys_manifests.ophys_container_manifest = oCache.CachedAPICall('criteria=model::ExperimentContainer', 'rma::include,ophys_experiments,isi_experiment,specimen(donor(conditions,age,transgenic_lines)),targeted_structure');
         
         %% - Fetch OPhys session manifest
         ophys_session_manifest = oCache.CachedAPICall('criteria=model::OphysExperiment', 'rma::include,experiment_container,well_known_files(well_known_file_type),targeted_structure,specimen(donor(age,transgenic_lines))');

         % - Label as ophys sessions
         ophys_session_manifest = addvars(ophys_session_manifest, ...
            repmat({'ophys'}, size(ophys_session_manifest, 1), 1), ...
            'NewVariableNames', 'BOT_session_type', ...
            'before', 1);
         
         % - Create `cre_line` variable from specimen field of session
         % manifests and append it back to session_manifest tables.
         % `cre_line` is important, makes life easier if it's explicit
         
         % - Extract from OPhys sessions manifest
         tAllSessions = ophys_session_manifest;
         cre_line = cell(size(tAllSessions, 1), 1);
         for i = 1:size(tAllSessions, 1)
            donor_info = tAllSessions(i, :).specimen.donor;
            transgenic_lines_info = struct2table(donor_info.transgenic_lines);
            cre_line(i,1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
               & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
         end
         
         ophys_session_manifest = addvars(ophys_session_manifest, cre_line, ...
            'NewVariableNames', 'cre_line');

         % - Convert experiment containiner variables to integer
         ophys_session_manifest{:, 'experiment_container_id'} = uint32(ophys_session_manifest{:, 'experiment_container_id'});
         ophys_manifests.ophys_session_manifest = ophys_session_manifest;
         
         %% - Fetch cell ID mapping
         
         options = weboptions('ContentType', 'table', 'TimeOut', 60);
         ophys_manifests.cell_id_mapping = oCache.sCacheFiles.ccCache.webread(cell_id_mapping_url, [], options);
      end

      function [ecephys_session_manifest] = get_ecephys_sessions(oCache)
         %% - Download ECEPhys session manifest
         disp('Fetching ECEPhys sessions manifest...');
         ecephys_session_manifest = oCache.CachedAPICall('criteria=model::EcephysSession', 'rma::include,specimen(donor(age)),well_known_files(well_known_file_type)');
         
         % - Label as ECEPhys sessions
         ecephys_session_manifest = addvars(ecephys_session_manifest, ...
            repmat({'ECEPhys'}, size(ecephys_session_manifest, 1), 1), ...
            'NewVariableNames', 'BOT_session_type', ...
            'before', 1);
         
         % - Post-process ECEPhys manifest
         age_in_days = arrayfun(@(s)s.donor.age.days, ecephys_session_manifest.specimen);
         cSex = arrayfun(@(s)s.donor.sex, ecephys_session_manifest.specimen, 'UniformOutput', false);
         cGenotype = arrayfun(@(s)s.donor.full_genotype, ecephys_session_manifest.specimen, 'UniformOutput', false);
         
         vbWT = cellfun(@isempty, cGenotype);
         if any(vbWT)
            cGenotype{vbWT} = 'wt';
         end
         
         cWkf_types = arrayfun(@(s)s.well_known_file_type.name, ecephys_session_manifest.well_known_files, 'UniformOutput', false);
         has_nwb = cWkf_types == "EcephysNwb";
                  
         % - Add variables
         ecephys_session_manifest = addvars(ecephys_session_manifest, age_in_days, cSex, cGenotype, has_nwb, ...
            'NewVariableNames', {'age_in_days', 'sex', 'genotype', 'has_nwb'});
         
         % - Rename variables
         ecephys_session_manifest = rename_variables(ecephys_session_manifest, "stimulus_name", "session_type");
      end
      
      function [ecephys_unit_manifest] = get_ecephys_units(oCache)
         %% Download ECEPhys units
         disp('Fetching ECEPhys units manifest...');
         ecephys_unit_manifest = oCache.CachedAPICall('criteria=model::EcephysUnit', '');
         
         % - Rename variables
         ecephys_unit_manifest = rename_variables(ecephys_unit_manifest, ...
            'PT_ratio', 'waveform_PT_ratio', ...
            'amplitude', 'waveform_amplitude', ...
            'duration', 'waveform_duration', ...
            'halfwidth', 'waveform_halfwidth', ...
            'recovery_slope', 'waveform_recovery_slope', ...
            'repolarization_slope', 'waveform_repolarization_slope', ...
            'spread', 'waveform_spread', ...
            'velocity_above', 'waveform_velocity_above', ...
            'velocity_below', 'waveform_velocity_below', ...
            'l_ratio', 'L_ratio');
         
         % - Set default filter values
         if ~exist('sFilterValues', 'var') || isempty(sFilterValues) %#ok<NODEF>
            sFilterValues.amplitude_cutoff_maximum = 0.1;
            sFilterValues.presence_ratio_minimum = 0.95;
            sFilterValues.isi_violations_maximum = 0.5;
         end
         
         % - Check filter values
         assert(isstruct(sFilterValues), ...
            'BOT:Usage', ...
            '`sFilterValues` must be a structure with fields {''amplitude_cutoff_maximum'', ''presence_ratio_minimum'', ''isi_violations_maximum''}.')
         
         if ~isfield(sFilterValues, 'amplitude_cutoff_maximum')
            sFilterValues.amplitude_cutoff_maximum = inf;
         end
         
         if ~isfield(sFilterValues, 'presence_ratio_minimum')
            sFilterValues.presence_ratio_minimum = -inf;
         end
         
         if ~isfield(sFilterValues, 'isi_violations_maximum')
            sFilterValues.isi_violations_maximum = inf;
         end
         
         % - Filter units
         ecephys_unit_manifest = ...
            ecephys_unit_manifest(ecephys_unit_manifest.amplitude_cutoff <= sFilterValues.amplitude_cutoff_maximum & ...
            ecephys_unit_manifest.presence_ratio >= sFilterValues.presence_ratio_minimum & ...
            ecephys_unit_manifest.isi_violations <= sFilterValues.isi_violations_maximum, :);
         
         if any(ecephys_unit_manifest.Properties.VariableNames == "quality")
            ecephys_unit_manifest = ecephys_unit_manifest(ecephys_unit_manifest.quality == "good", :);
         end
         
         if any(ecephys_unit_manifest.Properties.VariableNames == "ecephys_structure_id")
            ecephys_unit_manifest = ecephys_unit_manifest(~isempty(ecephys_unit_manifest.ecephys_structure_id), :);
         end
      end
      
      function [ecephys_probes_manifest] = get_ecephys_probes(oCache)
         %% Download ECEPhys probes
         disp('Fetching ECEPhys probes manifest...');
         ecephys_probes_manifest = oCache.CachedAPICall('criteria=model::EcephysProbe', '');
         
         % - Rename variables
         ecephys_probes_manifest = rename_variables(ecephys_probes_manifest, ...
            "use_lfp_data", "has_lfp_data");
      end
      
      function [ecephys_channels_manifest] = get_ecephys_channels(oCache)
         %% Download ECEPhys channels
         disp('Fetching ECEPhys channels manifest...');
         ecephys_channels_manifest = oCache.CachedAPICall('criteria=model::EcephysChannel', "rma::include,structure,rma::options[tabular$eq'ecephys_channels.id,ecephys_probe_id,local_index,probe_horizontal_position,probe_vertical_position,anterior_posterior_ccf_coordinate,dorsal_ventral_ccf_coordinate,left_right_ccf_coordinate,structures.id as ecephys_structure_id,structures.acronym as ecephys_structure_acronym']");
         
         % - Convert columns to reasonable formats
         id = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.id, 'UniformOutput', false)));
         ecephys_probe_id = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.ecephys_probe_id, 'UniformOutput', false)));
         local_index = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.local_index, 'UniformOutput', false)));
         probe_horizontal_position = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.probe_horizontal_position, 'UniformOutput', false)));
         probe_vertical_position = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.probe_vertical_position, 'UniformOutput', false)));
         anterior_posterior_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.anterior_posterior_ccf_coordinate, 'UniformOutput', false)));
         dorsal_ventral_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.dorsal_ventral_ccf_coordinate, 'UniformOutput', false)));
         left_right_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ecephys_channels_manifest.left_right_ccf_coordinate, 'UniformOutput', false)));
         
         es_id = ecephys_channels_manifest.ecephys_structure_id;
         ecephys_structure_id(~cellfun(@isempty, es_id)) = cellfun(@str2num, es_id(~cellfun(@isempty, es_id)), 'UniformOutput', false);
         ecephys_structure_id(cellfun(@isempty, es_id)) = {[]};
         ecephys_structure_id = ecephys_structure_id';
         
         ecephys_structure_acronym = ecephys_channels_manifest.ecephys_structure_acronym;
         
         % - Rebuild table
         ecephys_channels_manifest = table(id, ecephys_probe_id, local_index, ...
            probe_horizontal_position, probe_vertical_position, ...
            anterior_posterior_ccf_coordinate, dorsal_ventral_ccf_coordinate, ...
            left_right_ccf_coordinate, ecephys_structure_id, ecephys_structure_acronym);
      end
   end
end

function tMessages = cell_messages_to_table(cMessages)
   % - Get an exhaustive list of fieldnames
   cFieldnames = cellfun(@fieldnames, cMessages, 'UniformOutput', false);
   cFieldnames = unique(vertcat(cFieldnames{:}), 'stable');
   
   % - Make sure every message has all required field names
   function sData = enforce_fields(sData)
      vbHasField = cellfun(@(c)isfield(sData, c), cFieldnames);
      
      for strField = cFieldnames(~vbHasField)'
         sData.(strField{1}) = [];
      end
   end

   cMessages = cellfun(@(c)enforce_fields(c), cMessages, 'UniformOutput', false);
   
   % - Convert to a table
   tMessages = struct2table([cMessages{:}]);
end

function tRename = rename_variables(tRename, varargin)

for nVar = 1:2:numel(varargin)
   vbVarIndex = tRename.Properties.VariableNames == string(varargin{nVar});
   if any(vbVarIndex)
      tRename.Properties.VariableNames(vbVarIndex) = string(varargin{nVar + 1});
   end
end

end

function count_unique
end
