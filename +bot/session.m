function new_sess = session(nSessionID)

if nargin == 0
   new_sess = bot.internal.session_base;
   return;
end

% - Is we were given a table, extract the IDs
if istable(nSessionID)
   nSessionID = nSessionID.id;
end

% - Were we given an array of session IDs?
if numel(nSessionID) > 1
   % - Loop over session IDs and build session objects
   for nIndex = numel(nSessionID):-1:1
      nThisSessionID = nSessionID(nIndex);
      new_sess(nIndex) = bot.session(nThisSessionID);
   end
   return;
end

% - Get the table rows for this session
tManifestRow = bot.internal.session_base.find_manifest_row(nSessionID);

% - Build a session object from this single ID and return
if tManifestRow.BOT_session_type == "OPhys"
   new_sess = bot.ophyssession(tManifestRow);
else
   bom = bot.ephysmanifest;
   new_sess = bot.ephyssession(tManifestRow, bom);
end
