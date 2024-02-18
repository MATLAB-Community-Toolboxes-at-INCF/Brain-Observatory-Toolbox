% Retrieve table of ophys cell information from an Allen Brain Observatory dataset
%
% Supports the Visual Coding 2P [1] dataset and the Visual Behavior 2P [2] 
% dataset from the Allen Brain Observatory [3].
%
% Usage:
%    cells = bot.listCells() returns a table of cell information for the
%       Visual Coding dataset
%
%    cells = bot.listCells(datasetName) returns a table of cell information 
%       for the specified dataset. datasetName can be "VisualCoding" or
%       "VisualBehavior" (Default = "VisualCoding")
%
%    cells = bot.listCells(datasetName, include_metrics) additionally 
%       specifies whether to include cell metrics or not (Default = false).
%       Note: The cell table from the Visual Behavior Dataset do not have 
%           metrics available
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
