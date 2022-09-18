%% CLASS bot.internal.cache - Cache and cloud access class for Brain Observatory Toolbox
%
% This class is used internally by the Brain Observatory Toolbox to access
% data from the Allen Brain Observatory resource [1] via the Allen Brain
% Atlas API [2].
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits
% [2] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: brain-map.org/api/index.html

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
                if ~oCache.HasPreferredCacheDirectory()
                    strCacheDir = oCache.InitializePreferredCacheDirectory();
                else
                    strCacheDir = oCache.GetPreferredCacheDirectory();
                end
            else
                % strCacheDir is provided and is not empty!
            end

            oCache.strCacheDir = strCacheDir;

            % - Find and return the global cache object, if one exists
            sUserData = get(0, 'UserData');
            if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
                    isa(sUserData.BOT_GLOBAL_CACHE, 'bot.internal.cache') && ...
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
            
            % - Set up cloud and object caches
            oCache.ccCache = bot.internal.CloudCacher(oCache.strCacheDir);
            oCache.ocCache = bot.internal.ObjectCacher(oCache.strCacheDir);
            
            % - Assign the cache object to a global cache
            sUserData.BOT_GLOBAL_CACHE = oCache;
            set(0, 'UserData', sUserData);
        end
    end
    
    %% Methods to manage manifests and caching
    methods
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
            % Usage: object = oCache.Retrieve(strKey)
            %
            % `strKey` is a string which identifies an object in the cache.
            %
            % If the key `strKey` exists in the cache, the corresponding
            % object will be retrieved. Otherwise an error will be raised.
            
            object = oCache.ocCache.Retrieve(strKey);
        end
        
        function bIsInCache = IsObjectInCache(oCache, strKey)
            % IsObjectInCache - METHOD Check if an object (key) is in the object cache
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
        
        function ClearObjectCache(oCache)
           keys = oCache.ocCache.mapCachedData.keys();
           
           for key = string(keys)
               oCache.RemoveObject(key);
           end
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
        
        function tResponse = CachedAPICall(oCache, strModel, strQueryString, nPageSize, strFormat, strRMAPrefix, strHost, strScheme, strID)
            % CachedAPICall - METHOD Return the (hopefully cached) contents of an Allen Brain Atlas API call
            %
            % Usage: tResponse = CachedAPICall(oCache, strModel, strQueryString, ...)
            %        tResponse = CachedAPICall(..., <nPageSize>, <strFormat>, <strRMAPrefix>, <strHost>, <strScheme>, <strID>)
            
            DEF_strScheme = "http";
            DEF_strHost = "api.brain-map.org";
            DEF_strRMAPrefix = "api/v2/data";
            DEF_nPageSize = 5000;
            DEF_strFormat = "query.json";
            DEF_strID = "id";
            
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
            
            if ~exist('strID', 'var') || isempty(strID)
                strID = DEF_strID;
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
                strURLQueryPage = strURL + ",rma::options[start_row$eq" + nStartRow + "][num_rows$eq" + nPageSize + "][order$eq'" + strID + "']";
                
                % - Perform query
                response_raw = oCache.ccCache.webread(strURLQueryPage, [], options);
                
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

    %% Methods to get preferred or default cache directory
    methods (Static, Access = private)
        
        function tf = HasPreferredCacheDirectory()
        %HasPreferredCacheDirectory Check if a preferred cache directory exists
            tf = ispref('BrainObservatoryToolbox', 'CacheDirectory');
        end

        function strCacheDir = InitializePreferredCacheDirectory()
        %InitializePreferredCacheDirectory Let user configure a cache directory
        %   
        %   A method that opens a question dialog box for a user to select
        %   whether to configure a preferred directory for downloaded data
        %   (cache) or to use a factory (default) directory. If the user
        %   answers "Yes" on the prompt, a folder selection dialog box
        %   opens. Before returning, the selected directory (custom or
        %   factory) is added to the BrainObservatoryToolbox' preferences.
        %   
        %   This method was introduced 2022-09-04. For backwards
        %   compatibility; if a factory directory for cached data exists on
        %   the file system, this method returns immediately.
            
            factoryCacheDir = bot.internal.cache.GetFactoryCacheDirectory();
            
            % If the factory cache directory already exists, the Brain 
            % Observatory Toolbox has been used on this computer prior to the
            % introduction of a preferred cache directory. Return here and
            % use the factory setting.
            if isfolder(factoryCacheDir)
                strCacheDir = factoryCacheDir; return
            end
            
            % - Construct a question dialog box where user can select if 
            % he/she wants to configure a custom folder for downloaded
            % data.
            promptMessage = sprintf(['This is the first time you run ', ...
                'the Brain Observatory Toolbox. Do you want to ', ...
                'configure a directory for saving downloaded data?\n\n', ...
                'If you select "No", data will be downloaded to the ', ...
                'following directory:\n \\bf%s'], factoryCacheDir);

            % - Format the message with a bigger font size
            formattedMessage = strcat('\fontsize{14}', promptMessage);
            
            % - Fix some characters that are interpreted as tex markup
            formattedMessage = strrep(formattedMessage, '_', '\_');
            titleMessage = 'Select Download Directory for Data?'; 

            % - Use the tex-interpreter for displaying the prompt message.
            opts = struct('Default', 'Yes', 'Interpreter', 'tex');
            
            % - Present the question to the user
            answer = questdlg(formattedMessage, titleMessage, opts);
            
            % - Handle answer
            switch answer
                case 'Yes'
                    strCacheDir = bot.internal.cache.UiGetCacheDirectory();
                case 'No'
                    strCacheDir = factoryCacheDir;
                case 'Cancel'
                    error('BOT:InitializeCacheDirectory', ...
                        'User canceled during configuration of a preferred cache directory.')
            end

            % - Store the selected cache directory to preferences
            setpref('BrainObservatoryToolbox', 'CacheDirectory', strCacheDir)
        end
        
        function strCacheDir = GetFactoryCacheDirectory()
        %GetFactoryCacheDirectory Get the BOT default (factory) cache directory    
            strBOTDir = fileparts(which('bot.fetchSessions'));
            strCacheDir = fullfile(strBOTDir, 'Cache');
        end

        function strCacheDir = GetPreferredCacheDirectory()
        %GetPreferredCacheDirectory Get the preferred cache directory from
        %the BrainObservatoryToolbox preferences.

            strCacheDir = getpref('BrainObservatoryToolbox', 'CacheDirectory');
            
            if ~isfolder(strCacheDir)
                error('BOT:PreferredCacheDirectoryMissing', ...
                    'The preferred cache directory is unavailable:\n%s', strCacheDir)
            end

            % Add suggested actions?
            % Do you want to set a new cache directory?

        end

        function SetPreferredCacheDirectory(strCacheDir)
        %SetPreferredCacheDirectory Set the preferred cache directory in
        %the BrainObservatoryToolbox preferences.
        %
        %   Usage: bot.internal.cache.SetPreferredCacheDirectory(strCacheDir)
        %
        %   `strCacheDir` is a string specifying the path for a directory
        %   to use as the preferred directory for downloaded data (cache).

            setpref('BrainObservatoryToolbox', 'CacheDirectory', strCacheDir)
        end

        function strCacheDir = UiGetCacheDirectory()
        %UiGetCacheDirectory Open folder selection dialog for selecting a  cache directory.
        
            strCacheDir = uigetdir();

            if strCacheDir == 0
                error('BOT:InitializeCacheDirectory', ...
                    'User canceled during selection of a preferred cache directory.')
            end
        end

    end

end

