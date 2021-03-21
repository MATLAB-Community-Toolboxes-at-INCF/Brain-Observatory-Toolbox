% fetchUnits - FUNCTION Return the table of recorded unts
%
% Usage: units = fetchUnits()
%
% `units` will be the manifest table of EPhys units.

function units = fetchUnits(~)
   manifest = bot.internal.manifest('ephys').ephys_units;
   units = bot.internal.refineManifest(manifest);   
end