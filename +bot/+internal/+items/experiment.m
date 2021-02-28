%% experiment - CLASS Represent an experiment container

classdef experiment < handle
   properties (SetAccess = private)
      metadata;   % Metadata associated with this experiment container
      id;         % Experiment container ID
      
      sessions;   % Table of sessions in this experiment container
   end
   
   properties (Hidden = true, GetAccess = private, SetAccess = private)
      manifest = bot.internal.manifest('ophys');
   end
   
   methods
      function exp = experiment(id)
         % experiment - CLASS Encapsulate an experiment container
         
         % - Handle no-argument calling case
         if nargin == 0
            return;
         end
         
         % - Handle a vector of session IDs
         if ~istable(id) && numel(id) > 1
            for nIndex = numel(id):-1:1
               exp(id) = bot.internal.items.experiment(id(nIndex));
            end
            return;
         end
         
         % - Assign experiment container information
         exp.metadata = table2struct(exp.find_manifest_row(id));
         exp.id = exp.metadata.id;
         
         % - Extarct matching sessions
         matching_sessions = exp.manifest.ophys_sessions.experiment_container_id == exp.id;
         exp.sessions = exp.manifest.ophys_sessions(matching_sessions, :);
      end
   end
   
   methods (Static = true, Hidden = true)
      function manifest_row = find_manifest_row(id)
         % - Were we provided a table?
         if istable(id)
            experiment_row = id;
            
            % - Check for an 'id' column
            if ~ismember(experiment_row.Properties.VariableNames, 'id')
               error('BOT:InvalidExperimentTable', ...
                  'The provided table does not describe an experiment container.');
            end
            
            % - Extract the session IDs
            id = experiment_row.id;
         end
         
         % - Check for a numeric argument
         if ~isnumeric(id)
            help bot.experiment;
            error('BOT:Usage', ...
               'The experiment ID must be numeric.');
         end
         
         % - Find these sessions in the experiment manifest
         manifest = bot.internal.manifest('ophys');
         matching_ophys_container = manifest.ophys_containers.id == id;
         
         % - Extract the appropriate table row from the manifest
         if any(matching_ophys_container)
            manifest_row = manifest.ophys_containers(matching_ophys_container, :);
         end
         
         % - Check to see if the session exists
         if ~exist('manifest_row', 'var')
            error('BOT:InvalidExperimentID', ...
               'The provided experiment container ID [%d] was not found in the Allen Brain Observatory manifest.', ...
               id);
         end
      end
   end   
end

