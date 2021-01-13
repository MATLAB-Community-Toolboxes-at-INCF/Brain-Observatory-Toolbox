% unit — Return a unit object from the Allen Brain Observatory EPhys data set
%
% Usage: new_unit = unit(unit_id)
%
% `unit_id` is a unit ID from the Allen Brain Observatory EPhys data
% set.  A lightweight unit ojbect `new_unit` is returned, containing
% metadata about the data recorded from the corresponding unit in the
% experiment.

function new_unit = unit(unit_id)

% - Get a bot ephys manifest
ephys_manifest = bot.internal.manifest('ephys');

% - Return the unit object
new_unit = bot.internal.ephysunit(unit_id, ephys_manifest);
