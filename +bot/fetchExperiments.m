% fetchExperiments - FUNCTION Return the table of experiment containers
%
% Usage: experiments = fetchExperiments()
%
% `experiments` will be the manifest table of OPhys experiment containers.

function experiments = fetchExperiments(~)
   experiments = bot.internal.manifest('ophys').ophys_containers;
end