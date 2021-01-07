%% bot.internal.session_base — CLASS Base class for experimental sessionss

%%%%%%% REFACTOR TO BOT.INTERNAL.SESSION %%%%%%%

classdef session_base < handle
   properties (Access = protected)
      bot_cache = bot.internal.cache();                            % Private handle to the BOT Cache
      ophys_manifest = bot.internal.ophysmanifest;              % Private handle to the OPhys data manifest
      bomEPhysManifest = bot.internal.ephysmanifest;              % Private handle to the EPhys data manifest
      strLocalNWBFileLocation;
   end
   
   methods
      function sess = session_base(~)
         % bot.session_base - CLASS Base class for experimental sessions
         
         % - Handle calling with no arguments
         if nargin == 0
            return;
         end
      end
   end
   
   %% - Matlab BOT methods
   
   methods
      function bNWBFileIsCached = IsNWBFileCached(bos)
         % IsNWBFileCached - METHOD Check if the NWB file corresponding to this session is already cached
         %
         % Usage: bNWBFileIsCached = IsNWBFileCached(bos)
         bNWBFileIsCached =  bos.bot_cache.IsURLInCache(bos.nwb_url());
      end
      
      function strCacheFile = EnsureCached(bos)
         % EnsureCached - METHOD Ensure the data files corresponding to this session are cached
         %
         % Usage: strCachelFile = EnsureCached(bos)
         %
         % This method will force the session data to be downloaded and cached,
         % if it is not already available.
         bos.CacheFilesForSessionIDs(bos.id);
         strCacheFile = bos.strLocalNWBFileLocation;
      end      
   end
   
   methods
      function strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         % get.strLocalNWBFileLocation - GETTER METHOD Return the local location of the NWB file correspoding to this session
         %
         % Usage: strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         if ~bos.IsNWBFileCached()
            strLocalNWBFileLocation = [];
         else
            % - Get the local file location for the session NWB URL
            strLocalNWBFileLocation = bos.bot_cache.ccCache.CachedFileForURL(bos.nwb_url());
         end
      end
   end   
   methods (Static)
      function tManifestRow = find_manifest_row(nSessionID)
         sess = bot.internal.session_base;
         
         % - Were we provided a table?
         if istable(nSessionID)
            tSession = nSessionID;
            
            % - Check for an 'id' column
            if ~ismember(tSession.Properties.VariableNames, 'id')
               error('BOT:InvalidSessionTable', ...
                  'The provided table does not describe an experimental session.');
            end
            
            % - Extract the session IDs
            nSessionID = tSession.id;
         end
         
         % - Check for a numeric argument
         if ~isnumeric(nSessionID)
            help bot.session;
            error('BOT:Usage', ...
               'The session ID must be numeric.');
         end
         
         % - Find these sessions in the sessions manifests
         vbOPhysSession = sess.ophys_manifest.tOPhysSessions.id == nSessionID;
         
         % - Extract the appropriate table row from the manifest
         if any(vbOPhysSession)
            tManifestRow = sess.ophys_manifest.tOPhysSessions(vbOPhysSession, :);
         else
            vbEPhysSession = sess.bomEPhysManifest.tEPhysSessions.id == nSessionID;
            tManifestRow = sess.bomEPhysManifest.tEPhysSessions(vbEPhysSession, :);
         end
         
         % - Check to see if the session exists
         if ~exist('tManifestRow', 'var')
            error('BOT:InvalidSessionID', ...
               'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
               nSessionID);
         end
      end
   end
   
   methods
      function cstrCacheFiles = CacheFilesForSessionIDs(sess, vnSessionIDs, bUseParallel, nNumTries)
         % CacheFilesForSessionIDs - METHOD Download data files containing experimental data for the given session IDs
         %
         % Usage: cstrCacheFiles = CacheFilesForSessionIDs(sess, vnSessionIDs <, bUseParallel, nNumTries>)
         %
         % `vnSessionIDs` is a list of session IDs obtained from either the
         % OPhys or EPhys sessions table. The data files for these
         % sessions will be downloaded and cached, if they have not already
         % been cached.
         %
         % The optional argument `bUseParallel` allows you to specify
         % whether a pool of workers should be used to download several
         % data files simultaneously. A pool will *not* be created if one
         % does not already exist. By default, a pool will be used.
         %
         % The optional argument `nNumTries` allows you to specify how many
         % attempts should be made to download each file befire giving up.
         % Default: 3
         
         % - Default arguments
         if ~exist('bUseParallel', 'var') || isempty(bUseParallel)
            bUseParallel = true;
         end
         
         if ~exist('nNumTries', 'var') || isempty(nNumTries)
            nNumTries = 3;
         end
         
         % - Loop over session IDs
         for nSessIndex = numel(vnSessionIDs):-1:1
            % - Find this session in the sessions tables
            vbOPhysSession = sess.ophys_manifest.tOPhysSessions.id == vnSessionIDs(nSessIndex);
            
            if any(vbOPhysSession)
               tSession = sess.ophys_manifest.tOPhysSessions(vbOPhysSession, :);
            else
               vbEPhysSession = sess.bomEPhysManifest.tEPhysSessions.id == vnSessionIDs(nSessIndex);
               tSession = sess.bomEPhysManifest.tEPhysSessions(vbEPhysSession, :);
            end
            
            % - Check to see if the session exists
            if isempty(tSession)
               error('BOT:InvalidSessionID', ...
                  'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
                  vnSessionIDs(nSessIndex));
               
            else
               % - Cache the corresponding session data files
               if iscell(tSession.well_known_files)
                  vs_well_known_files = tSession.well_known_files{1};
               else
                  vs_well_known_files = tSession.well_known_files;
               end
               cstrURLs{nSessIndex} = arrayfun(@(s)strcat(sess.bot_cache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
               cstrLocalFiles{nSessIndex} = {vs_well_known_files.path}';
               cvbIsURLInCache{nSessIndex} = sess.bot_cache.IsURLInCache(cstrURLs{nSessIndex});
            end
         end
         
         % - Consolidate all URLs to download
         cstrURLs = [cstrURLs{:}];
         cstrLocalFiles = [cstrLocalFiles{:}];
         vbIsURLInCache = [cvbIsURLInCache{:}];
         
         % - Cache all sessions in parallel
         if numel(vnSessionIDs) > 1 && bUseParallel && ~isempty(gcp('nocreate'))
            if any(~vbIsURLInCache)
               fprintf('Downloading URLs in parallel...\n');
            end
            
            bSuccess = false;
            while ~bSuccess && (nNumTries > 0)
               try
                  cstrCacheFiles = sess.bot_cache.ccCache.pwebsave(cstrLocalFiles, [cstrURLs{:}], true);
                  bSuccess = true;
               catch
                  nNumTries = nNumTries - 1;
               end
            end
            
         else
            % - Cache sessions sequentially
            for nURLIndex = numel(cstrURLs):-1:1
               % - Provide some progress text
               if ~vbIsURLInCache(nURLIndex)
                  fprintf('Downloading URL: [%s]...\n', cstrURLs{nURLIndex});
               end
               
               % - Try to cache the data file
               bSuccess = false;
               while ~bSuccess && (nNumTries > 0)
                  try
                     cstrCacheFiles{nURLIndex} = sess.bot_cache.CacheFile(cstrURLs{nURLIndex}, cstrLocalFiles{nURLIndex});
                     bSuccess = true;
                  catch mE_Cause
                     nNumTries = nNumTries - 1;
                  end
               end
               
               % - Raise an error on failure
               if ~bSuccess
                  mE_Base = MException('BOT:CouldNotCacheURL', ...
                     'A data file could not be cached.');
                  mE_Base = mE_Base.addCause(mE_Cause);
                  throw(mE_Base);
               end
            end
         end
      end
   end
end