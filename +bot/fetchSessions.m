% Retrieve table of experiment sessions information for an Allen Brain Observatory dataset 
% 
% Can return experiment sessions from either of the Allen Brain Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophys")
%   * Visual Coding Neuropixels [3] ("ephys") 
%
% Web data accessed via the Allen Brain Atlas API [4]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% [4] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: https://brain-map.org/api/index.html
%
%% function sessionsTable = fetchSessions(dataset)
function sessionsTable = fetchSessions(dataset)

arguments
    dataset (1,1) string {mustBeMember(dataset,["ephys" "ophys" "Ephys" "Ophys", "EPhys", "OPhys"])}    
end
   
   switch lower(dataset)
      case 'ephys'
         manifest = bot.item.internal.Manifest.instance('ephys');
         sessionsTable = manifest.ephys_sessions;
         
      case 'ophys'
         manifest = bot.item.internal.Manifest.instance('ophys');
         sessionsTable = manifest.ophys_sessions;
   end

end


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
%                   cached_files = sess.bot_cache.ccCache.pwebsave(local_files, [urls{:}], true);
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