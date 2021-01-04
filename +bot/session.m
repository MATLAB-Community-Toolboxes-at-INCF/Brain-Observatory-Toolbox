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
% This function returns lightweight `bot.internal.ophyssession` and
% `bot.internal.ephyssession` objects, containing only metadata about an
% experimental session. No data will be downloaded unless the object is
% inspected.

function new_sess = session(session_id)

if nargin == 0
   new_sess = bot.internal.session_base;
   return;
end

% - Is we were given a table, extract the IDs
if istable(session_id)
   session_id = session_id.id;
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

% - Get the table rows for this session
manifest_table_row = bot.internal.session_base.find_manifest_row(session_id);

% - Build a session object from this single ID and return
if manifest_table_row.BOT_session_type == "OPhys"
   new_sess = bot.internal.ophyssession(manifest_table_row);
else
   new_sess = bot.internal.ephyssession(manifest_table_row);
end
