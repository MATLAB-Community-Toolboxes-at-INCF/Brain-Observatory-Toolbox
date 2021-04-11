%% bot.item.session_base — CLASS Base class for experimental sessionss

classdef Session < handle & bot.item.mixin.LinkedFiles
 

   %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.NWBItem)
   
%    % Public Property Access Methods 
%    methods
%    
%        function url = get.nwbURL(bos)
%           %Get the cloud URL for the NWB data file corresponding to this session
%            
%            % - Get well known files
%            well_known_files = bos.info.well_known_files;
%            
%            % - Find (first) NWB file
%            file_types = [well_known_files.well_known_file_type];
%            type_names = {file_types.name};
%            nwb_file_index = find(cellfun(@(c)strcmp(c, bos.NWB_WELL_KNOWN_FILE_PREFIX.char()), type_names), 1, 'first');
%            
%            % - Build URL
%            url = [bos.bot_cache.strABOBaseUrl well_known_files(nwb_file_index).download_link];
%        end
%    end
%    
%    % Developer Properties   
%    properties (Dependent, Hidden)
%        nwbURL;
%    end
%    
%    % Hidden Methods
%    methods (Hidden)
%        
%        % Override bot.item.abstract.NWBItem
%        function loc = ensureNWBCached(bos)                      
%            if ~bos.nwbIsCached
%                bos.CacheFilesForSessionIDs(bos.id); % dispatch to session cacher               
%            end
%            loc = bos.nwbLocalFile;
%        end
%    end         
   
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