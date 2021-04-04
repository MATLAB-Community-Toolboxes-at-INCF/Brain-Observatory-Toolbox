% fetchUnits - FUNCTION Return the table of recorded unts
%
% Usage: units = fetchUnits()
%
% `units` will be the manifest table of EPhys units.

function units = fetchUnits(~)
   manifest = bot.internal.manifest.instance('ephys');
   units = manifest.ephys_units;
end