classdef LocalFileCache < handle
%LocalCacher Abstract class for managing a local file cache.

    % Idea:
    % Make CacheManifest SetAccess = private and add an insert method for
    % subclasses.
    %
    %   The insert method should validate that inserted values are indeed
    %   relative filepaths of existing files?

    properties (Abstract, Constant)
        CacheName
    end

    properties (SetAccess = private)
        % CacheDirectory - Directory on local file system where data is 
        % cached. This is specified as the absolute path pointing to a 
        % folder where cached files are located.
        CacheDirectory (1,1) string = ""
        
        % IsTemporaryCache - Flag for whether cache is temporary and should 
        % be deleted when an instance of this class is deleted
        IsTemporaryCache (1,1) logical = false
    end

    properties (Dependent)
        % Length (number of items) of the cache
        CacheLength

        % A list (string array) of keys in the cache
        Keys
    end

    properties (Access = protected)
        % CacheManifest - Dictionary containing data that have been cached, 
        % consisting of key-value pairs where the key is a "cache key" and 
        % the value is the relative filepath for the cached file in the 
        % cache directory.
        CacheManifest dictionary = dictionary
    end

    properties (Dependent, Access = private)
        % Filepath for a .mat file containing the cache manifest / map
        CacheManifestFilePath (1,1) string
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
                %obj.saveCacheManifest()
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
        
        function filePath = getCachedFilePathForKey(obj, key)
        % getCachedFilePathForKey - Get full file path for a cached file
        %
        %   Syntax: 
        %   filePath = getCachedFilePathForKey(obj, key)
        %
        %   key is a string identifying a key that exists in the cache.
        %   filePath will be the full file path containing the object data
        %   for the key.
            
            if ~contains(obj.CacheManifest(key), obj.CacheDirectory)
                filePath = fullfile(obj.CacheDirectory, obj.CacheManifest(key));
            else
                filePath = obj.CacheManifest(key);
            end
            % Todo: Fix filesep if they are wrong. I.e cache may have
            % been created on one platform and opened on a second.
        end
        
        function tf = isInCache(obj, key) % todo: rename to isFileInCache
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
            if obj.CacheManifest.isKey(key)
                % - Check that the cache file actually exists
                tf = isfile( obj.getCachedFilePathForKey(key) );
                if ~tf
                    warning("LocalFileCache:MissingFileForKey", ...
                        "Key was detected but the corresponding file " + ...
                        "is not present in the file cache.")
                    obj.CacheManifest = obj.CacheManifest.remove(key);
                    obj.saveCacheManifest()
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
                obj.CacheManifest = obj.CacheManifest.remove(key);
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
                
                % - Remove key from manifest
                obj.CacheManifest = obj.CacheManifest.remove(key);
            end
            obj.saveCacheManifest()
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

        % Todo: Rename to getAbsolutePathname
            
            filePath = fullfile(obj.CacheDirectory, strFilename);
        end

        function relativePathName = getRelativePathname(obj, pathName)
        % getRelativePathname - Get pathname relative to cache location

            if contains( pathName, obj.CacheDirectory )
                relativePathName = replace(pathName, obj.CacheDirectory, '');
                if strncmp(relativePathName, filesep, 1)
                    % pass, todo?
                end
            end
        end
    end
      
    methods % Set/get methods
        
        function set.CacheDirectory(obj, newValue)
            obj.CacheDirectory = newValue;
            obj.onCacheDirectorySet()
        end

        function filePath = get.CacheManifestFilePath(obj)
            fileName = sprintf('%s_manifest.mat', obj.CacheName);
            filePath = fullfile(obj.CacheDirectory, fileName); %'OC_manifest.mat');
        end

        function size = get.CacheLength(obj)
            size = length(obj.CacheManifest);
        end

        function keys = get.Keys(obj)
            keys = string(obj.CacheManifest.keys());
        end
    end

    methods (Access = protected)
        
        function saveCacheManifest(obj)
        %saveCacheManifest - Store the cache manifest for this cache object
        %
        %   Syntax: 
        %   saveCacheManifest(obj) saves the cache manifest to the cache directory.
        %   
        %   Note: This function writes the cache manifest to disk. Should not
        %   need to be called by the end user.
         
            CacheManifest = obj.CacheManifest; %#ok<PROP>
            strVersion = obj.Version;
            save(obj.CacheManifestFilePath, 'CacheManifest', 'strVersion');
        end

        function loadCacheManifest(obj)
        %loadCacheManifest - Load the cache manifest for this cache object
        %
        %   Syntax: 
        %   loadCacheManifest(obj) loads the cache manifest from the cache directory.
        %   
        %   Note: This function reads the cache manifest from disk. Should not
        %   need to be called by the end user.
        
            S = load(obj.CacheManifestFilePath);
            assert(isequal(S.strVersion, obj.Version));
            try
                try
                    obj.CacheManifest = S.CacheManifest;
                catch
                    obj.CacheManifest = S.CacheMap;
                    obj.saveCacheManifest()
                end
            catch % Legacy
                obj.CacheManifest = S.mapCachedData;
            end

            if isa(obj.CacheManifest, 'containers.Map') % Convert to dictionary
                keys = string(obj.CacheManifest.keys()); values = string(obj.CacheManifest.values());
                obj.CacheManifest = dictionary(keys, values);
            end
        end
      
        function onCacheDirectorySet(obj)
        % Value changed callback for the CacheDirectory property

            % - Does the cache directory exist?
            if ~isfolder(obj.CacheDirectory)
                mkdir(obj.CacheDirectory);
            end
         
            % - Does a saved cache manifest exist?
            if isfile(obj.CacheManifestFilePath)
                try
                    obj.loadCacheManifest()
                catch
                    warning("LocalFileCache:InvalidManifest", ...
                       "Could not load saved manifest. " + ...
                       "Starting with an empty cache");
                    obj.CacheManifest = dictionary();
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
           keys = obj.CacheManifest.keys();
           
           for key = string(keys)
               obj.remove(key);
           end
        end
    end
    
end