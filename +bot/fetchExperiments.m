% Retrieve table of experiment container information for an Allen Brain Observatory dataset
%
% Supports the Visual Coding 2P [1] dataset from the Allen Brain Observatory [2]. 
%
% Web data accessed via the Allen Brain Atlas API [3]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [3] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: https://brain-map.org/api/index.html
%
%% function experimentsTable = fetchExperiments()
function experimentsTable = fetchExperiments()
   manifest = bot.internal.manifest.instance('ophys');
   experimentsTable = manifest.ophys_experiments;
end
