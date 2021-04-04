% fetchProbes - FUNCTION Return the manifest table of probes
%
% Usage: probes = fetchProbes()
%
% `probes` will be the manifest table of EPhys probes.

function probes = fetchProbes(~)
   manifest = bot.internal.manifest.instance('ephys');
   probes = manifest.ephys_probes;
end