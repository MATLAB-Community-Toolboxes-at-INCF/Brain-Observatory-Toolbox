% Obtain object array representing identified channel item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory.
%
% Usage:
%   channelObj = bot.getChannels(channelIDSpec) returns a channel item object
%       given a channelIDSpec. See below for more details on channelIDSpec.
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listChannels() 
%   * tables contained by other item objects (sessions, probes, units)   
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listChannels. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.
%
% For references [#]:
%   See also bot.util.showReferences

function channelObj = getChannels(channelIDSpec)
    arguments
        channelIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    end
    
    % - Return the channel object
    channelObj = bot.item.Channel(channelIDSpec);
end
