% fetchUnits - FUNCTION Return the table of recorded unts
%
% Usage: units = fetchUnits()
%
% `units` will be the manifest table of EPhys units.

function units = fetchUnits(~)
   tbl = bot.internal.manifest('ephys').ephys_units;
   units = bot.internal.manifest2item(tbl);   
end