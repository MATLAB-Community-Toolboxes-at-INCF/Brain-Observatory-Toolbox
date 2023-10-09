classdef LocalFileCache < handle
%LocalCacher Abstract class for managing a local file cache.

    properties (Abstract, Constant)
        CacheName
    end

    properties (SetAccess = private)
        % Directory on local file system in which data is cached
        CacheDirectory (1,1) string = ""
        
        % Flag for whether cache is temporary and should be deleted when 
        % an instance of this class is deleted
        IsTemporaryCache (1,1) logical = false
    end

    properties (Dependent)
        CacheLength
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


    methods
        
        % CONSTRUCTOR Create a cache object
        function obj = LocalFileCache(cacheDirectory)
        %LocalCacher Create a cache object, optionally reinitialise to an existing cache
        %
        % Usage: cacher = LocalCacher()
        %
        % The optional argument cacheDirectory can be used to force the
        % location of a new cache directory, or reinitialise to an existing
        % cache directory. If cacheDirectory is provided, then the cache
        % will not be removed when the CloudCacher object is deleted.

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
        % delete Delete the cache object and clean up
        %
        % Usage: delete(obj)
        %
        % If the flag obj.IsTemporaryCache is true, then the cache
        % directory will be removed
        
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
        % Usage: tf = isInCache(obj, key)
        %
        % key is a string to be queried in the object cache. If the
        % key exists in the cache, then `True` is returned. Otherwise
        % `False` is returned.
        
            % - Check whether the key is in the cache
            if obj.CacheMap.isKey(key)
                % - Check that the cache file actually exists
                tf = isfile( obj.getCachedFilePathForKey(key) );
                if ~tf
                    warning("LocalFileCache:MissingFileForKey", "Key was detected but the corresponding file is not present in the file cache.")
                end
            else
                tf = false;
            end
        end
      
        function remove(obj, key)
        % remove - METHOD Remove a cached file from the cache
        %
        % Usage: remove(obj, key)
        %
        % key is a string identifying a file. If the key exists in the 
        % cache, then the corresponding data file will be removed from 
        % the cache, i.e deleted from the file system.
        
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
            % Usage: filePath = CachedFilename(obj, strFilename)
            %
            % This method does NOT indicate whether the file exists in the
            % cache.
            
            filePath = fullfile(obj.CacheDirectory, strFilename);
        end

        function filePath = getCachedFilePathForKey(obj, key)
        % getCachedFilePathForKey - Return the full file path corresponding to a cached key
        %
        % Usage: filePath = getCachedFilePathForKey(obj, key)
        %
        % key is a string identifying a key that exists in the cache.
        % filePath will be the full file path containing the object data
        % for the key.
        
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
        %saveManifest Store the manifest for this cache object
        %
        %   Usage: saveManifest(obj)
        %   
        %   This function writes the cache manifest to disk. Should not
        %   need to be called by the end user.
         
            CacheMap = obj.CacheMap; %#ok<PROP>
            strVersion = obj.Version; %#ok<PROP>
            save(obj.CacheMapFilePath, 'CacheMap', 'strVersion');
        end

        function loadCacheMap(obj)
        %loadManifest Load the manifest for this cache object
            sManifest = load(obj.CacheMapFilePath);
            assert(isequal(sManifest.strVersion, obj.Version));
            try
                obj.CacheMap = sManifest.CacheMap;
            catch % Legacy
                obj.CacheMap = sManifest.mapCachedData;
            end
        end
      
        function onCacheDirectorySet(obj)

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
                    warning('LocalFileCache:InvalidManifest', ...
                       'Could not load saved manifest. Starting with an empty cache');
                end
            end
        end
    end

    methods (Access = ?bot.internal.Cache)
        function changeCacheDirectory(obj, directoryPath)
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