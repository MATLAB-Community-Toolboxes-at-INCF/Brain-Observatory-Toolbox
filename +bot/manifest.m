%% FUNCTION manifest

function new_manifest = manifest(manifest_type)
switch(lower(manifest_type))
   case 'ophys'
      new_manifest = bot.ophysmanifest();
      
   case 'ephys'
      new_manifest = bot.ephysmanifest();
      
   otherwise
      error('`manifest_type` must be one of {''ophys'', ''ephys''}');
end
