% Retrieve table of Neuropixels channels information for an Allen Brain Observatory [1] dataset
%
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory [1].
%
% Usage:
%    channels = bot.listChannels() returns a table of channel information
%       for Neuropixels probes of the Visual Coding dataset
%
%    channels = bot.listChannels(datasetName) returns a table of channel 
%       information for the specified dataset. datasetName can be 
%       "VisualCoding" or "VisualBehavior" (Default = "VisualCoding")
%
% Web data accessed via the Allen Brain Atlas API [6] or AWS Public 
% Datasets (Amazon S3). 
%
% For references [#]:
%   See also bot.util.showReferences

function channelsTable = listChannels(datasetName)
    arguments 
        datasetName (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
    end

    manifest = bot.item.internal.Manifest.instance('Ephys', datasetName);
    if datasetName == "VisualCoding"
        channelsTable = manifest.ephys_channels;
    else
        channelsTable = manifest.Channels;
    end
end
