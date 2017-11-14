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
            oCache = BOT_cache();
            
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
   
   %% Private methods
   
   methods (Access = private, Static = true)
      
      function [manifests] = get_manifests_info_from_api
         
         % PRIVATE METHOD - get_manifests_info_from_api
         %
         % Usage: [manifests] = get_manifests_info_from_api
         %
         % Download `container_manifest`, `session_manifest`, `cell_id_mapping`
         % from brain observatory api as matlab tables. Returns the tables as fields
         % of a structure.
         
         container_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::ExperimentContainer,rma::include,ophys_experiments,isi_experiment,specimen%28donor%28conditions,age,transgenic_lines%29%29,targeted_structure,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
         session_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::OphysExperiment,rma::include,experiment_container,well_known_files%28well_known_file_type%29,targeted_structure,specimen%28donor%28age,transgenic_lines%29%29,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
         cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';
         
         options1 = weboptions('ContentType','JSON','TimeOut',60);
         
         container_manifest_raw = webread(container_manifest_url,options1);
         manifests.container_manifest = struct2table(container_manifest_raw.msg);
         
         session_manifest_raw = webread(session_manifest_url,options1);
         manifests.session_manifest = struct2table(session_manifest_raw.msg);
         
         options2 = weboptions('ContentType','table','TimeOut',60);
         
         manifests.cell_id_mapping = webread(cell_id_mapping_url,options2);
         
         % create cre_line table from specimen field of session_manifest and
         % append it back to session_manifest table
         % cre_line is important,make my life easier if it's explicit
         
         session_table = manifests.session_manifest;
         cre_line = cell(size(session_table,1),1);
         for i = 1:size(session_table,1)
            donor_info = session_table(i,:).specimen.donor;
            transgenic_lines_info = struct2table(donor_info.transgenic_lines);
            %         cre_line(i,1) = transgenic_lines_info.name(string(transgenic_lines_info.transgenic_line_type_name) == 'driver' & ...
            %             contains(transgenic_lines_info.name, 'Cre'));
            cre_line(i,1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
               & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
         end
         
         manifests.session_manifest = [session_table, cre_line];
         manifests.session_manifest.Properties.VariableNames{'Var15'} = 'cre_line';
         
      end
   end
   
end   
   