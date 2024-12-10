% Obtain object array representing identified probe item(s) from an Allen Brain Observatory dataset
% 
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory.
%
% Usage:
%   probeObj = bot.getProbes(probeIDSpec) returns a probe item object given a
%       probeIDSpec. See below for more details on probeIDSpec.
%
% Specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listProbes() 
%   * tables contained by other item objects (sessions, channels, units)
%   
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listProbes. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations.
%
% For references [#]:
%   See also bot.util.showReferences

function probeObj = getProbes(probeIDSpec)
    arguments
        probeIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    end
    
    % - Return the probe object
    probeObj = bot.item.Probe(probeIDSpec);
end
