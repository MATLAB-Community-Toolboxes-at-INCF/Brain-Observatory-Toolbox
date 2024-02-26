% Retrieve table of ophys cell information from an Allen Brain Observatory [1] dataset
%
% Supports the Visual Coding 2P [2] dataset and the Visual Behavior 2P [4] 
% dataset from the Allen Brain Observatory [1].
%
% Usage:
%    cells = bot.listCells() returns a table of cell information for the
%       Visual Coding dataset
%
%    cells = bot.listCells(datasetName) returns a table of cell information 
%       for the dataset specified by datasetName. datasetName can be 
%       "VisualCoding" (default) or "VisualBehavior".
%
%    cells = bot.listCells(datasetName, include_metrics) additionally 
%       specifies whether to include cell metrics or not (Default = false).
%       Note: The cell table from the Visual Behavior Dataset do not have 
%           metrics available
%
% Web data accessed via the Allen Brain Atlas API [6] or AWS Public 
% Datasets (Amazon S3). 
%
% For references [#]:
%   See also bot.util.showReferences

function cellsTable = listCells(datasetName, include_metrics)
    arguments
        datasetName (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
        include_metrics logical = false;
    end
    
    % Get the metadata manifest for the selected dataset
    manifest = bot.item.internal.Manifest.instance('Ophys', datasetName);
    
    % Get the cells item table
    if datasetName == "VisualCoding"
        cellsTable = manifest.ophys_cells;
    else
        cellsTable = manifest.OphysCells;
    end

    if ~include_metrics 
        if datasetName == bot.item.internal.enum.Dataset.VisualCoding
            cellsTable = removevars(cellsTable, bot.item.Cell.METRIC_PROPERTIES);
        end
    end
end
