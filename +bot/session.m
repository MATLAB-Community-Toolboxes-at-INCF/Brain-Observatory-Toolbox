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
% This function returns lightweight `bot.items.ophyssession` and
% `bot.items.ephyssession` objects, containing only metadata about an
% experimental session. No data will be downloaded unless the object is
% inspected.

function new_sess = session(sessionIdentifier)

assert(~isempty(sessionIdentifier) && (istable(sessionIdentifier) || isnumeric(sessionIdentifier)), "Must specify session object(s) to create as either a table or numeric array");


% - Is we were given a table, extract the IDs
session_type = categorical();
if istable(sessionIdentifier)
    if ~ismember(sessionIdentifier.Properties.VariableNames, 'id')
        error('BOT:InvalidSessionTable', ...
            'The provided table does not describe an experimental session.');
    end    
    
   session_id = sessionIdentifier.id;
   session_type = sessionIdentifier{1,"type"};
end

% - Were we given an array of session IDs?
if numel(session_id) > 1
   % - Loop over session IDs and build session objects
   for nIndex = numel(session_id):-1:1
      nThisSessionID = session_id(nIndex);
      new_sess(nIndex) = bot.session(nThisSessionID);
   end
   return;
end

% Access manifest singleton tables & extract matching rows
if isequal(session_type,"OPhys")
    ophys_manifest = bot.internal.manifest('ophys');
    rowIdxs = ophys_manifest.ophys_sessions.id == session_id;
elseif isequal(session_type,"Ephys")
    ephys_manifest = bot.internal.manifest('ephys');
    rowIdxs = ephys_manifest.ephys_sessions.id == session_id;
else
    ophys_manifest = bot.internal.manifest('ophys');
    ephys_manifest = bot.internal.manifest('ephys');
    
    rowIdxs = ophys_manifest.ophys_sessions.id == session_id;
    if isempty(rowIdxs)
        session_type = categorical("Ophys");
    else
        session_type = categorical("Ephys");
        rowIdxs = ephys_manifest.ephys_sessions.id == session_id;
    end    
end  

if isempty(rowIdxs)
  error('BOT:InvalidSessionID', ...
               'The provided session ID [%d] was not found in the Allen Brain Observatory manifest.', ...
               session_id);
end

switch session_type
    case "OPhys"
        manifest_rows = ophys_manifest.ophys_sessions(rowIdxs,:);
        new_sess = bot.items.ophyssession(manifest_rows);
    case "Ephys"
        manifest_rows = ephys_manifest.ephys_sessions(rowIdxs,:);
        new_sess = bot.items.ephyssession(manifest_rows);
    otherwise
        assert(false);
end
