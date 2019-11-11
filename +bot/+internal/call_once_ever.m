function [bExecute, bError] = call_once_ever(strCacheDir, strKey, fhFunction)

% call_once_ever - FUNCTION Execute a function only once per installation
%
% Usage: [bExecute, bError] = call_once_ever(strCacheDir, strKey, fhFunction)
%
% `strKey` must be a reasonable string that could be used as a file name.
% `fhFunction` is a function handle, which will be executed only once per
% matlab installation (as long as the source directories for the BOT are
% not wiped).
%
% `bExecute` will be a boolean, indicating whether or not `fhFunction` was
% executed. `bError` will be a boolean, indicated that an error occurred
% during the execution of `fhFunction`.

% - Check arguments
if nargin < 2
   help bot.internal.call_once_ever;
   error('BOT:Usage', 'Incorrect usage.');
end

% - Determine the file name of the saved uuid
strKeyfile = fullfile(strCacheDir, [strKey, '.mat']);

% - Does the file exist?
bError = false;
bExecute = ~exist(strKeyfile, 'file');
if bExecute
   % - No, so we should execute the function

   % - Save the key file, so we don't try again
   save(strKeyfile, 'strKeyfile');

   try
      % - Call the function handle
      fhFunction();
   catch
      % - The function call failed
      bError = true;
   end
end


