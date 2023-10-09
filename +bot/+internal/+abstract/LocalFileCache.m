classdef LocalFileCache < handle
%LocalCacher Abstract class for managing a local file cache.

    properties (Abstract, Constant)
        CacheName
    end

    properties (SetAccess = private)
        % Directory on local file system in which data is cached. This is
        % specified as the absolute path pointing to a folder where 
        % cached files are located
        CacheDirectory (1,1) string = ""
        
        % Flag for whether cache is temporary and should be deleted when 
        % an instance of this class is deleted
        IsTemporaryCache (1,1) logical = false
    end

    properties (Dependent)
        % Length (number of items) of the cache
        CacheLength

        % A list (string array) of keys in the cache
        Keys
    end

    properties (Access = protected)
        % Dictionary containing data that have been cached, consisting of
        % key-value pairs where the key is a "cache key" and the value is
        % the relative filepath for the cached file in the cache directory.
        CacheMap %dictionary = dictionary
    end

    properties (Dependent, Access = private)
        % Filepath for a .mat file containing the cache manifest / map
        CacheMapFilePath (1,1) string
    end

    properties (SetAccess = immutable)
        % Class version string, used to verify saved cache
        Version (1,1) string = "0.01"
    end


    methods % Class constructor and destructor
        % CONSTRUCTOR Create a cache object
        function obj = LocalFileCache(cacheDirectory)
        % LocalFileCache - Create a cache object
        %
        %   Syntax: 
        %   CACHE = LocalFileCache() creates a new temporary cache
        %
        %   CACHE = LocalFileCache(CACHEDIRECTORY) creates new or 
        %   reinitialises an existing permanent cache.
        %
        %   Input arguments:
        %       CACHEDIRECTORY - Path string for a cache directory.
        %           If the specified directory does not exist, a new
        %           directory is created. Otherwise the cache is
        %           reinitialised based on the contents of the directory.
        %
        %   Output arguments:
        %       CACHE - A newly created cache instance
        %
        %   Note: If a temporary cache is created, the cached files
        %   are deleted when the cache instance is cleared from memory.

            % - Should we initialise a temporary cache?
            if ~exist('cacheDirectory', 'var') || isempty(cacheDirectory)
                obj.IsTemporaryCache = true;
                obj.CacheDirectory = tempname();
            else
                obj.CacheDirectory = cacheDirectory;
            end
        end

        % DESTRUCTOR Delete a cache object
        function delete(obj)
        % delete - Delete the cache object and clean up
        %
        %   Syntax: 
        %   delete(obj)
        %
        %   Note: If the flag obj.IsTemporaryCache is true, then the 
        %   cache directory will be removed
            
            % - Should the cache directory be removed?
            if obj.IsTemporaryCache
                rmdir(obj.CacheDirectory, 's');
            else
                %obj.saveCacheMap()
            end
        end
    end

    % methods (Abstract) % Public
    % 
    %     % Insert data into the cache
    %     cacheFilepath = insert(obj, key, value)
    % 
    %     % Retrieve data from the cache
    %     value = retrieve(obj, key)
    % 
    % end

    methods
        
        % ?Todo: isKeyInCache

        function tf = isInCache(obj, key)
        % isInCache - Is the provided key in the cache?
        %
        %   Syntax: 
        %   TF = isInCache(OBJ, KEY) checks if the provided key is in the
        %   cache.
        % 
        %   Input arguments:
        %       OBJ - An instance of the LocalFileCache class
        %
        %       KEY - A string to be queried in the file cache.
        %
        %   Output arguments:
        %       TF - A logical scalar, indicating if the key exists in the
        %           cache. If the key is in the cache, and the file for 
        %           that key exists, the value of TF is true, otherwise it 
        %           is false.
    
            % - Check whether the key is in the cache
            if obj.CacheMap.isKey(key)
                % - Check that the cache file actually exists
                tf = isfile( obj.getCachedFilePathForKey(key) );
                if ~tf
                    warning("LocalFileCache:MissingFileForKey", ...
                        "Key was detected but the corresponding file " + ...
                        "is not present in the file cache.")
                end
            else
                tf = false;
            end
        end
      
        function remove(obj, key)
        % remove - Remove a cached file from the cache
        %
        %   Syntax: 
        %   remove(obj, key)
        %
        %   key is a string identifying a file. If the key exists in the 
        %   cache, then the corresponding data file will be removed from 
        %   the cache (i.e deleted from the file system).
        
            % - Is the object in the cache?
            if ~obj.isInCache(key)
                % - No, so raise a warning
                warning('LocalFileCache:FileNotInCache', ...
                        'The file for the provided key does not exist in the cache.');
                
            else
                % - Try to delete the file from the cache
                try
                    filePath = obj.getCachedFilePathForKey(key);
                    delete(filePath);
                   
                catch mE_Cause
                    % - Raise a warning if we couldn't delete the file
                    mE_Base = MException('LocalFileCache:CouldNotDeleteCacheFile', ...
                        'Cached file could not be deleted from the cache.');
                    mE_Base.addCause(mE_Cause);
                    warning(getReport(mE_Base, 'extended', 'hyperlinks', 'on'));
                end
                
                % - Remove key from map
                obj.CacheMap.remove(key);
            end
            obj.saveCacheMap()
        end
    end

    methods (Access = protected)
        
        function filePath = getCachedFilename(obj, strFilename)
        % getCachedFilename - Return the cache-mapped location of a given file
        %
        %   Syntax: 
        %   filePath = getCachedFilename(obj, strFilename) returns the
        %   absolute filepath given the relative filepath of a file
        %
        %   Note: This method does NOT indicate whether the file exists in 
        %   the cache.
            
            filePath = fullfile(obj.CacheDirectory, strFilename);
        end

        function filePath = getCachedFilePathForKey(obj, key)
        % getCachedFilePathForKey - Get full file path for a cached file
        %
        %   Syntax: 
        %   filePath = getCachedFilePathForKey(obj, key)
        %
        %   key is a string identifying a key that exists in the cache.
        %   filePath will be the full file path containing the object data
        %   for the key.
        
            filePath = fullfile(obj.CacheDirectory, obj.CacheMap(key));
        end
    end
      
    methods % Set/get methods
        
        function set.CacheDirectory(obj, newValue)
            obj.CacheDirectory = newValue;
            obj.onCacheDirectorySet()
        end

        function filePath = get.CacheMapFilePath(obj)
            fileName = sprintf('%s_manifest.mat', obj.CacheName);
            filePath = fullfile(obj.CacheDirectory, fileName); %'OC_manifest.mat');
        end

        function size = get.CacheLength(obj)
            size = length(obj.CacheMap);
        end

        function keys = get.Keys(obj)
            keys = string(obj.CacheMap.keys());
        end
    end

    methods (Access = private)
        
        function saveCacheMap(obj)
        %saveCacheMap - Store the cache map for this cache object
        %
        %   Syntax: 
        %   saveCacheMap(obj) saves the cache map to the cache directory.
        %   
        %   Note: This function writes the cache map to disk. Should not
        %   need to be called by the end user.
         
            CacheMap = obj.CacheMap; %#ok<PROP>
            strVersion = obj.Version;
            save(obj.CacheMapFilePath, 'CacheMap', 'strVersion');
        end

        function loadCacheMap(obj)
        %loadCacheMap - Load the cache map for this cache object
        %
        %   Syntax: 
        %   loadCacheMap(obj) loads the cache map from the cache directory.
        %   
        %   Note: This function reads the cache map from disk. Should not
        %   need to be called by the end user.
        
            S = load(obj.CacheMapFilePath);
            assert(isequal(S.strVersion, obj.Version));
            try
                obj.CacheMap = S.CacheMap;
            catch % Legacy
                obj.CacheMap = S.mapCachedData;
            end
        end
      
        function onCacheDirectorySet(obj)
        % Value changed callback for the CacheDirectory property

            % - Does the cache directory exist?
            if ~isfolder(obj.CacheDirectory)
                mkdir(obj.CacheDirectory);
            end

            % - Initialize manifest
            % obj.CacheMap = containers.Map();
         
            % - Does a saved cache manifest exist?
            if isfile(obj.CacheMapFilePath)
                try
                    obj.loadCacheMap()
                catch
                    warning("LocalFileCache:InvalidManifest", ...
                       "Could not load saved manifest. " + ...
                       "Starting with an empty cache");
                end
            end
        end
    end

    methods (Access = ?bot.internal.Cache)
        function changeCacheDirectory(obj, directoryPath)
        % Lets bot.internal.Cache change cache directory
            obj.CacheDirectory = directoryPath;
        end

        function removeAll(obj)
           keys = obj.CacheMap.keys();
           
           for key = string(keys)
               obj.remove(key);
           end
        end
    end
    
end