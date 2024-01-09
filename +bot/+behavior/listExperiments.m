% Retrieve table of experiment information for an Allen Brain Observatory dataset
%
% Supports the Visual Behavior 2P [1] dataset from the Allen Brain Observatory [2]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Behavior 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-behavior-2p
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
%
%% function experimentsTable = listExperiments()
function experimentsTable = listExperiments()
    dataset = bot.item.internal.enum.Dataset('VisualBehavior');
    manifest = bot.item.internal.Manifest.instance('Ophys', dataset);
    experimentsTable = manifest.OphysExperiments;
end