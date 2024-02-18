% Retrieve table of experiment sessions information for an Allen Brain Observatory dataset 
% 
% Can return experimental sessions from either of the Allen Brain 
% Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophys")
%   * Visual Coding Neuropixels [3] ("ephys")
%   * Visual Behavior 2P [4] ("ophys")
%   * Visual Behavior Neuropixels [5] ("ephys")
%
% Usage:
%    sessions = bot.listSessions() returns a table of information for 
%       sessions of the Visual Coding Neuropixels (ephys) dataset
%
%    sessions = bot.listSessions(datasetName, datasetType) returns a 
%       sessions table for the specified datasetName and datasetType. 
%       datasetName can be "VisualCoding" or "VisualBehavior" (Default =
%       "VisualCoding") and datasetType can be "Ephys" or "Ophys" 
%       (Default = "Ephys")
%
%    sessions = bot.listSessions(..., Name, Value) returns a session table
%       based on additional options provided as name-value pairs.
%
%       Available options:
%
%         - Id : A list of ids. Will return a table that only includes
%                sessions for the given Ids
%
%         - IncludeBehaviorOnly : Includes behavior-only sessions. Note:
%                Only available for the Visual Behavior dataset
%
% Web data accessed via the Allen Brain Atlas API [6]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/circuits-behavior/visual-coding-2p
% [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/circuits-behavior/visual-coding-neuropixels
% [4] Copyright 2023 Allen Institute for Brain Science. Visual Behavior 2P dataset. Available from: https://portal.brain-map.org/circuits-behavior/visual-behavior-2p
% [5] Copyright 2023 Allen Institute for Brain Science. Visual Behavior Neuropixels dataset. Available from: https://portal.brain-map.org/circuits-behavior/visual-behavior-neuropixels
% [6] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: https://brain-map.org/api/index.html
%
%% sessionsTable = bot.listSessions(dataset, datasetType)
function sessionsTable = listSessions(dataset, datasetType, options)

    arguments
        dataset (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
        datasetType (1,1) bot.item.internal.enum.DatasetType = "Ephys"
        options.Id (1,:) = [];
        options.IncludeBehaviorOnly = false
    end

    import bot.item.internal.enum.Dataset

    % Note: This function can support returning sessions from multiple
    % datasets, but this functionality is currently not enabled
   
    datasetNames = [dataset.Name];
    datasetType = string(datasetType);

    if options.IncludeBehaviorOnly
        assert(datasetNames == Dataset.VisualBehavior, ...
            'Behavior only sessions are only present for the Visual Behavior dataset')
    end

    % Initialize a cell array for unmerged tables (i.e tables from 
    % different datasets)
    unmergedTables = cell(1, numel(datasetNames));

    % Gather tables from requested datasets
    for i = 1:numel(datasetNames)
        if options.IncludeBehaviorOnly
            tableName = 'BehaviorSessions';
        else
            tableName = datasetType+"Sessions";
        end
        
        manifest = bot.item.internal.Manifest.instance(datasetType, datasetNames(i));
        unmergedTables{i} = manifest.(tableName); % E.g manifest.EphysSessions
        if ~isempty(options.Id)
            unmergedTables{i} = unmergedTables{i}(ismember(unmergedTables{i}.id, options.Id),:);
        end
        unmergedTables{i}.dataset_name = repmat(datasetNames(i), height( unmergedTables{i} ), 1);
    end
    
    % Return if there is only one dataset table
    if numel(unmergedTables) == 1
        sessionsTable = unmergedTables{1}; return
    end

    % Find common set of table variable names for merging
    tableVariableNames = cellfun(@(t) t.Properties.VariableNames, unmergedTables, 'uni', 0);

    % Handle special case (ophys (VC) and ophys (VB)):
    if any( strcmp( [tableVariableNames{:}], 'targeted_structure_acronym') )
        unmergedTables = scalarColumnToCell(unmergedTables, 'targeted_structure_acronym');
    end
    tableVariableNames = cellfun(@(t) t.Properties.VariableNames, unmergedTables, 'uni', 0);

    finalVariableNames = intersect(tableVariableNames{1}, tableVariableNames{2}, 'stable');
    for i = 2:numel(unmergedTables)
        finalVariableNames = intersect(finalVariableNames, tableVariableNames{i}, 'stable');
    end

    % Keep only the common set of variables for each table
    for i = 1:numel(unmergedTables)
        unmergedTables{i} = unmergedTables{i}(:, finalVariableNames);
    end

    % Merge tables and return
    sessionsTable = cat(1, unmergedTables{:});


   % % switch string(datasetType)
   % %    case "Ephys"
   % %       manifest = bot.item.internal.Manifest.instance('ephys');
   % %       sessionsTable = manifest.ephys_sessions;
   % % 
   % %    case "Ophys"
   % %       manifest = bot.item.internal.Manifest.instance('ophys');
   % %       sessionsTable = manifest.ophys_sessions;
   % % end

end

function unmergedTables = scalarColumnToCell(unmergedTables, name)
    
    for i = 1:numel(unmergedTables)
        tableVariableNames = unmergedTables{i}.Properties.VariableNames;
        if any( strcmp( tableVariableNames, name) )
            data = unmergedTables{i}.(name);
            data = num2cell(data);
            unmergedTables{i} = removevars(unmergedTables{i}, name);
            unmergedTables{i}.([name, 's']) = data; % Make column name plural
        end
    end
end

% Notes: 
% For the Visual Coding ophys manifest, targeted structure acronym is
% always a scalar, as imaging was done in one plane. For the Visual
% Behavior dataset, imaging was done in multiple planes. In the VC ophys
% table, the variable for this data is called "targeted_structure_acronym",
% while for the VB datasets it is called "targeted_structure_acronyms" 
% (plural) and the data is wrapped in cell arrays. When merging these
% tables the scalar column is made into cell and renamed to plural name


% Retained code previously in Session class which previously implemented
% parallelization for array session object construction. This could be
% reimplemented here in the factory function.

%  function cached_files = CacheFilesForSessionIDs(sess, ids, use_parallel, num_tries)
%          % CacheFilesForSessionIDs - METHOD Download data files containing experimental data for the given session IDs
%          %
%          % Usage: cached_files = CacheFilesForSessionIDs(sess, ids <, use_parallel, num_tries>)
%          %
%          % `ids` is a list of session IDs obtained from either the OPhys or
%          % EPhys sessions table. The data files for these sessions will be
%          % downloaded and cached, if they have not already been cached.
%          %
%          % The optional argument `use_parallel` allows you to specify
%          % whether a pool of workers should be used to download several
%          % data files simultaneously. A pool will *not* be created if one
%          % does not already exist. By default, a pool will be used.
%          %
%          % The optional argument `num_tries` allows you to specify how many
%          % attempts should be made to download each file befire giving up.
%          % Default: 3
%
%          % - Default arguments
%          if ~exist('use_parallel', 'var') || isempty(use_parallel)
%             use_parallel = true;
%          end
%
%          if ~exist('num_tries', 'var') || isempty(num_tries)
%             num_tries = 3;
%          end
%
%          % - Loop over session IDs
%          for session_index = numel(ids):-1:1
%             % - Find this session in the sessions tables
%             matching_ophys_session = sess.ophys_manifest.ophys_sessions.id == ids(session_index);
%
%             if any(matching_ophys_session)
%                session_row = sess.ophys_manifest.ophys_sessions(matching_ophys_session, :);
%             else
%                matching_ephys_session = sess.ephys_manifest.ephys_sessions.id == ids(session_index);
%                session_row = sess.ephys_manifest.ephys_sessions(matching_ephys_session, :);
%             end
%
%             % - Check to see if the session exists
%             if isempty(session_row)
%                error('BOT:InvalidSessionID', ...
%                   'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
%                   ids(session_index));
%
%             else
%                % - Cache the corresponding session data files
%                if iscell(session_row.well_known_files)
%                   vs_well_known_files = session_row.well_known_files{1};
%                else
%                   vs_well_known_files = session_row.well_known_files;
%                end
%                urls{session_index} = arrayfun(@(s)strcat(sess.bot_cache.strABOBaseUrl, s.download_link), vs_well_known_files, 'UniformOutput', false);
%                local_files{session_index} = {vs_well_known_files.path}';
%                is_url_in_cache{session_index} = sess.bot_cache.IsURLInCache(urls{session_index});
%             end
%          end
%
%          % - Consolidate all URLs to download
%          urls = [urls{:}];
%          local_files = [local_files{:}];
%          is_url_in_cache = [is_url_in_cache{:}];
%
%          % - Cache all sessions in parallel
%          if numel(ids) > 1 && use_parallel && ~isempty(gcp('nocreate'))
%             if any(~is_url_in_cache)
%                fprintf('Downloading URLs in parallel...\n');
%             end
%
%             success = false;
%             while ~success && (num_tries > 0)
%                try
%                   cached_files = sess.bot_cache.CloudCacher.pwebsave(local_files, [urls{:}], true);
%                   success = true;
%                catch
%                   num_tries = num_tries - 1;
%                end
%             end
%
%          else
%             % - Cache sessions sequentially
%             for url_index = numel(urls):-1:1
%                % - Provide some progress text
%                if ~is_url_in_cache(url_index)
%                   fprintf('Downloading URL: [%s]...\n', urls{url_index});
%                end
%
%                % - Try to cache the data file
%                success = false;
%                while ~success && (num_tries > 0)
%                   try
%                      cached_files{url_index} = sess.bot_cache.CacheFile(urls{url_index}, local_files{url_index});
%                      success = true;
%                   catch cause
%                      num_tries = num_tries - 1;
%                   end
%                end
%
%                % - Raise an error on failure
%                if ~success
%                   base = MException('BOT:CouldNotCacheURL', ...
%                      'A data file could not be cached.');
%                   base = base.addCause(cause);
%                   throw(base);
%                end
%             end
%          end
%       end
%    end