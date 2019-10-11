function [bExecute, bError] = call_once_per_session(strKey, fhFunction)

% call_once_per_session - FUNCTION Execute a function only once per matlab session
%
% Usage: [bExecute, bError] = call_once_per_session(strKey, fhFunction)
%
% `strKey` must be a reasonable string for use as a matlab variable name.
% `fhFunction` is a function handle, which will be executed only once per
% matlab session. `call_once_per_session` relies on the global UserData
% structure, and so can be reset if UserData is wiped.
%
% `bExecute` will be a boolean, indicating whether or not `fhFunction` was
% executed. `bError` will be a boolean, indicated that an error occurred
% during the execution of `fhFunction`.

% - Check arguments

if nargin < 2
   help bot.internal.call_once_per_session;
   error('BOT:Usage', 'Incorrect usage.');
end

% - Get the user data
sUD = get(0, 'UserData');

% - Does the key exist in the global user data?
bError = false;
bExecute = ~(isfield(sUD, strKey) && isequal(sUD.(strKey), strKey));
if bExecute
   % - No, so we should execute the function

   % - Insert the key into user data, so we don't call the function again
   sUD.(strKey) = strKey;
   set(0, 'UserData', sUD);

   try
      % - Call the function handle
      fhFunction();
   catch
      % - The function call failed
      bError = true;
   end   
end