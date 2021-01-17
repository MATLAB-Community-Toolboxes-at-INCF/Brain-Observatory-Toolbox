% fetchProbes - FUNCTION Return the manifest table of probes
%
% Usage: probes = fetchProbes()
%
% `probes` will be the manifest table of EPhys probes.

function probes = fetchProbes(~)
   probes = bot.internal.manifest('ephys').ephys_probes;
end