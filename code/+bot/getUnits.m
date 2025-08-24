% Obtain object array representing identified unit item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory.
%
% Usage:
%   unitObj = bot.getUnits(unitIDSpec) returns a unit item object given a
%       unitIDSpec. See below for more details on unitIDSpec.
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listUnits() 
%   * tables contained by other item objects (sessions, channels, probes)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listUnits. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.   
%
% For references [#]:
%   See also bot.util.showReferences

function unitObj = getUnits(unitIDSpec)
    arguments
        unitIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    end
    
    % - Return the unit object
    unitObj = bot.item.Unit(unitIDSpec);
end
