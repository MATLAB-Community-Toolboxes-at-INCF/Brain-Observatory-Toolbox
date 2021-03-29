%% bot.item.session_base — CLASS Base class for experimental sessionss

classdef Session < handle & bot.item.abstract.NWBItem
 

   %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.NWBItem)
   
   % Public Property Access Methods 
   methods
   
       function url = get.nwbURL(bos)
          %Get the cloud URL for the NWB data file corresponding to this session
           
           % - Get well known files
           well_known_files = bos.info.well_known_files;
           
           % - Find (first) NWB file
           file_types = [well_known_files.well_known_file_type];
           type_names = {file_types.name};
           nwb_file_index = find(cellfun(@(c)strcmp(c, bos.NWB_WELL_KNOWN_FILE_PREFIX.char()), type_names), 1, 'first');
           
           % - Build URL
           url = [bos.bot_cache.strABOBaseUrl well_known_files(nwb_file_index).download_link];
       end
   end
   
   % Developer Properties   
   properties (Dependent, Hidden)
       nwbURL;
   end
   
   % Hidden Methods
   methods (Hidden)
       
       % Override bot.item.abstract.NWBItem
       function loc = ensureNWBCached(bos)                      
           if ~bos.nwbIsCached
               bos.CacheFilesForSessionIDs(bos.id); % dispatch to session cacher               
           end
           loc = bos.nwbLocalFile;
       end
   end         
   
   %% SUBCLASS INTERFACE
   
   properties (Abstract, Constant, Hidden)
       NWB_WELL_KNOWN_FILE_PREFIX (1,1) string
   end             
   
   %% HIDDEN INTERFACE - Properties
   
   properties (Access = protected)
      bot_cache = bot.internal.cache();                            % Private handle to the BOT Cache
      ophys_manifest = bot.internal.ophysmanifest.instance();              % Private handle to the OPhys data manifest
      ephys_manifest = bot.internal.ephysmanifest.instance();              % Private handle to the EPhys data manifest
   end
   
   %% HIDDEN INTERFACE - Methods
         
   % constructor
   methods
      function sess = Session(~)        
         % - Handle calling with no arguments
         if nargin == 0
            return;
         end
      end
   end     
 
   methods (Hidden) 
      
       function cached_files = CacheFilesForSessionIDs(sess, ids, use_parallel, num_tries)
         % CacheFilesForSessionIDs - METHOD Download data files containing experimental data for the given session IDs
         %
         % Usage: cached_files = CacheFilesForSessionIDs(sess, ids <, use_parallel, num_tries>)
         %
         % `ids` is a list of session IDs obtained from either the OPhys or
         % EPhys sessions table. The data files for these sessions will be
         % downloaded and cached, if they have not already been cached.
         %
         % The optional argument `use_parallel` allows you to specify
         % whether a pool of workers should be used to download several
         % data files simultaneously. A pool will *not* be created if one
         % does not already exist. By default, a pool will be used.
         %
         % The optional argument `num_tries` allows you to specify how many
         % attempts should be made to download each file befire giving up.
         % Default: 3
         
         % - Default arguments
         if ~exist('use_parallel', 'var') || isempty(use_parallel)
            use_parallel = true;
         end
         
         if ~exist('num_tries', 'var') || isempty(num_tries)
            num_tries = 3;
         end
         
         % - Loop over session IDs
         for session_index = numel(ids):-1:1
            % - Find this session in the sessions tables
            matching_ophys_session = sess.ophys_manifest.ophys_sessions.id == ids(session_index);
            
            if any(matching_ophys_session)
               session_row = sess.ophys_manifest.ophys_sessions(matching_ophys_session, :);
            else
               matching_ephys_session = sess.ephys_manifest.ephys_sessions.id == ids(session_index);
               session_row = sess.ephys_manifest.ephys_sessions(matching_ephys_session, :);
            end
            
            % - Check to see if the session exists
            if isempty(session_row)
               error('BOT:InvalidSessionID', ...
                  'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
                  ids(session_index));
               
            else
               % - Cache the corresponding session data files
               if iscell(session_row.well_known_files)
                  vs_well_known_files = session_row.well_known_files{1};
               else
                  vs_well_known_files = session_row.well_known_files;
               end
               urls{session_index} = arrayfun(@(s)strcat(sess.bot_cache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
               local_files{session_index} = {vs_well_known_files.path}';
               is_url_in_cache{session_index} = sess.bot_cache.IsURLInCache(urls{session_index});
            end
         end
         
         % - Consolidate all URLs to download
         urls = [urls{:}];
         local_files = [local_files{:}];
         is_url_in_cache = [is_url_in_cache{:}];
         
         % - Cache all sessions in parallel
         if numel(ids) > 1 && use_parallel && ~isempty(gcp('nocreate'))
            if any(~is_url_in_cache)
               fprintf('Downloading URLs in parallel...\n');
            end
            
            success = false;
            while ~success && (num_tries > 0)
               try
                  cached_files = sess.bot_cache.ccCache.pwebsave(local_files, [urls{:}], true);
                  success = true;
               catch
                  num_tries = num_tries - 1;
               end
            end
            
         else
            % - Cache sessions sequentially
            for url_index = numel(urls):-1:1
               % - Provide some progress text
               if ~is_url_in_cache(url_index)
                  fprintf('Downloading URL: [%s]...\n', urls{url_index});
               end
               
               % - Try to cache the data file
               success = false;
               while ~success && (num_tries > 0)
                  try
                     cached_files{url_index} = sess.bot_cache.CacheFile(urls{url_index}, local_files{url_index});
                     success = true;
                  catch cause
                     num_tries = num_tries - 1;
                  end
               end
               
               % - Raise an error on failure
               if ~success
                  base = MException('BOT:CouldNotCacheURL', ...
                     'A data file could not be cached.');
                  base = base.addCause(cause);
                  throw(base);
               end
            end
         end
      end
   end    
   

   
%   methods (Static, Hidden)
%       function manifest_row = find_manifest_row(id)
%          sess = bot.item.session_base;
%          
%          % - Were we provided a table?
%          if istable(id)
%             session_row = id;
%             
%             % - Check for an 'id' column
%             if ~ismember(session_row.Properties.VariableNames, 'id')
%                error('BOT:InvalidSessionTable', ...
%                   'The provided table does not describe an experimental session.');
%             end
%             
%             % - Extract the session IDs
%             id = session_row.id;
%          end
%          
%          % - Check for a numeric argument
%          if ~isnumeric(id)
%             help bot.session;
%             error('BOT:Usage', ...
%                'The session ID must be numeric.');
%          end
%          
%          % - Find these sessions in the sessions manifests
%          matching_ophys_session = sess.ophys_manifest.ophys_sessions.id == id;
%          
%          % - Extract the appropriate table row from the manifest
%          if any(matching_ophys_session)
%             manifest_row = sess.ophys_manifest.ophys_sessions(matching_ophys_session, :);
%          else
%             matching_ephys_session = sess.ephys_manifest.ephys_sessions.id == id;
%             manifest_row = sess.ephys_manifest.ephys_sessions(matching_ephys_session, :);
%          end
%          
%          % - Check to see if the session exists
%          if ~exist('manifest_row', 'var')
%             error('BOT:InvalidSessionID', ...
%                'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
%                id);
%          end
%       end
%   end   
   
     
end