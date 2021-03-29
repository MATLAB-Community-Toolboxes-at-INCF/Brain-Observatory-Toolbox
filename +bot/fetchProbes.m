% fetchProbes - FUNCTION Return the manifest table of probes
%
% Usage: probes = fetchProbes()
%
% `probes` will be the manifest table of EPhys probes.

function probes = fetchProbes(~)
   tbl = bot.internal.manifest('ephys').ephys_probes;
   probes = bot.internal.refineManifest(tbl);

end