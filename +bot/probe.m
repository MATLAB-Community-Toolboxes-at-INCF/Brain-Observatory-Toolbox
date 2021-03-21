% probe — Return a probe object from the Allen Brain Observatory EPhys data set
%
% Usage: new_probe = probe(probe_id)
%
% `probe_id` is a probe ID from the Allen Brain Observatory EPhys data set.
% A lightweight probe ojbect `new_probe` is returned, containing
% metadata about the experiment probe data.

function new_probe = probe(probe_id)

% - Get a bot ephys manifest
ephys_manifest = bot.internal.manifest('ephys');

% - Return the probe object
new_probe = bot.item.ephysprobe(probe_id, ephys_manifest);
