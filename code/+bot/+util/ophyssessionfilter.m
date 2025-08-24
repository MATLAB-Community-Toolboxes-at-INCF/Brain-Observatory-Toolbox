%% CLASS bot.util.ophyssessionfilter - Utility operations for filtering Visual Coding 2P dataset experimental sessions
%
% This class is deprecated. Use `bot.listSessions('ophys') to obtain the manifest for
% the Visual Coding 2P dataset [1], and filter the tables directly.
%
% This class implements a mechanism for searching the optical physiology
% experimental sessions within the Visual Coding 2P dataset. 
%
% Note: `bot.sessionfilter` is a handle class, which means that copies
% of an object point to the same object. This means you should create new
% `sessionfilter` objects if you want to keep the results of several
% filtering chains.
%
% Construction:
% >> bosf = bot.util.ophyssessionfilter()
% bosf =
%   ophyssessionfilter with properties:
%     filtered_session_table: [543x15 table]
%                   stimulus: {9x1 cell}
%         targeted_structure: {6x1 cell}
%     ...
%
% Filter by targetted structure:
% >> bosf.filter_sessions_by_targetted_structre('VISp')
% ans =
%   sessionfilter with properties:
%     filtered_session_table: [138x15 table]
%     ...
%
% See all methods for information about filtering options. Access the object
% properties to retrieve a summary of which experimental sessions remain after
% filtering.
%
% Get summaries of all session data:
% >> bosf.get_all_cre_lines();
% >> bosf.get_all_targeted_structures();
% >> bosf.get_all_imaging_depths();
%
% Obtain session objects for remaining sessions after filtering:
% >> vsSessions = bosf.get_filtered_sessions()
% ans =
%   1x138 session array with properties:
%     sSessionInfo
%     local_nwb_file_location
%
% Clear filters and start again:
% >> bosf.clear_filters();
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: portal.brain-map.org/explore/circuits/visual-coding-2p.
%

%% Class definition
classdef ophyssessionfilter < handle
   %% - Properties for global filtering of sessions table, included for backwards compatibility
   properties (SetAccess = private, Transient = true, Hidden = false)
      valid_session_table = nan;       % A table of all valid sessions, which by default contains all sessions excluding failed ones
      filtered_session_table = nan;    % A table of sessions that is progressively filtered
      stimulus;                        % A categorical array containing all the stimulus types from filtered_session_table
      targeted_structure;              % A categorical array containing all the brain areas from filtered_session_table
      imaging_depth;                   % A categorical array containing all the cortical depths from filtered_session_table
      container_id;                    % A vector containing all the container ids from filtered_session_table
      session_id;                      % A vector containing all the session ids from filtered_session_table
      session_type;                    % A categorical array containing all the session types from filtered_session_table
      cre_line;                        % A categorical array containing all the cre lines from filtered_session_table
      eye_tracking_avail;              % A boolean vector containing all conditions if eye tracking is available or not from filtered_session_table
      %         failed = false;                  % Boolean flag: should failed sessions be included?
   end
   
   %% - Private properties
   properties (Hidden = true, SetAccess = private, Transient = true)
      ophys_manifest = bot.item.internal.OphysManifest.instance();
   end
   
   %% Constructor
   methods
      
      function bosf = ophyssessionfilter()
         % - Display warning of deprecated class
         warning('The `bot.util.ophyssessionfilter` class is deprecated. Use `bot.list...()` to obtain data manifests, and filter the tables directly.');
         
         % - Get the unfiltered session table, clear all filters
         clear_filters(bosf);
      end
   end

   %% Session table filtering properties and methods
   
   methods
      function clear_filters(bosf)
         % clear_filters - METHOD Clear all session table filters
         failed_container_id = bosf.ophys_manifest.ophys_experiments((bosf.ophys_manifest.ophys_experiments.failed == 1), :).id;
         bosf.valid_session_table = bosf.ophys_manifest.ophys_sessions(~ismember(bosf.ophys_manifest.ophys_sessions.experiment_container_id, failed_container_id), :);
         bosf.filtered_session_table = bosf.valid_session_table;
      end
      
      function result = get_total_num_of_containers(bosf,varargin)
         % get_total_num_of_containers - METHOD Return the total number of experiment containers from ophys_sessions
         result = size(bosf.valid_session_table, 1) / 3;
      end
      
      
      function result = get_all_imaging_depths(bosf)
         % get_all_imaging_depths - METHOD Return all the cortical depths from ophys_sessions
         result = unique(bosf.valid_session_table.imaging_depth);
      end
      
      
      function result = get_all_targeted_structures(bosf)
         % get_all_targeted_structures - METHOD Return all the brain areas from ophys_sessions
         
         targeted_structure_table = struct2table(bosf.valid_session_table.targeted_structure);
         result = categories(categorical(targeted_structure_table.acronym));
      end
      
      
      function result = get_all_session_types (bosf)
         % get_all_session_types - METHOD Return all the session types from ophys_sessions
         result = categories(categorical(bosf.valid_session_table.stimulus_name));
      end
      
      
      function result = get_all_stimuli(bosf)
         % get_all_stimuli - METHOD Return all stimulus types from ophys_sessions
         
         session_by_stimuli = bosf.get_session_by_stimuli();
         result = [];
         for iSession = 1: length(bosf.session_type)
            result = [result, session_by_stimuli.(char(bosf.session_type(iSession)))]; %#ok<AGROW>
         end
         result = categories(categorical(result));
      end
      
      function result = get_all_cre_lines (bosf)
         % get_all_cre_lines - METHOD Return all cre lines from ophys_sessions
         result = categories(categorical(bosf.valid_session_table.cre_line));
      end
      
      
      function get_summary_of_containers_along_imaging_depths(bosf)
         % get_summary_of_containers_along_imaging_depths - METHOD Return the number of experiment containers recorded at each cortical depth
         summary(categorical(cellstr(num2str((bosf.ophys_manifest.ophys_containers.imaging_depth)))))
      end
      
      function get_summary_of_containers_along_targeted_structures (bosf)
         % get_summary_of_containers_along_targeted_structures - METHOD Return the number of experiment containers recorded in each brain region
         container_targeted_structure_table = struct2table(bosf.ophys_manifest.ophys_containers.targeted_structure);
         summary(categorical(cellstr(container_targeted_structure_table.acronym)))
      end
      
      function summary_table = get_summary_of_containers_along_depths_and_structures(bosf)
         % get_summary_of_containers_along_depths_and_structures - METHOD Return the number of experiment containers recorded at each cortical depth in each brain region
         
         % - Preallocate the summary matrix
         summary_matrix = nan(length(bosf.get_all_imaging_depths()), length(bosf.get_all_targeted_structures()));
         
         % - Get list of all imaging depths and targeted structures for table variable names
         all_depths =  bosf.get_all_imaging_depths();
         all_structures = bosf.get_all_targeted_structures;
         
         % - Loop over imaging depths and structures to build summary
         for cur_depth = 1: size(bosf.get_all_imaging_depths(),1)
            for cur_structure = 1: size(bosf.get_all_targeted_structures,1)
               % - Find matching imaging depths
               vbMatchImDepth = bosf.valid_session_table.imaging_depth == all_depths(cur_depth);
               
               % - Find matching targeted structures
               exp_targeted_structure_session_table = [bosf.valid_session_table.targeted_structure];
               vbMatchTargeted = ismember({exp_targeted_structure_session_table.acronym}, all_structures{cur_structure})';
               
               % - Build summary matrix
               summary_matrix(cur_depth,cur_structure) = nnz(vbMatchImDepth & vbMatchTargeted) / 3;
            end
         end
         
         % - Build summary table
         summarize_by_depths = sum(summary_matrix,2);
         summary_matrix = [summary_matrix,summarize_by_depths];
         summarize_by_structures = sum(summary_matrix,1);
         summary_matrix = [summary_matrix; summarize_by_structures];
         summary_table = array2table(summary_matrix);
         summary_table.Properties.VariableNames = [all_structures;'total'];
         summary_table.Properties.RowNames = [cellstr(num2str(all_depths));'total'];
      end
      
      
      function bosf = filter_session_by_eye_tracking(bosf, need_eye_tracking)
         % filter_session_by_eye_tracking - METHOD Eliminates sessions in filtered_session_table that don't have eye tracking, if eye tracking is desired
         
         if need_eye_tracking
            bosf.filtered_session_table = bosf.filtered_session_table(bosf.filtered_session_table.fail_eye_tracking == false, :);
         end
      end
      
      function bosf = filter_sessions_by_session_id(bosf, session_id)
         % filter_sessions_by_session_id - METHOD Eliminates sessions in filtered_session_table that don't have the session id provided
         
         bosf.filtered_session_table = bosf.filtered_session_table(bosf.filtered_session_table.id == session_id, :);
      end
      
      function bosf = filter_session_by_cre_line(bosf, cre_line)
         % filter_session_by_cre_line - METHOD Eliminates sessions in filtered_session_table that don't have the cre line provided
         
         bosf.filtered_session_table = bosf.filtered_session_table(ismember(bosf.filtered_session_table.cre_line, cre_line),:);
      end
      
      function bosf = filter_sessions_by_container_id(bosf,container_id)
         % filter_sessions_by_container_id - METHOD Eliminates sessions in filtered_session_table thadon't have the container id provided
         
         bosf.filtered_session_table = bosf.filtered_session_table(bosf.filtered_session_table.experiment_container_id == container_id, :);
      end
      
      function bosf = filter_sessions_by_stimuli(bosf,stimulus)
         % filter_sessions_by_stimuli - METHOD Eliminates sessions in filtered_session_table that don't have the stimulus type provided
         
         session_by_stimuli = bosf.get_session_by_stimuli();
         % filter sessions by stimuli
         bosf.filtered_session_table =  bosf.filtered_session_table(ismember(bosf.filtered_session_table.stimulus_name,...
            bosf.find_session_for_stimuli(stimulus,session_by_stimuli)), :);
      end
      
      function bosf = filter_sessions_by_imaging_depth(bosf,depth)
         % filter_sessions_by_imaging_depth - METHOD Eliminates sessions in filtered_session_table that don't have the cortical depth provided
         
         % filter sessions by imaging_depth
         bosf.filtered_session_table = bosf.filtered_session_table(bosf.filtered_session_table.imaging_depth == depth, :);
      end
      
      function acronym = get_targeted_structure_acronyms(bosf)
         if size(bosf.filtered_session_table,1) > 1
            exp_targeted_structure_session_table = struct2table(bosf.filtered_session_table.targeted_structure);
            acronym = categorical(exp_targeted_structure_session_table.acronym);
            
         elseif size(bosf.filtered_session_table,1) == 1
            acronym = categorical(cellstr(bosf.filtered_session_table.targeted_structure.acronym));
         end
         
      end
      
      function bosf = filter_sessions_by_targeted_structure(bosf, structure)
         % filter_sessions_by_targeted_structure - METHOD Eliminates sessions in filtered_session_table that don't have the brain area provided
         
         % filter sessions by targeted_structure
         acronyms = get_targeted_structure_acronyms(bosf);
         vbMatchAcronym = ismember(acronyms, structure);
         bosf.filtered_session_table = bosf.filtered_session_table(vbMatchAcronym, :);
      end
      
      function bosf = filter_sessions_by_session_type(bosf,session_type)
         % filter_sessions_by_session_type - METHOD Eliminates sessions in filtered_session_table that don't have the session type provided
         
         bosf.filtered_session_table = bosf.filtered_session_table(strcmp(bosf.filtered_session_table.stimulus_name,session_type),:);
      end
      
      %% -- Method to return session objects for filtered sessions
      
      function vbsSessions = get_filtered_sessions(bosf)
         % get_filtered_sessions - METHOD Return session objects for the filtered experimental sessions
         %
         % Usage: vbsSessions = get_filtered_sessions(bosf)
         
         % - Get the current table of filtered sessions, construct objects
         vbsSessions = bot.getSessions(bosf.filtered_session_table.id);
      end
      
      %% -- Getter methods for dependent filtered sessions properties
      
      function result = get.filtered_session_table(bosf)
         % get.filtered_session_table - GETTER METHOD Access `filtered_session_table` property
         
         % - Reset filtered sessions table, if necessary
         if ~istable(bosf.filtered_session_table) && isnan(bosf.filtered_session_table)
            bosf.clear_filters();
         end
         
         % - Check for an empty table
         if isempty(bosf.filtered_session_table)
            error('BOT:NoSessionsRemain', 'No sessions remain after filtering.');
         else
            result = bosf.filtered_session_table;
         end
      end
      
      function stimulus = get.stimulus(bosf)
         % get.stimulus - GETTER METHOD Access `stimulus` property
         stimulus = bosf.get_all_stimuli();
      end
      
      function session_type = get.session_type(bosf)
         % get.session_type - GETTER METHOD Access `session_type` property
         session_type = categories(categorical(bosf.filtered_session_table{:, 'stimulus_name'}));
      end
      
      function targeted_structure = get.targeted_structure(bosf)
         % get.targeted_structure - GETTER METHOD Access `targeted_structure` property
         targeted_structure = categories(bosf.get_targeted_structure_acronyms());
      end
      
      function imaging_depth = get.imaging_depth(bosf)
         % get.imaging_depth - GETTER METHOD Access `imaging_depth` property
         imaging_depth = unique(bosf.filtered_session_table.imaging_depth);
      end
      
      function container_id = get.container_id(bosf)
         % get.container_id - GETTER METHOD Access `container_id` property
         container_id = unique(bosf.filtered_session_table.experiment_container_id);
      end
      
      function session_id = get.session_id(bosf)
         % get.session_id - GETTER METHOD Access `session_id` property
         session_id = bosf.filtered_session_table.id;
      end
      
      function cre_line = get.cre_line(bosf)
         % get.cre_line - GETTER METHOD Access `cre_line` property
         cre_line = categories(categorical(bosf.filtered_session_table.cre_line));
      end
      
      function eye_tracking_avail = get.eye_tracking_avail(bosf)
         % get.eye_tracking_avail - GETTER METHOD Access `eye_tracking_avail` property
         eye_tracking_avail = ~unique(bosf.filtered_session_table.fail_eye_tracking);
      end
   end
   
   %% Private static methods
   methods (Access = private, Static = true)
      function filtered_session = find_session_for_stimuli(stimulus, session_by_stimuli)
         filtered_session = {};
         fields = fieldnames(session_by_stimuli);
         for i = 1 :length(fields)
            if sum(ismember(session_by_stimuli.(char(fields(i))),stimulus)) >= 1
               filtered_session(end+1) = cellstr(fields(i)); %#ok<AGROW>
            end
         end
      end
      
      function session_by_stimuli = get_session_by_stimuli()
         session_by_stimuli.three_session_A = {'drifting_gratings','natural_movie_one','natural_movie_three','spontaneous'};
         session_by_stimuli.three_session_B = {'static_gratings','natural_scenes','natural_movie_one','spontaneous'};
         session_by_stimuli.three_session_C = {'locally_sparse_noise_4deg','natural_movie_one','natural_movie_two','spontaneous'};
         session_by_stimuli.three_session_C2 = {'locally_sparse_noise_4deg','locally_sparse_noise_8deg', ...
            'natural_movie_one','natural_movie_two','spontaneous'};
      end
   end
end