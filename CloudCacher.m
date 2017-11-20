% CloudCacher - CLASS Manages a local cache of arbitrary URLs
%
% CloudCacher is a class that provides replacements for `webread` and
% `websave` that are cached locally. Is is stateful, and can be
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
         % Usage: ccObj.websave(strLocalFilename, strURL, ...)
         
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
         strFile = fullfile(ccObj.strCacheDir, strFilename);
      end
      
      function strFile = CachedFileForURL(ccObj, strURL)
         strFile = fullfile(ccObj.strCacheDir, ccObj.mapCachedData(strURL));
      end
      
      function SaveManifest(ccObj)
         % SaveManifest - METHOD Store the manifest for this cache object
         
         mapCachedData = ccObj.mapCachedData; %#ok<NASGU,PROP>
         strVersion = ccObj.strVersion; %#ok<NASGU,PROP>
         save(ccObj.strManifestFile, 'mapCachedData', 'strVersion');
      end
      
      function bIsInCache = IsInCache(ccObj, strURL)
         % IsInCache - METHOD Is the provided URL in the cache?
         bIsInCache = ccObj.mapCachedData.isKey(strURL);
      end
      
      function delete(ccObj)
         % - Should the cache directory be removed?
         if ccObj.bTemporaryCache
            rmdir(ccObj.strCacheDir, 's');
         end
      end
   end
   
end