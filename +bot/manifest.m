% manifest — Create or download a manifest from the Allen Brain Observatory
%
% Usage: manifest(manifest_type)
%
% `manifest_type` must be one of {'ophys', 'ephys'}. The corresponding
% manifest will be downloaded from the Allen Brain Observatory, and
% returned as a manifest class (either `bot.internal.ophysmanifest` or
% `bot.internal.ephysmanifest`).

function new_manifest = manifest(manifest_type)
switch(lower(manifest_type))
   case 'ophys'
      new_manifest = bot.internal.ophysmanifest();
      
   case 'ephys'
      new_manifest = bot.internal.ephysmanifest();
      
   otherwise
      error('`manifest_type` must be one of {''ophys'', ''ephys''}');
end
