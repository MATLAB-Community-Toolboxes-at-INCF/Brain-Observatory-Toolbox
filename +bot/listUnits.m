% Retrieve table of ephys unit information for an Allen Brain Observatory dataset
%
% Supports the Visual Coding Neuropixels [1] dataset and the Visual 
% Behavior Neuropixels [2] dataset from the Allen Brain Observatory [3].
%
% Usage:
%    units = bot.listUnits() returns a table of unit information for the
%       Visual Coding dataset
%
%    units = bot.listUnits(datasetName) returns a table of unit information for 
%       the specified dataset. datasetName can be "VisualCoding" or
%       "VisualBehavior" (Default = "VisualCoding")
%
%    units = bot.listUnits(datasetName, include_metrics) additionally specifies
%       whether to include unit metrics or not (Default = false).
%
% Web data accessed via the Allen Brain Atlas API [4]. 
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. 
%       Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
%
% [2] Copyright 2023 Allen Institute for Brain Science. Visual Behavior Neuropixels dataset. 
%       Available from: https://portal.brain-map.org/circuits-behavior/visual-behavior-neuropixels
%
% [3] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: https://portal.brain-map.org/explore/circuits
%
% [4] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. 
%       Available from: https://brain-map.org/api/index.html

function unitsTable = listUnits(datasetName, includeMetrics)

    arguments 
        datasetName (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
        includeMetrics logical = false;
    end
    
    % Get the metadata manifest for the selected dataset
    manifest = bot.item.internal.Manifest.instance('Ephys', datasetName);

    % Get the units item table
    if datasetName == "VisualCoding"
        unitsTable = manifest.ephys_units;
    else
        unitsTable = manifest.Units;
    end

    % - Trim metrics from table
    if ~includeMetrics
        metricProperties = bot.item.Unit.METRIC_PROPERTIES;
        presentMetricProperties = intersect(metricProperties, unitsTable.Properties.VariableNames);
        unitsTable = removevars(unitsTable, presentMetricProperties);
    end
end
