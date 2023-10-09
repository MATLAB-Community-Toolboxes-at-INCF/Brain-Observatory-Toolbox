% ObjectCacher - CLASS Manages a local cache of arbitrary objects
%
% ObjectCacher is a class that provides a local cache for arbitrary MATLAB
% objects. It is stateful, and can be reinitialised by providing the
% location of an extant cache dir.

% Note: In the Brain Observatory Toolbox, the ObjectCacher is used for
% caching item tables of the Ephys- and OphysManifest classes.

classdef ObjectCacher < bot.internal.abstract.LocalFileCache

    properties (Constant)
        CacheName = 'OC' %'ObjectCache'
    end

    methods
        function obj = ObjectCacher(cacheDirectory)
        % ObjectCacher - CONSTRUCTOR Create a cache object, optionally reinitialise to an existing cache
        %
        % Usage: ccObj = ObjectCacher(<cacheDirectory>)
        %
        % The optional argument cacheDirectory can be used to force the
        % location of a new cache directory, or reinitialise to an
        % existing cache directory. If cacheDirectory is provided, then the
        % cache will not be removed when the ObjectCacher object is
        % deleted.
            if nargin < 1; cacheDirectory = ''; end
            obj@bot.internal.abstract.LocalFileCache(cacheDirectory)
        end
    end

    methods

        function objectFilepath = insert(obj, key, object)
        % insert - METHOD Insert an object into the cache
        %
        % Usage: strCacheFilename = obj.Insert(key, object)
        %
        % key is a string, which will be associated with the object
        % in the cache. You should take care that the key is unique
        % enough.
        %
        % object is an arbitrary MATLAB object, that can be serialised
        % and saved.
        %
        % object will be inserted into the object cache, and can be
        % retrieved later using the key.
         
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
        % Retrieve - METHOD Retrieve an object from the cache
        %
        % Usage: object = obj.retrieve(key)
        %
        % key is a string which identifies an object in the cache.
        %
        % If the key key exists in the cache, the corresponding
        % object will be retrieved and returned. Otherwise an error will
        % be raised.
        
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
        % remove - METHOD Remove a cached file from the cache
        %
        % Usage: remove(obj, key)
        %
        % key is a string identifying an object. If the key exists in the 
        % cache, then the corresponding object will be removed from 
        % the cache, i.e the file containing the object is deleted from 
        % the file system.
            remove@bot.internal.abstract.LocalFileCache(obj, key)
        end
        
    end

end