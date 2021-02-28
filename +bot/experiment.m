% experiment — Return a experiment object from the Allen Brain Observatory EPhys data set
%
% Usage: new_experiment = experiment(experiment_id)
%
% `experiment_id` is a experiment ID from the Allen Brain Observatory EPhys
% data set. A lightweight experiment ojbect `new_experiment` is returned,
% containing metadata about the experiment.

function new_experiment = experiment(experiment_id)

% - Return the experiment object
new_experiment = bot.internal.items.experiment(experiment_id);
