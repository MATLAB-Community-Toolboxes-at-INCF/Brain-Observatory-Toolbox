% CloudCacher - Manages a local file cache for arbitrary URLs
%
% CloudCacher is a class that provides replacements for `webread` and
% `websave` that are cached locally. It is stateful, and can be
% reinitialised by providing the location of an extant cache dir.

classdef CloudCacher < bot.internal.abstract.LocalFileCache

    properties (Constant)
        CacheName = 'CC' % (Short name)
    end
   
    methods
        function obj = CloudCacher(cacheDirectory)
        % CloudCacher - Create a cloud cache instance
        %
        %   Syntax: 
        %       CLOUDCACHE = CloudCache() creates a new temporary cloud 
        %       cache.
        %
        %       CLOUDCACHE = CloudCache(CACHEDIRECTORY) creates new or 
        %       reinitialises an existing permanent cloud cache.
        %
        %   Input arguments:
        %       CACHEDIRECTORY - Path string for a cache directory.
        %           If the specified directory does not exist, a new
        %           directory is created. Otherwise the cache is
        %           reinitialised based on the contents of the directory.
        %
        %   Output arguments:
        %       CLOUDCACHE - A newly created cloud cache instance.
        %
        %   See also bot.internal.abstract.LocalFileCache/LocalFileCache

            if nargin < 1; cacheDirectory = ''; end
            obj@bot.internal.abstract.LocalFileCache(cacheDirectory)
        end
    end

    methods

        function strCacheFilename = copyfile(obj, strURL, strRelativeFilename, strCloudFilepath)
        % copyfile - Cached replacement for copyfile function
        
        % Hint: Copy files from S3 bucket to EC2 local drive
        
            strCacheFilename = obj.getCachedFilename(strRelativeFilename);
            
            targetFolder = fileparts(strCacheFilename);
            if ~isfolder(targetFolder); mkdir(targetFolder); end
            
            try
                copyfile(strCloudFilepath, strCacheFilename)
                obj.CacheMap(strURL) = strRelativeFilename;
                obj.saveManifest();
            catch mErr_Cause
                mErr_Base = MException('CloudCacher:FileCopyFailed', 'Could not copy file from S3 bucket.');
                mErr_Base = mErr_Base.addCause(mErr_Cause);
                throw(mErr_Base);
            end
        end
        
        function strCacheFilename = websave(obj, strRelativeFilename, strURL, varargin)
        % websave - Cached replacement for websave function
        %
        % Usage: strCacheFilename = obj.websave(strRelativeFilename, strURL, ...)
        %
        % Replaces the Matlab `websave` function, with a cached method.
        
        % Note: This feature (passing varargins to websave function) 
        % was removed when replacing websave with downloadFile 
        % (Todo: Consider to reimplement):
        % Optional additional arguments are passed to `websave`.
            
            import bot.external.fex.filedownload.downloadFile
            
            % Check varargin for optional SecondaryFileUrl (Todo: Add documentation)
            isSecondaryFileArg = cellfun(@(arg) ischar(arg) && strcmp(arg, 'SecondaryFileUrl'), varargin);
            if any( isSecondaryFileArg )
                fileDownloadUrl = varargin{ find(isSecondaryFileArg) + 1};
                %varargin(find(isSecondaryFileArg) + 0:1) = []; Placeholder
            else
                fileDownloadUrl = strURL;
            end
            
            try
                % - Is the URL already in the cache?
                if obj.isInCache(strURL) && exist(obj.getCachedFilePathForKey(strURL), 'file')
                    % - Yes, so read the cached file
                    strCacheFilename = obj.getCachedFilePathForKey(strURL);
                else
                    % - No, so we need to download and cache it
                    
                    % - Get a filename for the cache
                    if isempty(strRelativeFilename)
                        [~, strRelativeFilename] = fileparts(tempname());
                        [~, ~, fileExtension] = fileparts(char(strURL));
                        if ~isempty(fileExtension)
                            strRelativeFilename = [strRelativeFilename fileExtension];
                        end
                    end
                   
                    % - Convert the filename to a file in the cache
                    strCacheFilename = obj.getCachedFilename(strRelativeFilename);
                    
                    % - Ensure any required cache subdirectories exist
                    w = warning('off', 'MATLAB:MKDIR:DirectoryExists');
                    mkdir(fileparts(strCacheFilename));
                    warning(w);
                   
                    % - Check if the filename exists and warn
                    if exist(strCacheFilename, 'file')
                        warning('CloudCacher:FileExists', 'The specified file already exists; overwriting.');
                    end
                   
                    fileSizeWeb = bot.internal.util.getWebFileSize(fileDownloadUrl);
                    C = onCleanup( @(filename, filesize) ...
                        cleanUpFileDownload(strCacheFilename, fileSizeWeb) );
                
                    % - Download data from the provided URL and save
                    strCacheFilename = downloadFile(strCacheFilename, fileDownloadUrl, ...
                        'DisplayMode', bot.internal.Preferences.getPreferenceValue('DialogMode'));
                
                    % - Check that we got the complete file
                    fileSizeWeb = bot.internal.util.getWebFileSize(strURL);
                    fileSizeLocal = bot.internal.util.getLocalFileSize(strCacheFilename);
                   
                    if fileSizeWeb == fileSizeLocal
                        % - Add URL to cache and save manifest
                        obj.CacheMap(strURL) = strRelativeFilename;
                        obj.saveManifest();
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
        
        function cstrCacheFilenames = pwebsave(obj, cstrRelativeFilenames, cstrURLs, bProgress, varargin)
        % pwebsave - Parallel websave of several URLs
        %
        % Usage: cstrCachedFilename = pwebsave(obj, cstrRelativeFilenames, cstrURLs, bProgress, varargin)
        %
        % Replaces the Matlab `websave` function, with a cached method.
        % Optional additional varargin arguments are passed to `websave`.
            
            % - Are the URLs already in the cache?
            vbCacheHit = cellfun(@(u)(obj.isInCache(u) && exist(obj.getCachedFilePathForKey(u), 'file')), cstrURLs);
            
            % - Get file names for cache hits
            cstrCacheFilenames = cell(size(cstrURLs));
            cstrCacheFilenames(vbCacheHit) = cellfun(@(u)obj.getCachedFilePathForKey(u), cstrURLs(vbCacheHit), 'UniformOutput', false);
            
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
            cstrCacheFilenames(~vbCacheHit) = cellfun(@(f)obj.getCachedFilename(f), cstrRelativeFilenames(~vbCacheHit), 'UniformOutput', false);
            
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
                    obj.CacheMap(cstrURLs{nMiss}) = cstrRelativeFilenames{nMiss};
                    
                    % - Save the cache manifest
                    obj.saveManifest();
                    
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
        
        function data = webread(obj, strURL, strRelativeFilename, varargin)
        % webread - Cached replacement for webread function
        %
        % Usage: data = obj.webread(strURL, strRelativeFilename, ...)
        %
        % Replaces the Matlab `webread` function with a cached method.
        % Optional arguments are passed to `webread`.
            
            try
                % - Is the URL already in the cache?
                if obj.isInCache(strURL) && exist(obj.getCachedFilePathForKey(strURL), 'file')
                   % - Yes, so read the cached file
                   strCachedFilename = obj.getCachedFilePathForKey(strURL);
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
                   strCacheFilename = obj.getCachedFilename(strRelativeFilename);
                
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
                   obj.CacheMap(strURL) = strRelativeFilename;
                   obj.saveManifest();
                end

            catch mErr_Cause
                % - Throw an exception
                mErr_Base = MException('CloudCacher:AccessFailed', 'Could not access URL.');
                mErr_Base = mErr_Base.addCause(mErr_Cause);
                throw(mErr_Base);
            end
        end

    end

    methods
      
        function strFile = getRelativeFilepath(obj, strCachedFilename)
        % getRelativeFilepath - Return the cache-relative location of a given cached file 
        %
        % Usage: strFile = RelativeFilename(obj, strCachedFilename)
        %
        % This method does NOT indicate whether or not the file exists in
        % the cache. If `strCachedFilename` is not a path in the cache,
        % then `strFile` will be empty.
        
        % Question: Is this used?
            strFile = sscanf(strCachedFilename, [obj.CacheDirectory '%s']);
        end
      
        function removeURLsMatchingSubstring(obj, subString)
        % removeURLsMatchingSubstring - Remove all URLs from the cache 
        % containing a specified substring
        %
        % Usage: obj.removeURLsMatchingSubstring(subString)
        %
        % This method uses the `contains` function to test whether a URL 
        % (cache key) contains the substring in `subString`.
        
            % - Find keys matching the substring
            cstrAllKeys = obj.CacheMap.keys();
            vbMatchingKeys = contains(cstrAllKeys, subString);
            
            % - Remove matching URLs
            cellfun(@obj.remove, cstrAllKeys(vbMatchingKeys));
        end

   end
end

function cleanUpFileDownload(strFilename, webFileSize)
    fileSizeLocal = bot.internal.util.getLocalFileSize(strFilename);
    if fileSizeLocal < webFileSize
        if isfile(strFilename)
            delete(strFilename)
        end
    end        
end