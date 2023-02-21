% Brain Observatory Toolbox
% Version 0.9.3 (R2022a) 15-dec-2022
%
% Copyright (c) 2017, Ethan Meyers
% ----------------------------------
%
% A MATLAB toolbox for accessing and using the public neural 
% recording datasets from the Allen Brain Observatory.
% 
% Get started with the <a href="matlab:open EphysQuickstart" style="font-weight:bold">EphysQuickstart</a> & <a href="matlab:open OphysQuickstart" style="font-weight:bold">OphysQuickstart</a> guides.
% 
% See the Brain Observatory Toolbox applied to neuroscience data 
% analysis in the <a href="matlab:open EphysDemo" style="font-weight:bold">EphysDemo</a> & <a href="matlab:open OphysDemo" style="font-weight:bold">OphysDemo</a>.
% 
% Learn how to use the Brain Observatory Toolbox with the 
% <a href="matlab:open EphysTutorial" style="font-weight:bold">EphysTutorial</a>, <a href="matlab:open OphysTutorial" style="font-weight:bold">OphysTutorial</a> & <a href="matlab:open BehaviorTutorial" style="font-weight:bold">BehaviorTutorial</a>
%
%
%   Fetching item information:
%     bot.fetchExperiments   - List information about all experiments (Ophys)
%     bot.fetchSessions      - List information about all sessions (Ephys & Ophys)
%     bot.fetchProbes        - List information about all probes (Ephys)
%     bot.fetchChannels      - List information about all channels (Ephys)
%     bot.fetchUnits         - List information about all units (Ephys)
%     bot.fetchCells         - List information about all cells (Ophys)
%   
%   Getting item objects:
%     bot.getExperiments     - Obtain item(s) representing experiments (Ophys)
%     bot.getSessions        - Obtain item(s) representing sessions (Ephys & Ophys)
%     bot.getProbes          - Obtain item(s) representing probes (Ephys)
%     bot.getChannels        - Obtain item(s) representing channels (Ephys)
%     bot.getUnits           - Obtain item(s) representing units (Ephys)
%     bot.getCells           - Obtain item(s) representing cells (Ophys)
%
%   Get preferences for the toolbox:
%     bot.util.getPreferences     - Get a preference singleton object. 
