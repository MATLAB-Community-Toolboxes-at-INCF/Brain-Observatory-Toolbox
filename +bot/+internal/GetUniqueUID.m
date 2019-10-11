function strUserID = GetUniqueUID()

% GetUniqueUID - FUNCTION Generate and cache a uniquely identifiable ID
%
% Usage: strUserID = bot.internal.GetUniqueUID()
%
% `strUserID` will either be a UUID generated using the JVM, or else a
% random string. This value will be stored between Matlab sessions with the
% BOT cache.

% - Get a handle to the cache object
boc = bot.cache;

% - Determine the file name of the saved uuid
strUUIDMat = fullfile(boc.strCacheDir, 'uuid.mat');

% - See if a UUID already exists
try %#ok<TRYNC>
   load(strUUIDMat, 'strUserID');
   return;
end

% - Try to generate a UUID using java
try
   strUserID = char(java.util.UUID.randomUUID());

catch
   % - Otherwise use a tempname
   [~, strUserID] = fileparts(tempname);   
end

% - Save the user ID
save(strUUIDMat, 'strUserID');

