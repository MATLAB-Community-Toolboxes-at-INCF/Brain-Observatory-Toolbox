% Brain Observatory Toolbox
% Version 0.9.4 19-feb-2024
%
% Copyright (c) 2017, Ethan Meyers
% ----------------------------------
%
% A MATLAB toolbox for accessing and using the public neural 
% recording datasets from the Allen Brain Observatory.
%
%   Getting started:
%     bot.README       - View README live script providing links to examples (if using desktop environment)
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
%     bot.getExperiments    - Obtain item(s) representing experiments (Ophys)
%     bot.getSessions       - Obtain item(s) representing sessions (Ephys & Ophys)
%     bot.getProbes         - Obtain item(s) representing probes (Ephys)
%     bot.getChannels       - Obtain item(s) representing channels (Ephys)
%     bot.getUnits          - Obtain item(s) representing units (Ephys)
%     bot.getCells          - Obtain item(s) representing cells (Ophys)
%
%   Get and set toolbox preferences:
%     bot.util.getPreferences   - Obtain handle to the toolbox preferences object
