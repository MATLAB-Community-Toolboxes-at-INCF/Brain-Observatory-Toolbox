% fetchSessions - FUNCTION Return the table of experiment sessions (either OPhys or EPhys)
%
% Usage: sessions = fetchSessions(experiment_type)
%
% `experiment_type` is one of {'ophys', 'ephys'}. `sessions` will be the
% manifest table of OPhys or EPhys sessions.

function sessions = fetchSessions(experiment_type)
   if ~exist('experiment_type', 'var') || isempty(experiment_type)
      error('BOT:Usage', '`experiment_type` must be one of {''ophys'', ''ephys''}');
   end
   
   switch lower(experiment_type)
      case {'ephys', 'e'}
         manifest = bot.internal.manifest('ephys').ephys_sessions;
         
      case {'ophys', 'o'}
         manifest = bot.internal.manifest('ophys').ophys_sessions;
         
      otherwise
         error('BOT:Usage', '`experiment_type` must be one of {''ophys'', ''ephys''}');
   end
   
   % Return a "refined" manifest table (eliminates redundant vars)
   sessions = bot.internal.refineManifest(manifest);
end