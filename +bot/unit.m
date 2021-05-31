% Obtain object array representing identified unit item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding Neuropixels [1] dataset from the Allen Brain Observatory [2]. 
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.fetchUnits() 
%   * tables contained by other item objects (sessions, channels, probes)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.fetchUnits. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.   
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% 
%% function unitObj = unit(unitIDSpec)
function unitObj = unit(unitIDSpec)

arguments
    unitIDSpec {bot.item.abstract.Item.mustBeItemIDSpec}
end

% - Return the unit object
unitObj = bot.item.Unit(unitIDSpec);
