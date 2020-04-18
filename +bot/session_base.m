%% CLASS session

classdef session_base
   
   properties (SetAccess = protected)
      sSessionInfo;              % Structure containing session metadata
   end
   
   properties (Access = protected)
      bocCache = bot.internal.cache();                   % Private handle to the BOT Cache
      bomOPhysManifest = bot.ophysmanifest;              % Private handle to the OPhys data manifest
      bomEPhysManifest = bot.ephysmanifest;              % Private handle to the EPhys data manifest
   end
   
   methods
      function sess = session_base(nSessionID)
         % bot.session_base - CLASS Base class for experimental sessions

         % - Handle calling with no arguments
         if nargin == 0
            return
         end
         
         % - Assign session information
         sess.sSessionInfo = table2struct(sess.find_manifest_row(nSessionID));
      end
   end
   
   methods (Static)
      function tManifestRow = find_manifest_row(nSessionID)
         sess = bot.session_base;
         
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
            help bot.session/build_session;
            error('BOT:Usage', ...
               'The session ID must be numeric.');
         end
         
         % - Find these sessions in the sessions manifests
         vbOPhysSession = sess.bomOPhysManifest.tOPhysSessions.id == nSessionID;

         % - Extract the appropriate table row from the manifest
         if any(vbOPhysSession)
            tManifestRow = sess.bomOPhysManifest.tOPhysSessions(vbOPhysSession, :);
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
            vbOPhysSession = sess.bomOPhysManifest.tOPhysSessions.id == vnSessionIDs(nSessIndex);
            
            if any(vbOPhysSession)
               tSession = sess.bomOPhysManifest.tOPhysSessions(vbOPhysSession, :);
            else
               vbEPhysSession = sess.bomOPhysManifest.tEPhysSessions.id == vnSessionIDs(nSessIndex);
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
               cstrURLs{nSessIndex} = arrayfun(@(s)strcat(oCache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
               cstrLocalFiles{nSessIndex} = {vs_well_known_files.path}';
               cvbIsURLInCache{nSessIndex} = oCache.IsURLInCache(cstrURLs{nSessIndex});
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
                  cstrCacheFiles = oCache.sCacheFiles.ccCache.pwebsave(cstrLocalFiles, [cstrURLs{:}], true);
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
                     cstrCacheFiles{nURLIndex} = oCache.CacheFile(cstrURLs{nURLIndex}, cstrLocalFiles{nURLIndex});
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