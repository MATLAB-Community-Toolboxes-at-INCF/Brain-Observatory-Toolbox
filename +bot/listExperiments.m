% Retrieve table of ophys experiment information from an Allen Brain Observatory [1] dataset
%
% Supports the Visual Coding 2P [2] dataset and the Visual Behavior 2P [4] 
% dataset from the Allen Brain Observatory [1].
%
% Usage:
%    experiments = bot.listExperiments() returns a table of experiment 
%       information for the Visual Coding dataset
%
%    experiments = bot.listExperiments(datasetName) returns a table of 
%       experiment information for the dataset specified by datasetName. 
%       datasetName can be "VisualCoding" (default) or "VisualBehavior".
%
% Note:
%   Experiments are defined differently in the Visual Coding 2P
%   dataset and The Visual Behavior Dataset.
%     See <a href="matlab:help('bot.item.Experiment',
%     '-displayBanner')">bot.item.Experiment</a> & <a
%     href="matlab:help('bot.behavior.item.Experiment',
%     '-displayBanner')">bot.behavior.item.Experiment</a> for details
%
% Web data accessed via the Allen Brain Atlas API [6] or AWS Public 
% Datasets (Amazon S3). 
%
% For references [#]:
%   See also bot.util.showReferences

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
