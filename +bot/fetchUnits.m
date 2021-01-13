% fetchUnits - FUNCTION Return the table of recorded unts
%
% Usage: units = fetchUnits()
%
% `units` will be the manifest table of EPhys units.

function units = fetchUnits(~)
   units = bot.internal.manifest('ephys').ephys_units;
end