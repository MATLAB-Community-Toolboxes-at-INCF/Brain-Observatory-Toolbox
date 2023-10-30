% ObjectCacher - Manages a local file cache of arbitrary objects
%
%   ObjectCacher is a class that provides a local cache for arbitrary 
%   MATLAB objects. It is stateful, and can be reinitialised by providing 
%   the location of an extant cache dir.
%
%   See also bot.internal.abstract.LocalFileCache

%   Note: In the Brain Observatory Toolbox, the ObjectCacher is used 
%   internally for caching item tables of the Ephys- and OphysManifest 
%   classes.

classdef ObjectCacher < bot.internal.abstract.LocalFileCache

    properties (Constant)
        CacheName = 'OC' % (Short name)
    end

    methods
        function obj = ObjectCacher(cacheDirectory)
        % ObjectCacher - Create an object cache instance
        %
        %   Syntax: 
        %       OBJECTCACHE = ObjectCache() creates a new temporary object 
        %       cache.
        %
        %       OBJECTCACHE = ObjectCache(CACHEDIRECTORY) creates new or 
        %       reinitialises an existing permanent object cache.
        %
        %   Input arguments:
        %       CACHEDIRECTORY - Path string for a cache directory.
        %           If the specified directory does not exist, a new
        %           directory is created. Otherwise the cache is
        %           reinitialised based on the contents of the directory.
        %
        %   Output arguments:
        %       OBJECTCACHE - A newly created object cache instance.
        %
        %   See also bot.internal.abstract.LocalFileCache
        
            if nargin < 1; cacheDirectory = ''; end
            obj@bot.internal.abstract.LocalFileCache(cacheDirectory)
        end
    end

    methods
        function objectFilepath = insert(obj, key, object)
        % insert - Insert an object into the cache
        %
        %   Syntax:
        %       OBJECTFILEPATH = obj.insert(KEY, OBJECT) inserts an object 
        %       into the cache assigning it using the provided key. The 
        %       object can be retrieved later using the same key.
        %
        %   Input arguments:
        %       KEY - A string which will be associated with the object
        %           in the cache. You should take care that the key is 
        %           unique enough.
        %
        %       OBJECT - An arbitrary MATLAB object, that can be serialised
        %           and saved.
        %   
        %   Output arguments:
        %       OBJECTFILEPATH - An absolute path string to the file in the
        %           cache containing the cached object.
        %
        %   See also: bot.internal.ObjectCacher/retrieve

            try
                if obj.isInCache(key)
                    % - Get the existing data store for this object
                    objectFilepath = obj.getCachedFilePathForKey(key);
                   
                else
                    % - Get a new filename for the cache object store
                    if numel(char(key)) > 128 || ~strcmp(key, matlab.lang.makeValidName(key))
                        [~, strRelativeFilename] = fileparts(tempname());
                    else
                        strRelativeFilename = key;
                    end
                    strRelativeFilename = [strRelativeFilename '.mat'];
                    
                    % - Convert the filename to a file in the cache
                    objectFilepath = obj.getCachedFilename(strRelativeFilename);
                end
            
                % - Ensure any required cache subdirectories exist
                w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
                mkdir(fileparts(objectFilepath));
                warning(w);
                
                % - Check if the filename exists and warn
                if exist(objectFilepath, 'file')
                   warning('ObjectCacher:FileExists', 'The specified file already exists; overwriting.');
                end
                
                % - Save the object and add its filepath to the cache.
                save(objectFilepath, 'object');
                
                % - Add URL to cache and save manifest
                obj.CacheMap(key) = strRelativeFilename;
                obj.saveManifest();
            
            catch mErr_Cause
                % - Throw an exception
                mErr_Base = MException('ObjectCacher:AccessFailed', 'Could not store object in cache.');
                mErr_Base = mErr_Base.addCause(mErr_Cause);
                throw(mErr_Base);
            end
        end
        
        function object = retrieve(obj, key)
        % retrieve - Retrieve an object from the cache
        %
        %   Syntax: 
        %       OBJECT = obj.retrieve(KEY) retrieves an object from the 
        %       cache which is asociated with the given key
        %
        %   Input arguments:
        %       KEY - A string which identifies an object in the cache
        %
        %   Output arguments:
        %       OBJECT - An arbitrary MATLAB object
        %
        %   Note: If the key key exists in the cache, the corresponding
        %   object will be retrieved and returned. Otherwise an error will
        %   be raised.
        
            if ~obj.isInCache(key)
                error('ObjectCacher:NotInCache', ...
                    'The requested object is not in the cache.');
            
            else
                % - Get the cache filename for this key
                objectFilePath = obj.getCachedFilePathForKey(key);
            
                % - Load the object
                d = load(objectFilePath);
                object = d.object;
            end
        end
      
        function remove(obj, key)
        % remove - Remove a cached file from the cache
        %
        %   Syntax: 
        %       obj.remove(KEY) removes the object for the given key from
        %       the cache (the file containing the object is deleted).
        %
        %   Input arguments:
        %       KEY - A string which identifies an object in the cache.
        %           If the key exists in the cache, then the corresponding 
        %           object will be removed from the cache, i.e the file 
        %           containing the object is deleted from the file system.

            remove@bot.internal.abstract.LocalFileCache(obj, key)
        end
    end
end
