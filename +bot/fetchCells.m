% Retrieve table of cell information from the Allen Brain Observatory Visual Coding dataset [1, 2]
%
% Web data accessed via the Allen Brain Atlas API [3]. 
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [3] Copyright 2015 Allen Institute for Brain Science. Allen Brain Atlas API. Available from: https://brain-map.org/api/index.html
%
%% function cellsTable = fetchCells
function cellsTable = fetchCells
     manifest = bot.internal.manifest.instance('ophys');
     cellsTable = manifest.ophys_cells;
end
