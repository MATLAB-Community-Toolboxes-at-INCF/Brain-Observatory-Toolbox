% Obtain object array representing identified experiment item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding 2P [2] dataset and the Visual Behavior 2P [4] 
% dataset from the Allen Brain Observatory [1].
%
% Note:
%   An experiment is defined differently in the Visual Coding Dataset and
%   the Visual Behavior Dataset. In the Visual Coding Dataset an experiment
%   is a container for a set of (typically) three sessions. In the Visual
%   Behavior dataset, an experiment is defined as a single imaging plane 
%   (FOV) for a session. 
%
% Usage:
%   experimentObj = bot.getExperiments(experimentIDSpec) returns an 
%       experiment item object given a experimentIDSpec. See below for 
%       more details on experimentIDSpec.
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listExperiments() 
%   * tables contained by other item objects (sessions)
%   
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listExperiments. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.
%
% For references [#]:
%   See also bot.util.showReferences

function experimentObj = getExperiments(experimentIDSpec)

    arguments
        experimentIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    end

    if istable(experimentIDSpec)
        datasetName = experimentIDSpec.Properties.CustomProperties.DatasetName;
    else
        datasetName = bot.internal.util.resolveDataset(experimentIDSpec, "Ophys", "Experiment");
    end
    
    % - Return the experiment object
    if datasetName == "VisualCoding"
        experimentObj = bot.item.Experiment(experimentIDSpec);
    else
        experimentObj = bot.behavior.item.Experiment(experimentIDSpec);
    end
end
