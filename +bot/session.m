% session - Create a lightweight session obbject, representing a session from the manifest
%
% Usage: new_sess = session(session_id)
%        session_vector = session(vector_session_ids)
%        new_sess = session(manifest_table_row)
%
% `session_id` must be an integer ID representing an experiment session
% from the Allen Brain Observatory, from either the EPhys or OPhys data
% sets. If several session IDs are provided as a vector of IDs, then
% multiple session objects will be returnef.
%
% Alternatively, a table row from a session manifest can be provided, and
% the corresponding session object will be returned.
%
% This function returns lightweight `bot.item.ophyssession` and
% `bot.item.ephyssession` objects, containing only metadata about an
% experimental session. No data will be downloaded unless the object is
% inspected.

function new_sess = session(sessionsSpec)

% - Is we were given a table, extract the IDs
sessionType = categorical();
if istable(sessionsSpec)
    if ~ismember(sessionsSpec.Properties.VariableNames, 'id')
        error('BOT:InvalidSessionTable', ...
            'The provided table does not describe an experimental session.');
    end    
    
   sessionIDs = sessionsSpec.id;
   sessionType = sessionsSpec{1,"type"};
elseif isnumeric(sessionsSpec) && isvector(sessionsSpec)
    sessionIDs = sessionsSpec;
else
    error("Must specify session object(s) to create as either a table or numeric vector");
end

% - Were we given an array of session IDs?
if numel(sessionIDs) > 1
   % - Loop over session IDs and build session objects
   for nIndex = numel(sessionIDs):-1:1
      nThisSessionID = sessionIDs(nIndex);
      new_sess(nIndex) = bot.session(nThisSessionID);
   end
   return;
end

% Access manifest singleton tables & extract matching rows
if isequal(sessionType,"OPhys")
    ophys_manifest = bot.internal.manifest('ophys');
    rowIdxs = ophys_manifest.ophys_sessions.id == sessionIDs;
elseif isequal(sessionType,"Ephys")
    ephys_manifest = bot.internal.manifest('ephys');
    rowIdxs = ephys_manifest.ephys_sessions.id == sessionIDs;
else
    ophys_manifest = bot.internal.manifest('ophys');
    ephys_manifest = bot.internal.manifest('ephys');
    
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
        new_sess = bot.item.ophyssession(manifest_rows);
    case "Ephys"
        manifest_rows = ephys_manifest.ephys_sessions(rowIdxs,:);
        new_sess = bot.item.ephyssession(manifest_rows);
    otherwise
        assert(false);
end
