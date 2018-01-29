% CloudCacher - CLASS Manages a local cache of arbitrary URLs
%
% CloudCacher is a class that provides replacements for `webread` and
% `websave` that are cached locally. It is stateful, and can be
% reinitialised by providing the location of an extant cache dir.

classdef CloudCacher < handle
   
   properties (SetAccess = private)
      strCacheDir;                        % File directory in which data is cached
      strManifestFile;                    % .mat file containing the cache manifest
      bTemporaryCache = false;            % Boolean flag: should cache be deleted on variable deletion?
      mapCachedData = containers.Map();   % Map containing URLs that have been cached
   end
   
   properties (SetAccess = immutable)
      strVersion = '0.01';                % Class version string, used to verify saved cache
   end
   
   methods
      function ccObj = CloudCacher(strCacheDir)
         % CloudCached - CONSTRUCTOR Create a cache object, optionally reinitialise to an existing cache
         %
         % Usage: ccObj = CloudCacher(<strCacheDir>)
         %
         % The optional argument `strCacheDir` can be used to force the
         % location of a new cache directory, or reinitialise to an
         % existing cache directory. If `strCacheDir` is provided, then the
         % cache will not be removed when the CloudCacher object is
         % deleted.
         
         % - Should we initialise a temporary cache?
         if ~exist('strCacheDir', 'var') || isempty(strCacheDir)
            ccObj.bTemporaryCache = true;
            ccObj.strCacheDir = tempname();
         else
            ccObj.strCacheDir = strCacheDir;
         end
         
         % - Does the cache directory exist?
         if ~isdir(ccObj.strCacheDir)
            mkdir(ccObj.strCacheDir);
         end
         
         % - Does a saved cache manifest exist?
         ccObj.strManifestFile = fullfile(ccObj.strCacheDir, 'CC_manifest.mat');
         if exist(ccObj.strManifestFile, 'file')
            try
               sManifest = load(fullfile(ccObj.strCacheDir, 'CC_manifest.mat'));
               assert(isequal(sManifest.strVersion, ccObj.strVersion));
               ccObj.mapCachedData = sManifest.mapCachedData;
            catch
               warning('CloudCacher:InvalidManifest', ...
                       'Could not load saved manifest. Starting with an empty cache');
            end
         end
      end
      
      function strCacheFilename = websave(ccObj, strLocalFilename, strURL, varargin)
         % websave - METHOD Cached replacement for websave function
         %
         % Usage: strCacheFilename = ccObj.websave(strLocalFilename, strURL, ...)
         %
         % Replaces the Matlab `websave` function, with a cached method.
         % Optional arguments are passed to `websave`.
         
         try
            % - Is the URL already in the cache?
            if ccObj.IsInCache(strURL) && exist(ccObj.CachedFileForURL(strURL), 'file')
               % - Yes, so read the local file
               strCacheFilename = ccObj.CachedFileForURL(strURL);
               
            else
               % - No, so we need to download and cache it
               
               % - Get a filename for the cache
               if ~exist('strLocalFilename', 'var') || isempty(strLocalFilename)
                  [~, strLocalFilename] = fileparts(tempname());
                  strLocalFilename = [strLocalFilename '.mat'];
               end
               
               % - Convert the filename to a file in the cache
               strCacheFilename = ccObj.CachedFilename(strLocalFilename);
               
               % - Ensure any required cache subdirectories exist
               w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
               mkdir(fileparts(strCacheFilename));
               warning(w);
               
               % - Check if the filename exists and warn
               if exist(strCacheFilename, 'file')
                  warning('CloudCacher:FileExists', 'The specific local file already exists; overwriting.');
               end
               
               % - Download data from the provided URL and save
               strCacheFilename = websave(strCacheFilename, strURL, varargin{:});
               
               % - Add URL to cache and save manifest
               ccObj.mapCachedData(strURL) = strLocalFilename;
               ccObj.SaveManifest();
            end
            
         catch mErr_Cause
            % - Throw an exception
            mErr_Base = MException('CloudCacher:AccessFailed', 'Could not access URL.');
            mErr_Base = mErr_Base.addCause(mErr_Cause);
            throw(mErr_Base);
         end
      end
      
      function data = webread(ccObj, strURL, strLocalFilename, varargin)
         % webread - METHOD - Cached replacement for webread function
         %
         % Usage: data = ccObj.webread(strURL, strLocalFilename, ...)
         %
         % Replaces the Matlab `webread` function with a cached method.
         % Optional arguments are passed to `webread`.
         
         try
            % - Is the URL already in the cache?
            if ccObj.IsInCache(strURL) && exist(ccObj.CachedFileForURL(strURL), 'file')
               % - Yes, so read the local file
               strCachedFilename = ccObj.CachedFileForURL(strURL);
               sData = load(strCachedFilename);
               data = sData.data;
               
            else
               % - No, so we need to download and cache it
               
               % - Get a filename for the cache
               if ~exist('strLocalFilename', 'var') || isempty(strLocalFilename)
                  [~, strLocalFilename] = fileparts(tempname());
                  strLocalFilename = [strLocalFilename '.mat'];
               end
               
               % - Convert the filename to a file in the cache
               strCacheFilename = ccObj.CachedFilename(strLocalFilename);

               % - Ensure any required cache subdirectories exist
               w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
               mkdir(fileparts(strCacheFilename));
               warning(w);

               % - Check if the filename exists and warn
               if exist(strCacheFilename, 'file')
                  warning('CloudCacher:FileExists', 'The specific local file already exists; overwriting.');
               end
               
               % - Download data from the provided URL and save
               data = webread(strURL, varargin{:});
               save(strCacheFilename, 'data');

               % - Add URL to cache and save manifest
               ccObj.mapCachedData(strURL) = strLocalFilename;
               ccObj.SaveManifest();
            end
            
         catch mErr_Cause
            % - Throw an exception
            mErr_Base = MException('CloudCacher:AccessFailed', 'Could not access URL.');
            mErr_Base = mErr_Base.addCause(mErr_Cause);
            throw(mErr_Base);
         end
      end
      
      function strFile = CachedFilename(ccObj, strFilename)
         % CachedFilename - METHOD Return the cache-mapped location of a given file
         %
         % Usage: strFile = CachedFilename(ccObj, strFilename)
         %
         % This method does NOT indicate whether the file exists in the
         % cache.
         
         strFile = fullfile(ccObj.strCacheDir, strFilename);
      end
      
      function strFile = CachedFileForURL(ccObj, strURL)
         % CachedFileForURL - METHOD Return the file name corresponding to a cached URL
         %
         % Usage: strFile = CachedFileForURL(ccObj, strURL)
         %
         % This method does NOT indicate whether or not the URL exists in
         % the cache. Use `.IsInCache()` for that.
         
         strFile = fullfile(ccObj.strCacheDir, ccObj.mapCachedData(strURL));
      end
      
      function SaveManifest(ccObj)
         % SaveManifest - METHOD Store the manifest for this cache object
         %
         % Usage: SaveManifest(ccObj)
         %
         % This function writes the cache manifest to disk. Should not need
         % to be called by the end user.
         
         mapCachedData = ccObj.mapCachedData; %#ok<NASGU,PROP>
         strVersion = ccObj.strVersion; %#ok<NASGU,PROP>
         save(ccObj.strManifestFile, 'mapCachedData', 'strVersion');
      end
      
      function bIsInCache = IsInCache(ccObj, strURL)
         % IsInCache - METHOD Is the provided URL in the cache?
         %
         % Usage: bIsInCache = IsInCache(ccObj, strURL)
         
         bIsInCache = ccObj.mapCachedData.isKey(strURL);
      end
      
      function RemoveURL(ccObj, strURL)
         % RemoveURL - METHOD Remove a cached file from the cache
         %
         % Usage: RemoveURL(ccObj, strURL)
         
         % - Is the URL in the cache?
         if ~ccObj.IsInCache(strURL)
            % - No, so raise a warning
            warning('CloudCacher:URLNotInCache', ...
                    'The provided URL does not exist in the cache.');

         else
            % - Try to delete the file from the cache
            try
               delete(ccObj.CachedFileForURL(strURL));
               
            catch mE_Cause
               % - Raise an error if we couldn't delete the file
               mE_Base = MException('CloudCacher:CouldNotDeleteCacheFile', ...
                                    'Cached URL could not be deleted from the cache.');
               mE_Base.addCause(mE_Cause);
               throw(mE_Base);
            end
         end
      end
      
      function delete(ccObj)
         % delete - METHOD Delete the cache object and clean up
         %
         % Usage: delete(ccObj)
         %
         % If the flag `ccObj.bTemporaryCache` is `true`, then the cache
         % directory will be removed
         
         % - Should the cache directory be removed?
         if ccObj.bTemporaryCache
            rmdir(ccObj.strCacheDir, 's');
         end
      end
   end
   
end