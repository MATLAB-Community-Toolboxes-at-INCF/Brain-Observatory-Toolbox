% Retrieve table of Neuropixels probes information for an Allen Brain Observatory dataset
%
% Supports the Visual Coding Neuropixels [1] dataset and the Visual 
% Behavior Neuropixels [2] dataset from the Allen Brain Observatory [3].
%
% Usage:
%    probes = bot.listProbes() returns a table of information for 
%       Neuropixels probes of the Visual Coding dataset
%
%    probes = bot.listProbes(datasetName) returns a table of probe 
%       information for the specified dataset. datasetName can be 
%       "VisualCoding" or "VisualBehavior" (Default = "VisualCoding")
%
% Web data accessed via the Allen Brain Atlas API [4]. 
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. 
%       Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
%
% [2] Copyright 2023 Allen Institute for Brain Science. Visual Behavior Neuropixels dataset. 
%       Available from: https://portal.brain-map.org/circuits-behavior/visual-behavior-neuropixels
%
% [3] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: https://portal.brain-map.org/explore/circuits
%
% [4] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. 
%       Available from: https://brain-map.org/api/index.html

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
