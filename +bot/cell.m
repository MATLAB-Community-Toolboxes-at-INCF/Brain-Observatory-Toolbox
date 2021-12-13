% Obtain object array representing identified cell item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding 2P [1] dataset from the Allen Brain Observatory [2]. 
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.fetchCells() 
%   * tables contained by other item objects (sessions, experiments)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.fetchCells. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.   
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% 
%% function cellObj = cell(cellIDSpec)
function cellObj = cell(cellIDSpec)

arguments
    cellIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
end

% - Return the unit object
cellObj = bot.item.Cell(cellIDSpec);
