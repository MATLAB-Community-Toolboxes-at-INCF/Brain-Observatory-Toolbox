% Obtain object array representing identified session item(s) from an Allen Brain Observatory [1] dataset
% 
% Can return experimental sessions from either of the Allen Brain 
% Observatory [1] datasets:
%   * Visual Coding 2P [2] ("ophys")
%   * Visual Coding Neuropixels [3] ("ephys")
%   * Visual Behavior 2P [4] ("ophys")
%   * Visual Behavior Neuropixels [5] ("ephys")
%
% Usage:
%   sessionObj = bot.getSessions(sessionIDSpec) returns a session item 
%       object given a sessionIDSpec. See below for more details on 
%       sessionIDSpec.
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
% For references [#]:
%   See also bot.util.showReferences

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
            sessionType = sessionIDSpec.Properties.CustomProperties.DatasetType;
        else
            % No hint available --> resolve by checking all item manifests
            [datasetName, sessionType] = resolveSessionType(sessionIDSpec); % Local function
        end
    end
    
    if isempty(datasetName) || string(datasetName) == "None"
        if istable(sessionIDSpec)  
            sessionType = sessionIDSpec.Properties.CustomProperties.DatasetType;
            datasetName = sessionIDSpec.Properties.CustomProperties.DatasetName;
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
    
    persistent sessionIdMap

    if isempty(sessionIdMap)
        sessionIdMap = dictionary();

        % Check each of the metadata manifests.
        [~, datasetNames] = enumeration('bot.item.internal.enum.Dataset');
        [~, datasetTypes] = enumeration('bot.item.internal.enum.DatasetType');
        
        warning('off', 'BOT:ListSessions:BehaviorOnlyNotPresent')
        for iName = string(datasetNames')
            for jType = string(datasetTypes')
                for k = 0:1
                    sessionTable = bot.listSessions(iName, jType, "IncludeBehaviorOnly", logical(k));
                    ids = sessionTable.id;
                    sessionIdMap(ids)={{iName, jType}};
                end
            end
        end
        warning('on', 'BOT:ListSessions:BehaviorOnlyNotPresent')
    end

    numSessions = numel(sessionIDSpec);
    [datasetName, sessionType] = deal( repmat("",1,numSessions) );
    for i = 1:numSessions
        try
            [datasetName(i), sessionType(i)] = ...
                deal( sessionIdMap{sessionIDSpec(i)}{:} );
        catch
            ME = MException('BOT:getSessions:IdNotFound', ...
                'Could not find any Session with id %d.', sessionIDSpec(i));
            throwAsCaller(ME)
        end
    end

    sessionType = unique(sessionType);
    datasetName = unique(datasetName);

    if numel(sessionType)>1 || numel(datasetName)>1
        error('BOT:getSessions:MixedItemsNotSupported', ...
            'Creating sessions of different datasets / types is currently not supported')
    end
end
