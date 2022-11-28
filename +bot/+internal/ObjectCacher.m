% ObjectCacher - CLASS Manages a local cache of arbitrary objects
%
% ObjectCacher is a class that provides a local cache for arbitrary MATLAB
% objects. It is stateful, and can be reinitialised by providing the
% location of an extant cache dir.

classdef ObjectCacher < handle
   
   properties (SetAccess = private)
      strCacheDir;                        % File directory in which data is cached
      strManifestFile;                    % .mat file containing the cache manifest
      bTemporaryCache = false;            % Boolean flag: should cache be deleted on variable deletion?
      mapCachedData = containers.Map();   % Map containing objects that have been cached, maps to cache-relative filenames
   end
   
   properties (SetAccess = immutable)
      strVersion = '0.01';                % Class version string, used to verify saved cache
   end
   
   methods
      function ocObj = ObjectCacher(strCacheDir)
         % ObjectCacher - CONSTRUCTOR Create a cache object, optionally reinitialise to an existing cache
         %
         % Usage: ccObj = ObjectCacher(<strCacheDir>)
         %
         % The optional argument `strCacheDir` can be used to force the
         % location of a new cache directory, or reinitialise to an
         % existing cache directory. If `strCacheDir` is provided, then the
         % cache will not be removed when the CloudCacher object is
         % deleted.
         
         % - Should we initialise a temporary cache?
         if ~exist('strCacheDir', 'var') || isempty(strCacheDir)
            ocObj.bTemporaryCache = true;
            ocObj.strCacheDir = tempname();
         else
            ocObj.strCacheDir = strCacheDir;
         end
         
         % - Does the cache directory exist?
         if ~isfolder(ocObj.strCacheDir)
            mkdir(ocObj.strCacheDir);
         end
         
         % - Does a saved cache manifest exist?
         ocObj.strManifestFile = fullfile(ocObj.strCacheDir, 'OC_manifest.mat');
         if exist(ocObj.strManifestFile, 'file')
            try
               sManifest = load(fullfile(ocObj.strCacheDir, 'OC_manifest.mat'));
               assert(isequal(sManifest.strVersion, ocObj.strVersion));
               ocObj.mapCachedData = sManifest.mapCachedData;
            catch
               warning('ObjectCacher:InvalidManifest', ...
                       'Could not load saved manifest. Starting with an empty cache');
            end
         end
      end
      
      function strCacheFilename = Insert(ocObj, strKey, object)
         % Insert - METHOD Insert an object into the cache
         %
         % Usage: strCacheFilename = ocObj.Insert(strKey, object)
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
         
         try
            if ocObj.IsInCache(strKey)
               % - Get the existing data store for this object
               strCacheFilename = ocObj.CachedFileForKey(strKey);
               
            else
               % - Get a new filename for the cache object store
               if numel(char(strKey)) > 128 || ~strcmp(strKey, matlab.lang.makeValidName(strKey))
                   [~, strRelativeFilename] = fileparts(tempname());
               else
                   strRelativeFilename = strKey;
               end
               strRelativeFilename = [strRelativeFilename '.mat'];

               % - Convert the filename to a file in the cache
               strCacheFilename = ocObj.CachedFilename(strRelativeFilename);
            end
            
            % - Ensure any required cache subdirectories exist
            w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
            mkdir(fileparts(strCacheFilename));
            warning(w);
            
            % - Check if the filename exists and warn
            if exist(strCacheFilename, 'file')
               warning('ObjectCacher:FileExists', 'The specified file already exists; overwriting.');
            end
            
            % - Download data from the provided URL and save
            save(strCacheFilename, 'object');
            
            % - Add URL to cache and save manifest
            ocObj.mapCachedData(strKey) = strRelativeFilename;
            ocObj.SaveManifest();
            
         catch mErr_Cause
            % - Throw an exception
            mErr_Base = MException('ObjectCacher:AccessFailed', 'Could not store object in cache.');
            mErr_Base = mErr_Base.addCause(mErr_Cause);
            throw(mErr_Base);
         end
      end
         
      function object = Retrieve(ocObj, strKey)
         % Retrieve - METHOD Retrieve an object from the cache
         %
         % Usage: object = ocObj.Retrieve(strKey)
         %
         % `strKey` is a string which identifies an object in the cache.
         %
         % If the key `strKey` exists in the cache, the corresponding
         % object will be retrieved and returned. Otherwise an error will
         % be raised.
         
         if ~ocObj.IsInCache(strKey)
            error('ObjectCacher:NotInCache', 'The requested object is not in the cache.');
         
         else
            % - Get the cache filename for this key
            strCachedFilename = ocObj.CachedFileForKey(strKey);
            
            % - Load the object
            d = load(strCachedFilename);
            object = d.object;
         end
      end
      
      function strFile = CachedFilename(ocObj, strFilename)
         % CachedFilename - METHOD Return the cache-mapped location of a given file
         %
         % Usage: strFile = CachedFilename(ocObj, strFilename)
         %
         % This method does NOT indicate whether the file exists in the
         % cache.
         
         strFile = fullfile(ocObj.strCacheDir, strFilename);
      end
      
      function strFile = CachedFileForKey(ocObj, strKey)
         % CachedFileForKey - METHOD Return the full file path corresponding to a cached key
         %
         % Usage: strFile = CachedFileForKey(ocObj, strKey)
         %
         % `strKey` is a string identifying a key that exists in the cache.
         % `strFile` will be the full file path containing the object data
         % for the key.

         strFile = fullfile(ocObj.strCacheDir, ocObj.mapCachedData(strKey));
      end
      
      function SaveManifest(ocObj)
         % SaveManifest - METHOD Store the manifest for this cache object
         %
         % Usage: SaveManifest(ocObj)
         %
         % This function writes the cache manifest to disk. Should not need
         % to be called by the end user.
         
         mapCachedData = ocObj.mapCachedData; %#ok<PROP>
         strVersion = ocObj.strVersion; %#ok<PROP>
         save(ocObj.strManifestFile, 'mapCachedData', 'strVersion');
      end
      
      function bIsInCache = IsInCache(ocObj, strKey)
         % IsInCache - METHOD Is the provided URL in the cache?
         %
         % Usage: bIsInCache = IsInCache(ccObj, strKey)
         %
         % `strKey` is a string to be queried in the object cache. If the
         % key exists in the cache, then `True` is returned. Otherwise
         % `False` is returned.
         
         % - Check whether the key is in the cache
         if ocObj.mapCachedData.isKey(strKey)
            % - Check that the cache file actually exists
            bIsInCache = exist(ocObj.CachedFileForKey(strKey), 'file');
         else
            bIsInCache = false;
         end
      end
      
      function Remove(ocObj, strKey)
         % Remove - METHOD Remove a cached object from the cache
         %
         % Usage: Remove(ocObj, strKey)
         %
         % `strKey` is a string identifying an object key. If the key
         % exists in the cache, then the corresponding object data will be
         % removed form the cache.
         
         % - Is the object in the cache?
         if ~ocObj.IsInCache(strKey)
            % - No, so raise a warning
            warning('ObjectCacher:KeyNotInCache', ...
                    'The provided object does not exist in the cache.');

         else
            % - Try to delete the object from the cache
            try
               delete(ocObj.CachedFileForKey(strKey));
               
            catch mE_Cause
               % - Raise a warning if we couldn't delete the file
               mE_Base = MException('ObjectCacher:CouldNotDeleteCacheFile', ...
                                    'Cached object could not be deleted from the cache.');
               mE_Base.addCause(mE_Cause);
               warning(getReport(mE_Base, 'extended', 'hyperlinks', 'on'));
            end

            % - Remove key from map
            ocObj.mapCachedData.remove(strKey);
         end
      end
      
      function delete(ocObj)
         % delete - METHOD Delete the cache object and clean up
         %
         % Usage: delete(ocObj)
         %
         % If the flag `ocObj.bTemporaryCache` is `true`, then the cache
         % directory will be removed
         
         % - Should the cache directory be removed?
         if ocObj.bTemporaryCache
            rmdir(ocObj.strCacheDir, 's');
         end
      end
   end
end