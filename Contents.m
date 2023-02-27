% Brain Observatory Toolbox
% Version 0.9.3 (R2022b) 21-feb-2023
%
% Copyright (c) 2017, Ethan Meyers
% ----------------------------------
%
% A MATLAB toolbox for accessing and using the public neural 
% recording datasets from the Allen Brain Observatory.
% 
% Get started with the <a href="matlab:open EphysQuickstart" style="font-weight:bold">EphysQuickstart</a> & <a href="matlab:open bot.OphysQuickstart" style="font-weight:bold">OphysQuickstart</a> guides.
% 
% See the Brain Observatory Toolbox applied to neuroscience data 
% analysis in the <a href="matlab:open demos\EphysDemo" style="font-weight:bold">EphysDemo</a> & <a href="matlab:open demos\OphysDemo" style="font-weight:bold">OphysDemo</a>.
% 
% Learn how to use the Brain Observatory Toolbox with the 
% <a href="matlab:open tutorials\EphysTutorial" style="font-weight:bold">EphysTutorial</a>, <a href="matlab:open tutorials\OphysTutorial" style="font-weight:bold">OphysTutorial</a> & <a href="matlab:open tutorials\BehaviorTutorial" style="font-weight:bold">BehaviorTutorial</a>
%
%   Getting started
%     bot.callMeFirst       - Show Getting Started live script (if using desktop environment)
%
%   Listing item information:
%     bot.listExperiments   - List information about all experiments (Ophys)
%     bot.listSessions      - List information about all sessions (Ephys & Ophys)
%     bot.listProbes        - List information about all probes (Ephys)
%     bot.listChannels      - List information about all channels (Ephys)
%     bot.listUnits         - List information about all units (Ephys)
%     bot.listCells         - List information about all cells (Ophys)
%   
%   Obtaining item objects:
%     bot.getExperiments     - Obtain item(s) representing experiments (Ophys)
%     bot.getSessions        - Obtain item(s) representing sessions (Ephys & Ophys)
%     bot.getProbes          - Obtain item(s) representing probes (Ephys)
%     bot.getChannels        - Obtain item(s) representing channels (Ephys)
%     bot.getUnits           - Obtain item(s) representing units (Ephys)
%     bot.getCells           - Obtain item(s) representing cells (Ophys)
%
%   Get preferences for the toolbox:
%     bot.util.getPreferences     - Get a preference singleton object. 
