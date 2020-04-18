function new_sess = session(nSessionID)

if nargin == 0
   new_sess = bot.session_base;
   return;
end

% - Get the table rows for these sessions
tManifestRow = bot.session_base.find_manifest_row(nSessionID);

% - Were we given an array of session IDs?
if size(tManifestRow, 1) > 1
   for nIndex = size(tManifestRow, 1):-1:1
      nSessionID = tManifestRow.id(nIndex);
      new_sess(nIndex) = bot.session(nSessionID);
   end
   return;
end

% - Build a session object from this single ID and return
if tManifestRow.BOT_session_type == "OPhys"
   new_sess = bot.ophyssession(tManifestRow);
else
   new_sess = bot.ephyssession(tManifestRow);
end
