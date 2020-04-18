%% CLASS bot.internal.cache - Cache and cloud access class for Brain Observatory Toolbox
%
% This class is used internally by the Brain Observatory Toolbox to access
% data from the Allen Brain Observatory resource [1] via the Allen Brain
% Atlas API [2].
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits
% [2] Copyright 2015 Allen Brain Atlas API. Allen Brain Observatory. Available from: brain-map.org/api/index.html

%% Class definition
classdef cache < handle
   
   properties (SetAccess = immutable)
      strVersion = '0.5';              % Version string for cache class
   end
   
   properties (SetAccess = private)
      strCacheDir;                     % Path to location of cached data from the Allen Brain Observatory resource
      ccCache;                         % Cloud data cache
      ocCache;                         % Object cache
   end
   
   properties
      strABOBaseUrl = 'http://api.brain-map.org';  % Base URL for the Allen Brain Observatory resource
   end
   
   %% Constructor
   methods
      function oCache = cache(strCacheDir)
         % CONSTRUCTOR - Returns an object for managing data access from an Allen Brain Observatory dataset
         %
         % Usage: oCache = bot.internal.cache(<strCacheDir>)
         
         % - Check if a cache directory has been provided
         if ~exist('strCacheDir', 'var') || isempty(strCacheDir)
            % - Get the default cache directory
            strBOTDir = fileparts(which('bot.manifest'));
            oCache.strCacheDir = [strBOTDir filesep 'Cache'];
         else
            oCache.strCacheDir = strCacheDir;
         end
         
         % - Find and return the global cache object, if one exists
         sUserData = get(0, 'UserData');
         if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
               isa(sUserData.BOT_GLOBAL_CACHE, 'bot.cache') && ...
               isequal(sUserData.BOT_GLOBAL_CACHE.strVersion, oCache.strVersion) && ...
               (~exist('strCacheDir', 'var') || isempty(strCacheDir))
            
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
         
         % - Set up cloud and ojbect caches
         oCache.ccCache = bot.internal.CloudCacher(oCache.strCacheDir);
         oCache.ocCache = bot.internal.ObjectCacher(oCache.strCacheDir);         

         % - Assign the cache object to a global cache
         sUserData.BOT_GLOBAL_CACHE = oCache;
         set(0, 'UserData', sUserData);
      end
   end
   
   %% Methods to manage manifests and caching
   
   methods
      function cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs, bUseParallel, nNumTries)
         % CacheFilesForSessionIDs - METHOD Download data files containing experimental data for the given session IDs
         %
         % Usage: cstrCacheFiles = CacheFilesForSessionIDs(oCache, vnSessionIDs <, bUseParallel, nNumTries>)
         %
         % `vnSessionIDs` is a list of session IDs obtained from either the
         % OPhys or EPhys sessions table. The data files for these
         % sessions will be downloaded and cached, if they have not already
         % been cached.
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
            % - Find this session in the sessions tables
            vbOPhysSession = oCache.tOPhysSessions.id == vnSessionIDs(nSessIndex);
            
            if any(vbOPhysSession)
               tSession = oCache.tOPhysSessions(vbOPhysSession, :);
            else
               vbEPhysSession = oCache.tEPhysSessions.id == vnSessionIDs(nSessIndex);
               tSession = oCache.tEPhysSessions(vbEPhysSession, :);
            end
            
            % - Check to see if the session exists
            if isempty(tSession)
               error('BOT:InvalidSessionID', ...
                  'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
                  vnSessionIDs(nSessIndex));
               
            else
               % - Cache the corresponding session data files
               if iscell(tSession.well_known_files)
                  vs_well_known_files = tSession.well_known_files{1};
               else
                  vs_well_known_files = tSession.well_known_files;
               end
               cstrURLs{nSessIndex} = arrayfun(@(s)strcat(oCache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
               cstrLocalFiles{nSessIndex} = {vs_well_known_files.path}';
               cvbIsURLInCache{nSessIndex} = oCache.IsURLInCache(cstrURLs{nSessIndex});
            end
         end
         
         % - Consolidate all URLs to download
         cstrURLs = [cstrURLs{:}];
         cstrLocalFiles = [cstrLocalFiles{:}];
         vbIsURLInCache = [cvbIsURLInCache{:}];
         
         % - Cache all sessions in parallel
         if numel(vnSessionIDs) > 1 && bUseParallel && ~isempty(gcp('nocreate'))
            if any(~vbIsURLInCache)
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
               if ~vbIsURLInCache(nURLIndex)
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
      
      function InsertObject(oCache, strKey, object)
         % InsertObject - METHOD Insert an object into the object cache
         %
         % Usage: oCache.Insert(strKey, object)
         %
         % `strKey` is a string, which will be associated with the object
         % in the cache. You should take care that the key is unique
         % enough.
         %
         % `object` is an arbitrary MATLAB object, that can be serialised
         % and saved.
         %
         % `object` will be inserted into the object cache, and can be
         % retrieved later using `strKey`.
         
         oCache.ocCache.Insert(strKey, object);
      end
      
      function object = RetrieveObject(oCache, strKey)
         % RetrieveObject - METHOD Retrieve an object (key) from the object cache
         %
         % Usage: object = oCache.Rerieve(strKey)
         %
         % `strKey` is a string which identifies an object in the cache.
         %
         % If the key `strKey` exists in the cache, the corresponding
         % object will be retrieved. Otherwise an error will be raised.
         
         object = oCache.ocCache.Retrieve(strKey);
      end
      
      function bIsInCache = IsObjectInCache(oCache, strKey)
         % IsObjectInCache - METHOD Check if an object (key) is in the object cahce
         %
         % Usage: bIsInCache = oCache.IsObjectInCache(strKey)
         %
         % `strKey` is a string to be queried in the object cache. If the
         % key exists in the cache, then `True` is returned. Otherwise
         % `False` is returned.
         
         bIsInCache = oCache.ocCache.IsInCache(strKey);
      end
      
      function RemoveObject(oCache, strKey)
         % RemoveObject - METHOD Remove an object (key) from the object cache
         %
         % Usage: oCache.RemoveObject(strKey)
         %
         % `strKey` is a string identifying an object key. If the key
         % exists in the cache, then the corresponding object data will be
         % removed form the cache.

         oCache.ocCache.Remove(strKey);
      end
      
      function strFile = CacheFile(oCache, strURL, strLocalFile)
         % CacheFile - METHOD Check for cached version of Allen Brain Observatory dataset file, and return local location on disk
         %
         % Usage: strFile = oCache.CacheFile(strURL, strLocalFile)
         
         strFile = oCache.ccCache.websave(strLocalFile, strURL);
      end
      
      function bIsURLInCache = IsURLInCache(oCache, strURL)
         % IsURLInCache - METHOD Is the provided URL already cached?
         %
         % Usage: bIsURLInCache = oCache.IsURLInCache(strURL)
         
         bIsURLInCache = oCache.ccCache.IsInCache(strURL);
      end
      
      function tResponse = CachedAPICall(oCache, strModel, strQueryString, nPageSize, strFormat, strRMAPrefix, strHost, strScheme)
         % CachedAPICall - METHOD Return the (hopefully cached) contents of an Allen Brain Atlas API call
         %
         % Usage: tResponse = CachedAPICall(oCache, strModel, strQueryString, ...)
         %        tResponse = CachedAPICall(..., <nPageSize>, <strFormat>, <strRMAPrefix>, <strHost>, <strScheme>)
         
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
            
            % - Was there an error?
            if ~response_raw.success
               error('BOT:DataAccess', 'Error querying Allen Brain Atlas API for URL [%s]', strURLQueryPage);
            end
            
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
               fprintf('Fetching.... [%.0f%%]\n', round(nStartRow / nTotalRows * 100))
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
end

