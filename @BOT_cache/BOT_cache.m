%% CLASS BOT_cache - Cache and cloud acces class for Brain Observatory Toolbox
%
% Usage: oBOCache = BOT_cache()
% 
% Primary interface to the Allen Brain Observatory toolbox. 

%% Class definition
classdef BOT_cache < handle
   
   properties (SetAccess = immutable)
      strVersion = '0.01';             % Version string for cache class
   end
   
   properties (SetAccess = private)
      strCacheDir;                     % Path to location of cached Brain Observatory data
      sCacheFiles;                     % Structure containing file paths of cached files
      sessions_table;                  % Table of all experimental sessions
   end
   
   properties (SetAccess = private)
   end
   
   properties (Access = private)
      bManifestsLoaded = false;         % Flag that indicates whether manifests have been loaded
      manifests;                        % Structure containing Allen Brain Observatory manifests
   end
   
   methods
      %% - Constructor
      function oCache = BOT_cache(varargin)
         % CONSTRUCTOR - Returns an object for managing data access to the Allen Brain Observatory
         
         % - Find and return the global cache object, if one exists
         sUserData = get(0, 'UserData');
         if isfield(sUserData, 'BOT_GLOBAL_CACHE') && ...
               isa(sUserData.BOT_GLOBAL_CACHE, 'BOT_cache') && ...
               isequal(sUserData.BOT_GLOBAL_CACHE.strVersion, oCache.strVersion)
            
            % - A global class instance exists, and is the correct version
            oCache = sUserData.BOT_GLOBAL_CACHE;
            return;            
         end
         
         %% - Set up a cache object, if no object exists
         
         % - Get the cache directory
         strBOTDir = fileparts(which('BOT_cache'));
         oCache.strCacheDir = [strBOTDir filesep 'Cache'];
         
         % - Ensure the cache directory exists
         if ~exist(oCache.strCacheDir, 'dir')
            mkdir(oCache.strCacheDir);
         end
         
         % - Populate cached filenames
         oCache.sCacheFiles.manifest = [oCache.strCacheDir filesep 'manifests.mat'];
         
         % - Assign the cache object to a global cache
         sUserData.BOT_GLOBAL_CACHE = oCache;
         set(0, 'UserData', sUserData);
      end
   end
   
   %% Getter and Setter methods
   
   methods
      function sessions_table = get.sessions_table(oCache)
         % METHOD - Return the table of all experimental sessions
         
         % - Make sure the manifest has been loaded
         oCache.EnsureManifestsLoaded();
         
      end
   end

   methods
      function EnsureManifestsLoaded(oCache)
         % METHOD - Read the manifest from the cache, or download
         
         % - Check to see if the manifest has been loaded
         if oCache.bManifestsLoaded
            return;
         end
         
         try
            % - Read the manifests from disk, if it exists
            if ~exist(oCache.sCacheFiles.manifests, 'file')
               BOT_cache.UpdateManifest()
            else
               oCache.manifest = load(oCache.sCacheFiles.manifests, 'manifests');
            end
            
         catch mE_cause
            
         end
         
         oCache.bManifestLoaded = true;
      end
   end
   
   %% Session table filtering properties and methods

   
   methods
   end
   
   
   %% Methods for returning a 
   
   %% Static class methods
   methods (Static)
      function UpdateManifest
         % STATIC METHOD - Check and update file manifest from Allen Brain Observatory API
         
         try
            % - Get a cache object
            oBOCache = BOT_cache();
            
            % - Download the manifest from the Allen Brain API
            manifests = get_manifests_info_from_api(); %#ok<NASGU>
            
            % - Save the manifest to the cache directory
            save(oCache.sCacheFiles.manifests, 'manifests');
         
         catch mE_cause
            % - Throw an error
            mEBase = MException('BOT:UpdateManifestFailed', ...
                 'Unable to update the Allen Brain Observatory manifest.');
            mEBase.addCause(mE_cause);
         end
      end
   end
   
end   
   