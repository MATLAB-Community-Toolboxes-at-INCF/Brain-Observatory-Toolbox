function datasetName = resolveDataset(itemId, datasetType, itemType)
% resolveDataset - Resolve the dataset (name) an item belongs to.
    
% See also local function "resolveSessionType" in bot.getSessions

    datasetName = [];

    listFcn = str2func( sprintf("bot.list%ss", string(itemType)) ); %i.e @bot.listSessions
    allDatasets = enumeration('bot.item.internal.enum.Dataset');
    allDatasets = reshape(allDatasets, 1, []);

    for iDataset = allDatasets
        if itemType == bot.item.internal.enum.ItemType.Session
            itemTable = feval(listFcn, iDataset, datasetType);
        else
            itemTable = feval(listFcn, iDataset);
        end

        if any( ismember(itemTable.id, itemId) )
            datasetName = iDataset;
            return
        end
    end

    if isempty(datasetName)
        error('BOT:UnresolvedDataset', 'Could not resolve dataset for item of type %s with id %d', itemType, itemId)
    end
end
