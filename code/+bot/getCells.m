% Obtain object array representing identified cell item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding 2P [2] dataset and the Visual Behavior 2P [4] 
% dataset from the Allen Brain Observatory [1].
%
% Usage:
%   cellObj = bot.getCells(cellIDSpec) returns a cell item object given a
%       cellIdSpec. See below for more details on cellIDSpec.
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listCells() 
%   * tables contained by other item objects (sessions, experiments)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listCells. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.   
%
% For references [#]:
%   See also bot.util.showReferences

function cellObj = getCells(cellIDSpec)
    arguments
        cellIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    end
    
    % - Return the unit object
    cellObj = bot.item.Cell(cellIDSpec);
end
