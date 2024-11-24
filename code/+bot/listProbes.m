% Retrieve table of Neuropixels probes information for an Allen Brain Observatory [1] dataset
%
% Supports the Visual Coding Neuropixels [3] dataset and the Visual 
% Behavior Neuropixels [5] dataset from the Allen Brain Observatory [1].
%
% Usage:
%    probes = bot.listProbes() returns a table of information for 
%       Neuropixels probes of the Visual Coding dataset
%
%    probes = bot.listProbes(datasetName) returns a table of probe 
%       information for the dataset specified by datasetName. datasetName 
%       can be "VisualCoding" (default) or "VisualBehavior".
%
% Web data accessed via the Allen Brain Atlas API [6] or AWS Public 
% Datasets (Amazon S3). 
%
% For references [#]:
%   See also bot.util.showReferences

function probesTable = listProbes(datasetName)
    arguments 
        datasetName (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
    end
    
    manifest = bot.item.internal.Manifest.instance('Ephys', datasetName);
    if datasetName == "VisualCoding"
        probesTable = manifest.ephys_probes;
    else
        probesTable = manifest.Probes;
    end
end
