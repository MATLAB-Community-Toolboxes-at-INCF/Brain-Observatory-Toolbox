%% CLASS bot.behavior.internal.Cache - Cache and cloud access class for Brain Observatory Toolbox
%
% This class is used internally by the Brain Observatory Toolbox to access
% data from the Allen Brain Observatory resource [1] via the Allen Brain
% Atlas API [2].
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits
% [2] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: brain-map.org/api/index.html

% Changes from bot.internal.cache:
% - Inherits from bot.behavior.internal.cache.CloudCacher
% - Use modified bot.behavior.internal.cache.CloudCacher
% - Add getPathForFile, getCacheKeyForFile, getTargetPath,
%   detectRetrievalMode methods


%% Class definition
classdef Cache < handle & bot.internal.fileresource.mixin.HasFileResource

    % - This class provides a singleton instance of a cache.
    % - It provides a single interface to the CloudCache and ObjectCache
    %   classes
    % - It interacts with the file resource classes to find the urls
    %   for remote files.



    properties (SetAccess = private)
        % Path to location of cached data from the Allen Brain Observatory resource
        CacheDirectory (1,1) string = ""
        
        % CloudCacher instance. This instance manages a map of cached data
        % files for the Allen Brain Observatory resource.
        CloudCacher (1,1) bot.behavior.internal.cache.CloudCacher

        % ObjectCacher instance. This instance manages a map for cached
        % metadata files (item tables) for the Allen Brain Observatory resource
        ObjectCacher (1,1) bot.internal.ObjectCacher % Object cache
    end

    properties (Access = private)
        % Path to location of cached data from the Allen Brain Observatory 
        % resource. The scratch directory will be used in situations
        % where the CacheDirectory is unsuitable, i.e on MATLAB Online. See
        % the Brain-Observatory-Toolbox Wiki for more details
        ScratchDirectory (1,1) string = ""
    end

    properties (Access = public)
        APIClient = bot.internal.BrainObservatoryAPI
        strABOBaseUrl = 'http://api.brain-map.org';  % Base URL for the Allen Brain Observatory resource
    end

    properties (Constant, Access = private)
        Version (1,1) string = "0.5"    % Version string for cache class
    end

    % Method for retrieving singleton instance
    methods (Static) 
        function obj = instance()
        %instance Return a singleton instance of the BOT Cache
            
            persistent cacheObject % Singleton instance
            
            % - If cache object exists, check that version is correct
            if ~isempty(cacheObject) && isvalid(cacheObject)
                if cacheObject.Version ~= bot.behavior.internal.Cache.Version
                    warning('BOT:Cache:NonMatchingVersion', ...
                        ['The existing cache singleton instance does not ' ...
                        'match the version of \nthe bot.behavior.internal.Cache ', ...
                        'class. The cache will be reinitialized.'])
                    delete(cacheObject)
                    cacheObject = [];
                end
            end

            % - Construct the cache if singleton instance is not present
            if isempty(cacheObject)
                cacheObject = bot.behavior.internal.Cache();
            end

            % - Return the instance
            obj = cacheObject; 
        end
    end

    % Constructor
    methods (Access = private)
        function obj = Cache()
            % CONSTRUCTOR - Returns an object for managing data access from an Allen Brain Observatory dataset
            %
            % Usage: obj = bot.behavior.internal.Cache(<strCacheDir>)
            
            
            % - Check if a cache directory has been provided
            if ~obj.hasPreferredCacheDirectory()
                strCacheDir = obj.initializePreferredCacheDirectory();
            else
                strCacheDir = obj.getPreferredCacheDirectory();
            end

            obj.CacheDirectory = strCacheDir;

            %% - Set up a cache object, if no object exists
            
            % - Ensure the cache directory exists
            if ~exist(obj.CacheDirectory, 'dir')
                mkdir(obj.CacheDirectory);
            end

            % Use scratch directory?
            strScratchDir = obj.getScratchDirectory(obj.CacheDirectory);
            
            % - Set up cloud and object caches
            obj.CloudCacher = bot.behavior.internal.cache.CloudCacher(strScratchDir);
            obj.ObjectCacher = bot.internal.ObjectCacher(obj.CacheDirectory);
        end
    end
    
    % Methods to manage manifests and caching
    methods

        function filePath = getPathForFile(obj, fileNickname, itemObject, options)
        % getPathForFile - Get path for data file

        % Todo: rename to fetch file?

            arguments
                obj
                fileNickname
                itemObject
                options.AutoDownload = false
            end

            fileKey = obj.getCacheKeyForFile(itemObject, fileNickname);

            isCached = obj.IsURLInCache(fileKey);

            % % if ~isCached && strcmp(bot.internal.Preferences.getPreferenceValue("DownloadMode"), "Variable")
            % %     setenv("AWS_DEFAULT_REGION", "us-west-2");
            % %     filePath = obj.getFileUrl(itemObject, fileNickname);

            if ~isCached && options.AutoDownload
                downloadUrl = obj.getFileUrl(itemObject, fileNickname);
                %if strncmp(downloadUrl, 's3', 2)
                targetFilePath = obj.getTargetPath(downloadUrl);
                filePath = obj.CacheFile(downloadUrl, targetFilePath, ...
                    'CacheKey', fileKey, 'FileNickname', fileNickname);

            elseif ~isCached
                % Todo: Return missing instead of ""
                filePath = "";
            else
                filePath = obj.CloudCacher.getCachedFilePathForKey(fileKey);
            end
        end

        function insertObject(obj, strKey, object)
            % insertObject - METHOD Insert an object into the object cache
            %
            % Usage: obj.insertObject(strKey, object)
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
            
            obj.ObjectCacher.insert(strKey, object);
        end
        
        function object = retrieveObject(obj, strKey)
            % retrieveObject - METHOD Retrieve an object (key) from the object cache
            %
            % Usage: object = obj.retrieveObject(strKey)
            %
            % `strKey` is a string which identifies an object in the cache.
            %
            % If the key `strKey` exists in the cache, the corresponding
            % object will be retrieved. Otherwise an error will be raised.
            
            object = obj.ObjectCacher.retrieve(strKey);
        end
        
        function bIsInCache = isObjectInCache(obj, strKey)
            % isObjectInCache - METHOD Check if an object (key) is in the object cache
            %
            % Usage: bIsInCache = obj.isObjectInCache(strKey)
            %
            % `strKey` is a string to be queried in the object cache. If the
            % key exists in the cache, then `True` is returned. Otherwise
            % `False` is returned.
            
            bIsInCache = obj.ObjectCacher.isInCache(strKey);
        end
        
        function removeObject(obj, strKey)
            % removeObject - METHOD Remove an object (key) from the object cache
            %
            % Usage: obj.removeObject(strKey)
            %
            % `strKey` is a string identifying an object key. If the key
            % exists in the cache, then the corresponding object data will be
            % removed form the cache.
            
            obj.ObjectCacher.remove(strKey);
        end
        
        function clearObjectCache(obj)
           obj.ObjectCacher.removeAll();
        end
        
        function strFile = CacheFile(obj, downloadUrl, cachedFilePath, strSecondaryFilePath, options)
            % CacheFile - METHOD Check for cached version of Allen Brain Observatory dataset file, and return local location on disk
            %
            % Usage: 
            %     strFile = obj.CacheFile(strFileURL, strLocalFile)
            %     get filepath (strFile) for a file in the local cache. 
            %     File is downloaded if from the specified file url 
            %     (strFileUrl) if it does not exist in the local cache.
            %
            % Extended usage:
            %     strFile = obj.CacheFile(strFileURL, strLocalFile, strSecondaryFileURL)
            %     file is downloaded from a secondary file url. This
            %     version is used if the file should be downloaded from the
            %     ABO S3 bucket using the https protocol.
            %   
            %     strFile = obj.CacheFile(strFileURL, strLocalFile, strSecondaryFileURL, options)
            %
            %     options:
            %       - RetrievalMode : Mode for file retrieval if file is not in cache. 
            %                         Options: "Download" (default) or "Copy"
            
            arguments
                obj                              % cache object 
                downloadUrl                          % Primary URL for downloading file 
                cachedFilePath                        % Path to local cache location of file
                strSecondaryFilePath = ""           % Path or URL to retrieve file from secondary location (alternative to primary location)
                options.RetrievalMode = "Download"  % Mode for file retrieval if file is not in cache. Options: 'Download' or 'Copy'
                options.CacheKey = ""
                options.FileNickname = ""
            end
            
            %retrievalMode = obj.detectRetrievalMode(downloadUrl);
            
            if options.RetrievalMode == "Copy" && strSecondaryFilePath ~= ""
                strFile = obj.CloudCacher.copyfile(downloadUrl, cachedFilePath, strSecondaryFilePath);
            else
                nvPairs = namedargs2cell( rmfield(options, 'RetrievalMode') );
                strFile = obj.CloudCacher.websave(cachedFilePath, downloadUrl, nvPairs{:});
            end
        end
        
        function bIsURLInCache = IsURLInCache(obj, strURL)
            % IsURLInCache - METHOD Is the provided URL already cached?
            %
            % Usage: bIsURLInCache = obj.IsURLInCache(strURL)
            
            bIsURLInCache = obj.CloudCacher.isInCache(strURL);
        end
                    
        function tResponse = CachedRMAQuery(obj, rmaQueryUrl, options)
             
            arguments
                obj bot.behavior.internal.Cache % Object of this class
                rmaQueryUrl string
                options.PageSize = 5000
                options.SortingAttributeName = "id"
            end

            % - Set up options for http request
            requestOptions = weboptions('ContentType', 'JSON', 'TimeOut', 60);
            
            nTotalRows = [];
            nStartRow = 0;
            
            tResponse = table();
            
            while isempty(nTotalRows) || nStartRow < nTotalRows
                
                % - Add page parameters                
                queryOptions = obj.APIClient.getRMAPagingOptions(nStartRow, ...
                    options.PageSize, options.SortingAttributeName);

                strURLQueryPage = strjoin([rmaQueryUrl, queryOptions], ",");
                
                % - Perform query
                response_raw = obj.CloudCacher.webread(strURLQueryPage, [], requestOptions);
                
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
                nStartRow = nStartRow + options.PageSize;
                
                % - Display progress if we didn't finish
                if (nStartRow < nTotalRows)
                    fprintf('Fetching.... [%.0f%%]\n', round(nStartRow / nTotalRows * 100))
                end
            end
            
            function tMessages = cell_messages_to_table(cMessages)
                import bot.internal.util.structcat
                structArray = structcat(1, cMessages{:});
                tMessages = struct2table(structArray);
            end
        end
        
        function tResponse = CachedAPICall(obj, strModel, strQueryString, nPageSize, strFormat, strRMAPrefix, strHost, strScheme, strID)
            % CachedAPICall - METHOD Return the (hopefully cached) contents of an Allen Brain Map API call
            %
            % Usage: tResponse = CachedAPICall(obj, strModel, strQueryString, ...)
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

            tResponse = obj.CachedRMAQuery(strURL, 'PageSize', nPageSize, ...
                'SortingAttributeName', strID);
        end
    end

    methods (Access = ?bot.internal.Preferences)

        function changeCacheDirectory(obj, directoryPath)
            
            obj.CacheDirectory = directoryPath;
            obj.CloudCacher.changeCacheDirectory(directoryPath)
            obj.ObjectCacher.changeCacheDirectory(directoryPath)
                        
            % Need to reset the in-memory cache if this value is updated.
            obj.clearMetadataManifests()
        end

        function changeScratchDirectory(obj, directoryPath)
            obj.ScratchDirectory = directoryPath;
            obj.CloudCacher.changeCacheDirectory(obj.CacheDirectory)
        end
        
    end

    methods (Static, Access = private)
        
        function fileKey = getCacheKeyForFile(itemObject, fileNickname)

            datasetName = itemObject.getDatasetName();
            datasetType = itemObject.getDatasetType();

            % Todo Will this be universal? I.e ophys session id is not 
            % unique for the ophys nwb files :
            itemId = string(itemObject.id);
            
            fileKey = sprintf('%s_%s_%s_%s', ...
                datasetName, ...
                datasetType, ...
                fileNickname, ...
                itemId);
            fileKey = lower(fileKey);
        end

        function targetFilePath = getTargetPath(downloadUrl)
            uri = matlab.net.URI(downloadUrl);
            targetFilePath = fullfile(uri.Path{:});
        end

        function retrievalMode = detectRetrievalMode(downloadUrl)
            uri = matlab.net.URI(downloadUrl);
            
            if uri.Scheme == "file" || uri.Scheme == "s3"
                retrievalMode = "Copy";

            elseif uri.Scheme == "https"
                retrievalMode = "Download";

            else
                error('BOT:Cache', 'Unsupported url')
            end
        end


    end

    methods (Static) % Methods for reseting or clearing cache
        
        function clearMetadataManifests()
            % Clear the Ephys- and OphysManifest singleton instances
            bot.item.internal.EphysManifest.instance("clear")
            bot.item.internal.OphysManifest.instance("clear")
        end
        
        function clearInMemoryCache(force)
        %clearInMemoryCache Clear the cache from memory.

            arguments
                force (1,1) logical = false
            end

            if ~force
                message = 'This will clear the cache from memory, but will keep the cache on storage. Are you sure you want to continue?';
                
                switch bot.internal.Preferences.getPreferenceValue('DialogMode')
                    case "Dialog Box"
                        answer = questdlg(message, 'Please Confirm');
                    case "Command Window"
                        answer = input( strjoin({message, '(y/n):'}), "s" );
                end

                switch answer
                    case {'Yes', 'y'}
                        force = true;
                end
            end

            if force

                bot.item.internal.EphysManifest.instance("clear") % clear singleton
                bot.item.internal.OphysManifest.instance("clear") % clear singleton
                % clear bot.behavior.internal.Cache
                % clear bot.internal.ObjectCacher
                % clear bot.internal.CloudCacher
            end
        end
        
        function resetCache(mode)
                        
            arguments
                % Extra layer of precaution
                mode (1,1) string = "ask" % "ask" || "force"
            end

            if strcmp(mode, "ask")
                messageStr = 'This will delete all the cached files. Are you sure you want to continue?';
                answer = questdlg(messageStr, 'Please confirm');
            elseif strcmp(mode, "force")
                answer = 'Yes';
            else
                error("Invalid input")
            end

            % Remove cache folder from path
            switch answer
                case 'Yes'
                    bot.behavior.internal.Cache.clearInMemoryCache(true)

                    cacheDirectory = bot.behavior.internal.Cache.getPreferredCacheDirectory();
                    warning('off', 'MATLAB:rmpath:DirNotFound')
                    rmpath(genpath(cacheDirectory)); savepath
                    warning('on', 'MATLAB:rmpath:DirNotFound')
                    rmdir(cacheDirectory, 's')
                    mkdir(cacheDirectory)
                    addpath(genpath(cacheDirectory)); savepath
            end
        end
    end

    %% Methods to get preferred or default cache directorygetPreferredCacheDirectory
    methods (Static, Access = private)
        function tf = hasPreferredCacheDirectory()
        %hasPreferredCacheDirectory Check if a preferred cache directory exists
            prefCacheDirectory = bot.internal.Preferences.getPreferenceValue('CacheDirectory');
            tf = prefCacheDirectory ~= "";
        end

        function strCacheDir = initializePreferredCacheDirectory()
        %initializePreferredCacheDirectory Let user configure a cache directory
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
            
            factoryCacheDir = bot.behavior.internal.Cache.getFactoryCacheDirectory();
            
            % If the factory cache directory already exists, the Brain 
            % Observatory Toolbox has been used on this computer prior to the
            % introduction of a preferred cache directory. Return here and
            % use the factory setting.
            if isfolder(factoryCacheDir)
                strCacheDir = factoryCacheDir; return
            end

            % Legacy factory cache directory did not exist, place factory
            % directory on the userpath.
            if isempty(userpath) % Can occur on linux platforms
                % Initialize the cache directory to the current working directory
                % in order to get an absolute directory path.
                factoryCacheDir = fullfile(pwd(), 'Brain Observatory Toolbox Cache');
            else
                factoryCacheDir = fullfile(userpath, 'Brain Observatory Toolbox Cache');
            end

            % - Construct a question dialog box where user can select if 
            % he/she wants to configure a custom folder for downloaded
            % data.
            promptMessage = sprintf(['This is the first time you run ', ...
                'the Brain Observatory Toolbox. This toolbox will download ' ...
                'and cache data in the following directory:' ...
                '\n \\bf%s'], factoryCacheDir);

            strCacheDir = bot.behavior.internal.Cache.createCacheDirectory(factoryCacheDir, promptMessage);
        end
        
        function strCacheDir = resolveMissingCacheDirectory(strCacheDir)

            msg = sprintf([ 'Can''t find the preferred cache directory for ', ...
                'the Brain Observatory Toolbox:\n%s'], strCacheDir);

            answer = questdlg(msg, 'Directory Missing', 'Locate...', 'Reinitialize', 'Locate...');

            switch answer
                case 'Locate...'
                    strCacheDir = bot.behavior.internal.Cache.uiGetCacheDirectory();
                case 'Reinitialize'
                    mkdir(strCacheDir);
                otherwise
                    strCacheDir = '';
            end
        end

        function strCacheDir = getFactoryCacheDirectory()
        %getFactoryCacheDirectory Get the BOT default (factory) cache directory    
            strBOTDir = fileparts(which('bot.listSessions'));
            strCacheDir = fullfile(strBOTDir, 'Cache');
        end

        function strCacheDir = getPreferredCacheDirectory()
        %getPreferredCacheDirectory Get the preferred cache directory from
        %the BrainObservatoryToolbox preferences.

            strCacheDir = bot.internal.Preferences.getPreferenceValue('CacheDirectory');
            
            if ~isfolder(strCacheDir)
                strCacheDir = bot.behavior.internal.Cache.resolveMissingCacheDirectory(strCacheDir);
                
                if isempty(strCacheDir)
                    error('BOT:PreferredCacheDirectoryMissing', ...
                          'Cache directory is unavailable.')
                end
            end
        end
        
        function strCacheDir = createCacheDirectory(strInitCacheDir, promptMessage)
   
            if nargin < 2 || isempty(promptMessage)
                promptMessage = sprintf(['Download ' ...
                    'and cache data in the following directory:' ...
                    '\n \\bf%s'], strInitCacheDir);
            end

            % - Format the message with a bigger font size (Todo; should depend on screen resolution...)
            %formattedMessage = strcat('\fontsize{14}', promptMessage);
            formattedMessage = promptMessage;

            % - Fix some characters that are interpreted as tex markup
            formattedMessage = strrep(formattedMessage, '_', '\_');
            titleMessage = 'Select Download Directory for Data'; 
            choices = {'Continue', 'Change Cache Directory...'};
            
            % - Use the tex-interpreter for displaying the prompt message.
            opts = struct('Default', 'Continue', 'Interpreter', 'tex');
            
            % - Present the question to the user
            answer = questdlg(formattedMessage, titleMessage, choices{:}, opts);
            
            % - Handle answer
            switch answer
                case 'Continue'
                    strCacheDir = strInitCacheDir;
                case 'Change Cache Directory...'
                    strCacheDir = bot.behavior.internal.Cache.uiGetCacheDirectory();
                otherwise
                    error('BOT:InitializeCacheDirectory', ...
                        'User canceled during configuration of the preferred cache directory.')
            end
            
            % - Store the selected cache directory to preferences
            prefs = bot.util.getPreferences();
            prefs.CacheDirectory = strCacheDir;
        end

        function strCacheDir = uiGetCacheDirectory()
        %uiGetCacheDirectory Open folder selection dialog for selecting a  cache directory.
        
            strCacheDir = uigetdir();

            if strCacheDir == 0
                error('BOT:InitializeCacheDirectory', ...
                    'User canceled during selection of a preferred cache directory.')
            end
        end

        function strScratchDir = getScratchDirectory(cacheDirectory)
        % Note: very specific to MATLAB ONLINE. Should be more generalized
            [~, currentUsername] = system('whoami');
            currentUsername = strtrim(currentUsername);

            if string(currentUsername) == "mluser"
                strScratchDir = "/Data/BOT_Cache_Temp";
                if ~isfolder(strScratchDir); mkdir(strScratchDir); end
            else
                strScratchDir = cacheDirectory;
            end
        end
    end

end

