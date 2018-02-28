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
      bManifestsLoaded = false;              % Flag that indicates whether manifests have been loaded
      manifests;                             % Structure containing Allen Brain Observatory manifests
   end

   properties (Access = {?bot.cache, ?bot.session})
      strGATrackingID = 'UA-114632844-1';    % Tracking ID for Google Analytics
   end      
   
   properties
      strABOBaseUrl = 'http://api.brain-map.org';  % Base URL for Allen Brain Observatory
   end
   
   %% Constructor
   methods
      function oCache = cache
         % CONSTRUCTOR - Returns an object for managing data access to the Allen Brain Observatory
         %
         % Usage: oCache = bot.cache()
         
         % - Find and return the global cache object, if one exists
         sUserData = get(0, 'UserData');
         if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
               isa(sUserData.BOT_GLOBAL_CACHE, 'BOT_cache') && ...
               isequal(sUserData.BOT_GLOBAL_CACHE.strVersion, oCache.strVersion)
            
            % - A global class instance exists, and is the correct version
            oCache = sUserData.BOT_GLOBAL_CACHE;
            return;
         end
         
         %% - Set up a cache object, if no object exists
         
         % - Get the cache directory
         strBOTDir = fileparts(which('bot.cache'));
         oCache.strCacheDir = [strBOTDir filesep 'Cache'];
         
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
                        bot.internal.GetUniqueUID(), [], ...
                        'once-per-installation', 'cache.construct', 'bot.cache', [], ...
                        'bot', oCache.strVersion, ...
                        'matlab');
         bot.internal.call_once_ever(oCache.strCacheDir, 'first_toolbox_use', fhGAHit);

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
      function cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs, bUseParallel)
         % CacheFilesForSessionIDs - METHOD Download NWB files containing experimental data for the given session IDs
         %
         % Usage: cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs <, bUseParallel>)
         %
         % `vnSessionIDs` is a list of session IDs obtained from the
         % sessions table. The NWB data files for these sessions will be
         % downloaded and cached, if they have not already been cached.
         %
         % The optional argument `bUseParallel` allows you to specify
         % whether a pool of workers should be used to download several
         % data files simultaneously. A pool will *not* be created if one
         % does not already exist. By default, a pool will be used.
         
         % - Default arguments
         if ~exist('bUseParallel', 'var') || isempty(bUseParallel)
             bUseParallel = true;
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
               % - Cache the corresponding NWB file
               cstrURLs{nSessIndex} = [oCache.strABOBaseUrl tSession.well_known_files.download_link];
               cstrLocalFiles{nSessIndex} = tSession.well_known_files.path;
               vbIsInCache(nSessIndex) = oCache.IsInCache(cstrURLs{nSessIndex});
               if vbIsInCache(nSessIndex)
                cstrCacheFiles{nSessIndex} = oCache.sCacheFiles.ccCache.CachedFileForURL(cstrURLs{nSessIndex});
               end
            end
         end
         
         % - Can we exit immediately, if all sessions are cached?
         if all(vbIsInCache)
             return;
         end
         
         % - Cache all sessions in parallel
         if numel(vnSessionIDs) > 1 && bUseParallel && ~isempty(gcp('nocreate'))
            fprintf('Downloading URLs in parallel...\n');
            cstrCacheFiles = oCache.sCacheFiles.ccCache.pwebsave(cstrLocalFiles, cstrURLs, true);
         
         else
            % - Cache sessions sequentially
            for nSessIndex = numel(vnSessionIDs):-1:1
               try
                  % - Provide some progress text
                  if ~vbIsInCache(nSessIndex)
                     fprintf('Downloading URL: [%s]...\n', cstrURLs{nSessIndex});
                  end
                  
                  % - Try to cache the NWB file
                  cstrCacheFiles{nSessIndex} = oCache.CacheFile(cstrURLs{nSessIndex}, cstrLocalFiles{nSessIndex});
                  
               catch mE_Cause
                  % - Raise an error on failure
                  mE_Base = MException('BOT:CouldNotCacheURL', ...
                     'The NWB file for a session ID [%d] could not be cached.', ...
                     vnSessionIDs(nSessIndex));
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
               oCache.manifests = bot.cache.UpdateManifest();
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
      
   end
      
   %% Static class methods
   
   methods (Static)
      function manifests = UpdateManifest
         % STATIC METHOD - Check and update file manifest from Allen Brain Observatory API
         %
         % Usage: manifests = bot.cache.UpdateManifest()
         
         % TODO: Only download the manifest if it has been updated
         
         try
            % - Get a cache object
            oCache = bot.cache();
            
            % - Download the manifest from the Allen Brain API
            fprintf('Downloading Allen Brain Observatory manifests...\n');
            manifests = bot.cache.get_manifests_info_from_api();
            
            % - Save the manifest to the cache directory
            save(oCache.sCacheFiles.manifests, 'manifests');
            
            % - Invalidate local manifests cache
            oCache.bManifestsLoaded = false;
         
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
   end
end   
   