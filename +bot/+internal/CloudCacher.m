% CloudCacher - CLASS Manages a local cache of arbitrary URLs
%
% CloudCacher is a class that provides replacements for `webread` and
% `websave` that are cached locally. It is stateful, and can be
% reinitialised by providing the location of an extant cache dir.

classdef CloudCacher < handle
   
   properties (SetAccess = private)
      strCacheDir                         % File directory in which data is cached
      strManifestFile;                    % .mat file containing the cache manifest
      bTemporaryCache = false;            % Boolean flag: should cache be deleted on variable deletion?
      mapCachedData = containers.Map();   % Map containing URLs that have been cached, maps to cache-relative filenames
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
         if ~isfolder(ccObj.strCacheDir)
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
      
      function strCacheFilename = copyfile(ccObj, strURL, strRelativeFilename, strCloudFilepath)
      % copyfile - METHOD Cached replacement for copyfile function

      % Hint: Copy files from S3 bucket to EC2 local drive
      
          strCacheFilename = ccObj.CachedFilename(strRelativeFilename);

          targetFolder = fileparts(strCacheFilename);
          if ~isfolder(targetFolder); mkdir(targetFolder); end
          
          try
              copyfile(strCloudFilepath, strCacheFilename)
              ccObj.mapCachedData(strURL) = strRelativeFilename;
              ccObj.SaveManifest();
          catch mErr_Cause
             mErr_Base = MException('CloudCacher:FileCopyFailed', 'Could not copy file from S3 bucket.');
             mErr_Base = mErr_Base.addCause(mErr_Cause);
             throw(mErr_Base);
          end
      end

      function strCacheFilename = websave(ccObj, strRelativeFilename, strURL, varargin)
         % websave - METHOD Cached replacement for websave function
         %
         % Usage: strCacheFilename = ccObj.websave(strRelativeFilename, strURL, ...)
         %
         % Replaces the Matlab `websave` function, with a cached method.

         % Note: This feature was removed when replacing websave with
         % downloadFile (Todo: Consider to reimplement):
         % Optional additional arguments are passed to `websave`.
        
         import bot.external.fex.filedownload.downloadFile

         % Check varargin for optional SecondaryFileUrl (Todo: Add documentation)
         isSecondaryFileArg = cellfun(@(arg) ischar(arg) && strcmp(arg, 'SecondaryFileUrl'), varargin);
         if any( isSecondaryFileArg )
            secondaryFileUrl = varargin{ find(isSecondaryFileArg) + 1};
            %varargin(find(isSecondaryFileArg) + 0:1) = []; Placeholder
         else
            secondaryFileUrl = '';
         end

         try
            % - Is the URL already in the cache?
            if ccObj.IsInCache(strURL) && exist(ccObj.CachedFileForURL(strURL), 'file')
               % - Yes, so read the cached file
               strCacheFilename = ccObj.CachedFileForURL(strURL);
            else
               % - No, so we need to download and cache it
               
               % - Get a filename for the cache
               if isempty(strRelativeFilename)
                  [~, strRelativeFilename] = fileparts(tempname());
                  strRelativeFilename = [strRelativeFilename '.mat'];
               end
               
               % - Convert the filename to a file in the cache
               strCacheFilename = ccObj.CachedFilename(strRelativeFilename);
               
               % - Ensure any required cache subdirectories exist
               w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
               mkdir(fileparts(strCacheFilename));
               warning(w);
               
               % - Check if the filename exists and warn
               if exist(strCacheFilename, 'file')
                  warning('CloudCacher:FileExists', 'The specified file already exists; overwriting.');
               end
               
               % - Download data from the provided URL and save
               if isempty(secondaryFileUrl)
                  strCacheFilename = downloadFile(strCacheFilename, strURL, ...
                      'DisplayMode', bot.Preferences.get('DialogMode'));
               else
                  strCacheFilename = downloadFile(strCacheFilename, secondaryFileUrl, ...
                      'DisplayMode', bot.Preferences.get('DialogMode'));
               end

               % - Check that we got the complete file
               fileSizeWeb = bot.util.getWebFileSize(strURL);
               fileSizeLocal = bot.util.getLocalFileSize(strCacheFilename);
               
               if fileSizeWeb == fileSizeLocal
                  % - Add URL to cache and save manifest
                  ccObj.mapCachedData(strURL) = strRelativeFilename;
                  ccObj.SaveManifest();
               else
                  delete(strCacheFilename) % Delete file if incomplete
                  error('CloudCacher:DownloadFailed', 'Something went wrong during download. Please try again.')
               end
            end
            
         catch mErr_Cause
            % - Throw an exception
            mErr_Base = MException('CloudCacher:AccessFailed', 'Could not access URL.');
            mErr_Base = mErr_Base.addCause(mErr_Cause);
            throw(mErr_Base);
         end
      end
      
      function cstrCacheFilenames = pwebsave(ccObj, cstrRelativeFilenames, cstrURLs, bProgress, varargin)
         % pwebsave - METHOD Parallel websave of several URLs
         %
         % Usage: cstrCachedFilename = pwebsave(ccObj, cstrRelativeFilenames, cstrURLs, bProgress, varargin)
         %
         % Replaces the Matlab `websave` function, with a cached method.
         % Optional additional varargin arguments are passed to `websave`.
         
         % - Are the URLs already in the cache?
         vbCacheHit = cellfun(@(u)(ccObj.IsInCache(u) && exist(ccObj.CachedFileForURL(u), 'file')), cstrURLs);
         
         % - Get file names for cache hits
         cstrCacheFilenames = cell(size(cstrURLs));
         cstrCacheFilenames(vbCacheHit) = cellfun(@(u)ccObj.CachedFileForURL(u), cstrURLs(vbCacheHit), 'UniformOutput', false);
         
         % - Can we exit quickly, if all were hits?
         if all(vbCacheHit)
            return;
         end
         
         % - Check that a pool exists
         if isempty(gcp('nocreate'))
            error('CouldCacher:NoParallel', ...
               'A parallel pool must exist to use ''pwebsave''.');
         end
         
         % - Helper function to generate cache-relative filenames
         function strRelativeFilename = getRelativeFilename(strRelativeFilename)
            if isempty(strRelativeFilename)
               [~, strRelativeFilename] = fileparts(tempname());
               strRelativeFilename = [strRelativeFilename '.mat'];
            end               
         end
            
         % - Get relative and cache filenames for each file
         cstrRelativeFilenames(~vbCacheHit) = cellfun(@getRelativeFilename, cstrRelativeFilenames(~vbCacheHit), 'UniformOutput', false);
         cstrCacheFilenames(~vbCacheHit) = cellfun(@(f)ccObj.CachedFilename(f), cstrRelativeFilenames(~vbCacheHit), 'UniformOutput', false);
         
         % - Ensure any required cache subdirectories exist
         w = warning('off', 'MATLAB:MKDIR:DirectoryExists');         
         cellfun(@(c)mkdir(fileparts(c)), cstrCacheFilenames(~vbCacheHit));
         warning(w);
            
         % - Check if the filename exists and warn
         vbFileExists = cellfun(@(f)exist(f, 'file'), cstrCacheFilenames(~vbCacheHit));
         if any(vbFileExists)
            warning('CloudCacher:FileExists', 'A cached file already exists; overwriting.');
         end
            
         % - Download data from the provided URLs and save
         vnMisses = find(~vbCacheHit);
         for nMiss = vnMisses
            fEval(nMiss) = parfeval(@websave, 1, cstrCacheFilenames{nMiss}, cstrURLs{nMiss}, varargin{:}); %#ok<AGROW>
         end
         
         % - Wait for download results
         for nMiss = vnMisses
            try
               % - Get the next completed result
               [nIdx, strCacheFilename] = fetchNext(fEval(vnMisses));
               cstrCacheFilenames{vnMisses(nIdx)} = strCacheFilename;
               
               % - Store the relative filename in the cache
               ccObj.mapCachedData(cstrURLs{nMiss}) = cstrRelativeFilenames{nMiss};

               % - Save the cache manifest
               ccObj.SaveManifest();
               
               % - Display some progress
               if (bProgress)
                  fprintf('Downloaded URL [%s]...\n', cstrURLs{nMiss});
               end

            catch meCause
               % - Report a warning when the download did not complete
               warning(getReport(meCause, 'extended', 'hyperlinks', 'on'));
               cstrCacheFilenames{nMiss} = '';
            end
         end
      end
      
      function data = webread(ccObj, strURL, strRelativeFilename, varargin)
         % webread - METHOD - Cached replacement for webread function
         %
         % Usage: data = ccObj.webread(strURL, strRelativeFilename, ...)
         %
         % Replaces the Matlab `webread` function with a cached method.
         % Optional arguments are passed to `webread`.
         
         try
            % - Is the URL already in the cache?
            if ccObj.IsInCache(strURL) && exist(ccObj.CachedFileForURL(strURL), 'file')
               % - Yes, so read the cached file
               strCachedFilename = ccObj.CachedFileForURL(strURL);
               sData = load(strCachedFilename);
               data = sData.data;
               
            else
               % - No, so we need to download and cache it
               
               % - Get a filename for the cache
               if ~exist('strRelativeFilename', 'var') || isempty(strRelativeFilename)
                  [~, strRelativeFilename] = fileparts(tempname());
                  strRelativeFilename = [strRelativeFilename '.mat'];
               end
               
               % - Convert the filename to a file in the cache
               strCacheFilename = ccObj.CachedFilename(strRelativeFilename);

               % - Ensure any required cache subdirectories exist
               w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
               mkdir(fileparts(strCacheFilename));
               warning(w);

               % - Check if the filename exists and warn
               if exist(strCacheFilename, 'file')
                  warning('CloudCacher:FileExists', 'The specified file already exists; overwriting.');
               end
               
               % - Download data from the provided URL and save
               data = webread(strURL, varargin{:});
               save(strCacheFilename, 'data');

               % - Add URL to cache and save manifest
               ccObj.mapCachedData(strURL) = strRelativeFilename;
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
      
      function strFile = RelativeFilename(ccObj, strCachedFilename)
          % RelativeFilename - METHOD Return the cache-relative location of a given cached file 
          %
          % Usage: strFile = RelativeFilename(ccObj, strCachedFilename)
          %
          % This method does NOT indicate whether or not the file exists in
          % the cache. If `strCachedFilename` is not a path in the cache,
          % then `strFile` will be empty.
          
          strFile = sscanf(strCachedFilename, [ccObj.strCacheDir '%s']);
      end
      
      function strFile = CachedFileForURL(ccObj, strURL)
         % CachedFileForURL - METHOD Return the full file path corresponding to a cached URL
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
         
         mapCachedData = ccObj.mapCachedData; %#ok<PROP>
         strVersion = ccObj.strVersion; %#ok<PROP>
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
               % - Raise a warning if we couldn't delete the file
               mE_Base = MException('CloudCacher:CouldNotDeleteCacheFile', ...
                                    'Cached URL could not be deleted from the cache.');
               mE_Base.addCause(mE_Cause);
               warning(getReport(mE_Base, 'extended', 'hyperlinks', 'on'));
            end

            % - Remove URL from map
            ccObj.mapCachedData.remove(strURL);
         end
      end
      
      function RemoveURLsMatchingSubstring(ccObj, strSubstring)
         % RemoveURLsMatchingSubstring - METHOD Remove all URLs from the cache containing a specified substring
         %
         % Usage: ccObj.RemoveURLsMatchingSubstring(strSubstring)
         %
         % This method uses the `contains` function to test whether a URL contains
         % the substring in `strSubstring`.
         
         % - Find keys matching the substring
         cstrAllKeys = ccObj.mapCachedData.keys();
         vbMatchingKeys = contains(cstrAllKeys, strSubstring);

         % - Remove matching URLs
         cellfun(@ccObj.RemoveURL, cstrAllKeys(vbMatchingKeys));
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