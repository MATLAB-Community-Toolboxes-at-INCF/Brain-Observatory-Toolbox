% Retrieve table of ophys experiment information from an Allen Brain Observatory dataset
%
% Supports the Visual Coding 2P [1] dataset and the Visual Behavior 2P [2] 
% dataset from the Allen Brain Observatory [3].
%
% Usage:
%    experiments = bot.listExperiments() returns a table of experiment 
%       information for the Visual Coding dataset
%
%    experiments = bot.listExperiments(datasetName) returns a table of 
%       experiment information for the specified dataset. datasetName can 
%       be "VisualCoding" or "VisualBehavior" (Default = "VisualCoding")
%
% Note:
%   Experiments are defined differently in the Visual Coding 2P
%   dataset and The Visual Behavior Dataset.
%
%   See also: bot.item.Experiment bot.behavior.item.Experiment
%
%
% Web data accessed via the Allen Brain Atlas API [4]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. 
%       Available from: https://portal.brain-map.org/circuits-behavior/visual-coding-2p
%
% [2] Copyright 2023 Allen Institute for Brain Science. Visual Behavior 2P dataset. 
%       Available from: https://portal.brain-map.org/circuits-behavior/visual-behavior-2p
%
% [3] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: https://portal.brain-map.org/explore/circuits
%
% [4] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. 
%       Available from: https://brain-map.org/api/index.html

function experimentsTable = listExperiments(datasetName)
    arguments
        datasetName (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
    end

    % Get the metadata manifest for the selected dataset
    manifest = bot.item.internal.Manifest.instance('Ophys', datasetName);
    
    % Get the cells item table
    if datasetName == "VisualCoding"
        experimentsTable = manifest.ophys_experiments;
    else
        experimentsTable = manifest.OphysExperiments;
    end
end
