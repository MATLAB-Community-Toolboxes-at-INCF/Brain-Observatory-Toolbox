% Obtain object array representing identified session item(s) from an Allen Brain Observatory dataset
% 
% Can return experiment sessions from either of the Allen Brain Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophyssession")
%   * Visual Coding Neuropixels [3] ("ephyssession") 
%
% Can specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.fetchSessions(...) 
%   * tables contained by other item objects (channels, probes, units, experiments)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.fetchSessions. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations. 
%   
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% 
%% function sessionObj = session(sessionSpec) 
function sessionObj = session(sessionIDSpec)

arguments
    sessionIDSpec {bot.item.internal.mustBeItemIDSpec}
end

% - Is we were given a table, extract the IDs
sessionType = categorical();
if istable(sessionIDSpec)
    if ~ismember(sessionIDSpec.Properties.VariableNames, 'id')
        error('BOT:InvalidSessionTable', ...
            'The provided table does not describe an experimental session.');
    end    
    
   sessionIDs = sessionIDSpec.id;
   sessionType = sessionIDSpec.Properties.UserData.type;
elseif isnumeric(sessionIDSpec) && isvector(sessionIDSpec)
    sessionIDs = sessionIDSpec;
else
    error("Must specify session object(s) to create with either a numeric vector or table");
end

% - Were we given an array of session IDs?
if numel(sessionIDs) > 1
   % - Loop over session IDs and build session objects
   for nIndex = numel(sessionIDs):-1:1
      nThisSessionID = sessionIDs(nIndex);
      sessionObj(nIndex) = bot.session(nThisSessionID);
   end
   return;
end

% Access manifest singleton tables & extract matching rows
if isequal(sessionType,"OPhys")
    ophys_manifest = bot.internal.manifest.instance('ophys');
    rowIdxs = ophys_manifest.ophys_sessions.id == sessionIDs;
elseif isequal(sessionType,"Ephys")
    ephys_manifest = bot.internal.manifest.instance('ephys');
    rowIdxs = ephys_manifest.ephys_sessions.id == sessionIDs;
else
    ophys_manifest = bot.internal.manifest.instance('ophys');
    ephys_manifest = bot.internal.manifest.instance('ephys');
    
    rowIdxs = ophys_manifest.ophys_sessions.id == sessionIDs;
    if isempty(rowIdxs)
        sessionType = categorical("Ophys");
    else
        sessionType = categorical("Ephys");
        rowIdxs = ephys_manifest.ephys_sessions.id == sessionIDs;
    end    
end  

if isempty(rowIdxs)
  error('BOT:InvalidSessionID', ...
               'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
               sessionIDs);
end

switch sessionType
    case "OPhys"
        manifest_rows = ophys_manifest.ophys_sessions(rowIdxs,:);
        sessionObj = bot.item.ophyssession(manifest_rows);
    case "Ephys"
        manifest_rows = ephys_manifest.ephys_sessions(rowIdxs,:);
        sessionObj = bot.item.ephyssession(manifest_rows);
    otherwise
        assert(false);
end
