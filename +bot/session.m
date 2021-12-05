% Obtain object array representing identified session item(s) from an Allen Brain Observatory dataset
% 
% Can return experiment sessions from either of the Allen Brain Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophyssession")
%   * Visual Coding Neuropixels [3] ("ephyssession") 
%
% Can specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.fetchSessions(...) 
%   * tables contained by other item objects (channels, probes, units, experiments)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.fetchSessions. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations. 
%   
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% 
%% function sessionObj = session(sessionSpec) 
function sessionObj = session(sessionIDSpec,sessionType)

arguments
    % Required arguments
    sessionIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
    
    % Optional arguments
    sessionType (1,:) string {mustBeMember(sessionType,["ephys" "ophys" ""])} = string.empty(1,0);
end


if isempty(sessionType)
    % Try to determine sessionType if possible
    
    if istable(sessionIDSpec)  
        sessionType = lower(string(sessionIDSpec.Properties.UserData.type));
        
    else    
        % No hint available --> must call both constructors sequentially to try matching against both manifests
        
        sessionObj = [];
                
        try
            sessionObj = bot.item.concrete.OphysSession(sessionIDSpec);
        catch ME
            if ~isequal(ME.identifier,"BOT:Item:idNotFound") && ~isequal(ME.identifier, "MATLAB:UnableToConvert")
                ME.rethrow();
            end
        end
        
        if isempty(sessionObj)
            sessionObj = bot.item.concrete.EphysSession(sessionIDSpec);
        end
        
        return
    end
end

switch sessionType
    case "ophys"
        sessionObj = bot.item.concrete.OphysSession(sessionIDSpec);
    case "ephys"
        sessionObj = bot.item.concrete.EphysSession(sessionIDSpec);
    otherwise
        assert(false);
end

