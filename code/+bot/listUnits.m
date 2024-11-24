% Retrieve table of ephys unit information for an Allen Brain Observatory [1] dataset
%
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory.
%
% Usage:
%    units = bot.listUnits() returns a table of unit information for the
%       Visual Coding dataset
%
%    units = bot.listUnits(datasetName) returns a table of unit information 
%       for the dataset specified by datasetName. datasetName can be 
%       "VisualCoding" (default) or "VisualBehavior".
%
%    units = bot.listUnits(datasetName, include_metrics) additionally 
%       specifies whether to include unit metrics or not (Default = false).
%
% Web data accessed via the Allen Brain Atlas API [6] or AWS Public 
% Datasets (Amazon S3). 
%
% For references [#]:
%   See also bot.util.showReferences

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
