% unit — Return a unit object from the Allen Brain Observatory EPhys data set
%
% Usage: new_unit = unit(unit_id)
%
% `unit_id` is a unit ID from the Allen Brain Observatory EPhys data
% set.  A lightweight unit ojbect `new_unit` is returned, containing
% metadata about the data recorded from the corresponding unit in the
% experiment.

function new_unit = unit(unit_id)
new_unit = bot.item.ephysunit(unit_id);
