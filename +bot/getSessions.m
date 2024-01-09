% Obtain object array representing identified session item(s) from an Allen Brain Observatory dataset
% 
% Can return experiment sessions from either of the Allen Brain Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophyssession")
%   * Visual Coding Neuropixels [3] ("ephyssession") 
%
% Can specify item(s) by unique numeric IDs for item. These can be obtained via:
%   * table returned by bot.listSessions(...) 
%   * tables contained by other item objects (channels, probes, units, experiments)
%
% Can also specify item(s) by supplying an information table of the format
% returned by bot.listSessions. This is often useful when such a table has
% been "filtered" to one or a few rows of interest via table indexing
% operations. 
%   
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
% [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
% [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% 
%% function sessionObj = getSessions(sessionSpec) 
function sessionObj = getSessions(sessionIDSpec, sessionType, datasetName)

    arguments
        % Required arguments
        sessionIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec}
        
        % Optional arguments
        sessionType (1,:) bot.item.internal.enum.DatasetType = ...
            bot.item.internal.enum.DatasetType.empty
    
        datasetName (1,:) bot.item.internal.enum.Dataset = ...
            bot.item.internal.enum.Dataset.empty
    end
    
    if isempty(sessionType)
        % Try to determine sessionType if possible
        
        if istable(sessionIDSpec)  
            sessionType = sessionIDSpec.Properties.UserData.DatasetType;
        else
            % No hint available --> resolve by checking all item manifests
            [datasetName, sessionType] = resolveSessionType(sessionIDSpec); % Local function
        end
    end
    
    if isempty(datasetName) || string(datasetName) == "None"
        if istable(sessionIDSpec)  
            sessionType = sessionIDSpec.Properties.UserData.DatasetType;
            datasetName = sessionIDSpec.Properties.UserData.DatasetName;
        else
            error('Please specify the name of the dataset this session belongs to, i.e "VisualCoding" or "VisualBehavior"')
        end
    end
    
    switch string(datasetName) + string(sessionType)
        case "VisualCodingOphys"
            sessionObj = bot.item.concrete.OphysSession(sessionIDSpec);
        case "VisualCodingEphys"
            sessionObj = bot.item.concrete.EphysSession(sessionIDSpec);
        case "VisualBehaviorOphys"
            sessionObj = bot.behavior.item.OphysSession(sessionIDSpec);
        case "VisualBehaviorEphys"
            sessionObj = bot.behavior.item.EphysSession(sessionIDSpec);
    
        otherwise
            assert(false);
    end
end

function [datasetName, sessionType] = resolveSessionType(sessionIDSpec)
    
    boc = bot.internal.Cache.instance();

    if boc.isObjectInCache('session_id_map')
        sessionIdMap = boc.retrieveObject('session_id_map');
    else
        sessionIdMap = dictionary();

        % Check each of the metadata manifests.
        [~, datasetNames] = enumeration('bot.item.internal.enum.Dataset');
        [~, datasetTypes] = enumeration('bot.item.internal.enum.DatasetType');
        
        for iName = string(datasetNames')
            for jType = string(datasetTypes')
                manifest = bot.item.internal.Manifest.instance(jType, iName);
                tableName = jType + "Sessions";
                ids = manifest.(tableName).id;
                sessionIdMap(ids)={{iName, jType}};
            end
        end
        
        boc.insertObject('session_id_map', sessionIdMap)
    end

    numSessions = numel(sessionIDSpec);
    [datasetName, sessionType] = deal( repmat("",1,numSessions) );
    for i = 1:numSessions
        [datasetName(i), sessionType(i)] = ...
            deal( sessionIdMap{sessionIDSpec(i)}{:} );
    end

    sessionType = unique(sessionType);
    datasetName = unique(datasetName);

    if numel(sessionType)>1 || numel(datasetName)>1
        error('Creating sessions of different datasets / types is currently not supported')
    end
end
