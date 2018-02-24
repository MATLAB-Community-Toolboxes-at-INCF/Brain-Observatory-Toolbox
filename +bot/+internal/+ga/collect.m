function collect(strTrackingID, strHitType, ...
   strUserID, strClientUUID, ...
   strDocURL, strDocHost, strDocPath, strDocTitle, ...
   strScreenName, ...
   strEventCategory, strEventAction, strEventLabel, nEventValue, ...
   strAppName, strAppVersion, ...
   strDataSource, strSessionControl, bNonInteractive) %#ok<*INUSL>

% collect - FUNCTION General interface to Google Analytics 'collect' API
%
% Usage: collect(strTrackingID, strHitType, ...
%                < strUserID, strClientUUID >, ...
%                < strDocURL, strDocHost, strDocPath, strDocTitle >, ...
%                < strScreenName >, ...
%                < strEventCategory, strEventAction, strEventLabel, nEventValue >, ...
%                < strAppName, strAppVersion >, ...
%                < strDataSource, strSessionControl, bNonInteractive >)
%
% `strTrackingID` must be a valid Google Analytics tracking ID.
% `strHitType` must be one of 'pageview', 'screenview', 'event'.
% pageview: `strDocURL`, `strDocHost`, `strDocPath`, `strDocTitle` are used
% screenview: `strScreenName` is used
% event: `strEventCategory`, `strEventAction`, `strEventLabel`,
% `nEventValue` are used
%
% Other arguments are optional. See Google Analytics Measurement Protocol
% documentation for details:
% https://developers.google.com/analytics/devguides/collection/protocol/v1/

%% -- Parse input arguments

if nargin < 3
   help bot.internal.ga.collect;
   error('ga:collect:Usage', 'Incorrect usage.');
end

% - Check session control arguments
if exist('strSessionControl', 'var') && ~isempty(strSessionControl)
   strSessionControl = lower(strSessionControl);
   
   switch strSessionControl
      case {'start', 'end'}
         
      otherwise
         error('ga:collect:Arguments', ...
               '''strSessionControl'' must be one of {''start'', ''end''}.');
   end
end

% - Set up required request parameters
sReq.v = 1;
sReq.ds = 'matlab';
sReq.tid = strTrackingID;

% - Include session control
AppendReq('strSessionControl', 'sc');

% - Include data source
AppendReq('strDataSource', 'ds');


%% -- Check client identifier
NeedAtLeastOne('strUserID', 'strClientUUID');

% - Include client identifier in request
AppendReq('strUserID', 'uid');
AppendReq('strClientUUID', 'cid');


%% -- Check hit type

strHitType = lower(strHitType);

switch strHitType
   case 'pageview'
      NeedAtLeastOne('strDocURL', 'strDocHost');
      AppendReq('strDocURL', 'dl');
      AppendReq('strDocHost', 'dh');
      AppendReq('strDocPath', 'dp');
      AppendReq('strDocTitle', 'dt');
      
   case 'screenview'
      NeedAll('strScreenName');
      AppendReq('strScreenName', 'cd');
     
   case 'event'
      NeedAll('strEventCategory', 'strEventAction');
      AppendReq('strEventCategory', 'ec');
      AppendReq('strEventAction', 'ea');
      AppendReq('strEventLabel', 'el');
      AppendReq('nEventValue', 'ev', @(o)isnumeric(o) && (o>0) && (floor(o) == o));
      
   case 'transaction'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strTransID'); %#ok<*UNRCH>
      
   case 'item'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strTransID', 'strItemName');
      
   case 'social'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strSocialNetwork', 'strSocialAction', 'strSocialActionTarget');
      
   case 'exception'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      
   case 'timing'
      error('GACollect:UnsupportedHitType', ...
            'The hit type ''%s'' is unsupported.', strHitType);
      NeedAll('strUserTimingCat', 'strUserTimingVar', 'nUserTimingTime');
      
   otherwise
      error('GACollect:Arguments', ...
         '''strHitType'' must be one of {''pageview'', ''screenview'', ''event'', ''transaction'', ''item'', ''social'', ''exception'', ''timing''}.');
end

% - Set hit type
sReq.t = strHitType;

%% -- Check bNonInteractive

if exist('bNonInteractive', 'var')
   bNonInteractive = double(logical(bNonInteractive)); %#ok<NASGU>
end
AppendReq('bNonInteractive', 'ni');

%% -- Application information fields

AppendReq('strAppName', 'an');
AppendReq('strAppVersion', 'av');

%% -- Send request

strURL = 'https://www.google-analytics.com/collect';
weboptions('RequestMethod','post');

cRequest = [fieldnames(sReq) struct2cell(sReq)]';
webwrite(strURL, cRequest{:});

%% --- END of collect FUNCTION ---

   function AppendReq(strVarName, strReqFieldName, fhValidate, oDefaultValue)
      % AppendReq - FUNCTION Append a field to the request, if the field exists in the function arguments
      %
      % Usage: AppendReq(strVarName, strReqFieldName <, fhValidate, oDefaultValue>)
      %
      % `strVarName` is a string containing an argument name. The existence
      % of this argument will be checked, and if it is not empty, a new
      % field in the GA request will be set. The request field will be
      % named by the contents of `strReqFieldName`.
      %
      % `fhValidate` is an optional function handle that is called with the
      % data in the argument. If this function handle returns false, then
      % an assertion is raised.
      %
      % The optional argument `oDefaultValue` can be used to force a
      % default request field vaule.
      
      % - Was the named argument provided to ga.collect?
      if exist(strVarName, 'var') && ~isempty(eval(strVarName))
         % - Should we call the validation function?
         if exist('fhValidate', 'var') && ~isempty(fhValidate)
            % - The validation failed, so raise an error
            assert(fhValidate(eval(strVarName)), ...
                   'ga:collect:Arguments', ...
                   'Incorrect value for ''%s''.', strVarName);
         end
         
         % - Add the named field to the request, with the provided argument data
         sReq.(strReqFieldName) = eval(strVarName);
      
      elseif exist('oDefaultValue', 'var') && ~isempty(oDefaultValue)
         % - Set a default value
         sReq.(strReqFieldName) = oDefaultValue;
      end
   end

   function NeedAll(varargin)
      % NeedAll - FUNCTION Check that all named arguments were provided
      %
      % Usage: NeedAll(strArgName1, strArgName2, ...)
      %
      % If all of the named arguments in strArgNameN are provided, the
      % function will exit silently. Otherwise an error will be thrown.
      
      % - Get a structure containing the current workspace
      sWS = who();
      
      % - Check that the named arguments exist in the workspace
      vbArgExists = cellfun(@(s)ismember(s, sWS) && ~isempty(evalin('caller', s)), varargin);
      
      if ~all(vbArgExists)
         % - Raise an error if any of the arguments does not exist
         error('ga:collect:Arguments', ...
               'All of {%s} are required.', ...
               sprintf('%s, ', varargin{:}));
      end
   end

   function NeedAtLeastOne(varargin)
      % NeedAtLeastOne - FUNCTION Check that at least one of the named arguments was provided
      %
      % Usage: NeedAtLeastOne(strArgName1, strArgName2, ...)
      
      % - Get a structure containing the current workspace      
      sWS = who();

      % - Check that the named arguments exist in the workspace
      vbArgExists = cellfun(@(s)ismember(s, sWS) && ~isempty(evalin('caller', s)), varargin);
      
      if ~any(vbArgExists)
         % - Raise an error if none of the arguments exist
         error('ga:collect:Arguments', ...
               'At least one of {%s} is required.', ...
               sprintf('%s, ', varargin{:}));
      end
   end

end


