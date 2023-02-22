% Retrieve table of Neuropixels probes information for an Allen Brain Observatory dataset
%
% Supports the Visual Coding Neuropixels [1] dataset from the Allen Brain Observatory [2]. 
%
% Web data accessed via the Allen Brain Atlas API [3]. 
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [3] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: https://brain-map.org/api/index.html
%
%% function probesTable = listProbes()
function probesTable = listProbes()
   manifest = bot.item.internal.Manifest.instance('ephys');
   probesTable = manifest.ephys_probes;
end