% Manifest — Create or download a manifest from the Allen Brain Observatory

% Todo: rename to MetadataTables.

classdef Manifest < handle & matlab.mixin.CustomDisplay & bot.item.internal.mixin.OnDemandProps
       
    properties (Abstract, Access=protected, Constant, Hidden)
        DATASET_NAME (1,1) bot.item.internal.enum.Dataset

        % Enumeration for dataset type that a concrete manifest is part of
        DATASET_TYPE (1,1) bot.item.internal.enum.DatasetType
        
        % Names of available item types for a manifest of a given dataset type
        ITEM_TYPES (1,:) string

        % Resource to use for downloading the respective item tables. If 
        % nothing is specified, the default resource will be gotten from
        % preferences. The purpose of this constant property is to override
        % the preference for some of the item types.
        DOWNLOAD_FROM containers.Map
    end

    properties (Access = protected, Transient = true)
        cache bot.internal.Cache % BOT Cache object for caching of data to disk
    end

    properties (Access = protected)
        MemoizedFetcher = struct % Memoized functions for fetching item tables
    end

    properties (Abstract, Access = protected)
        FileResource
    end

    methods (Access = protected) % Constructor

        function manifest = Manifest()

            % Assign the disk cache
            manifest.cache = bot.internal.Cache.instance();

            % Assign on-demand properties
            manifest.ON_DEMAND_PROPERTIES = lower(string(manifest.DATASET_TYPE)) ...
                + "_" + lower(manifest.ITEM_TYPES) + "s";

            % Suggested upgrade:
            %manifest.ON_DEMAND_PROPERTIES = manifest.ITEM_TYPES + "s";     % Property names are plural
            
            doClear = manifest.checkRequiresUpdate();
            if doClear
                manifest.clearManifest(false); manifest.logClearedManifest()
            end
        end
    end

    methods % Methods fetchAll & clearManifest

        function fetchAll(manifest)
        %fetchAll Fetches all of the item tables of the manifest
        %
        %   fetchAll(manifest) will fetch all item tables of the concrete
        %   manifest.

            for itemType = manifest.ITEM_TYPES
                propName = lower(string(manifest.DATASET_TYPE)) + "_" + lower(itemType) + "s";
                manifest.(propName);

                % Suggested upgrade:
                %manifest.(itemType+"s");
            end
        end

        function manifest = updateManifest(manifest, updateMemoOnly)
            arguments
                manifest (1,1) bot.item.internal.Manifest
                updateMemoOnly (1,1) logical = true
            end
            
            manifest.clearManifest(updateMemoOnly)
            manifest.fetchAll()
        end
    
        function clearManifest(manifest, clearMemoOnly, itemTypeToClear)
        %clearManifest Clear the manifest contents (item tables)
        %
        %   clearManifest(manifest) clears the manifest from memory.
        %   
        %   clearManifest(manifest, clearMemoOnly) additionally specifies
        %   the level of clearing. `clearMemoOnly = true` (default) will
        %   clear the manifest contents from memory only, whereas 
        %   `clearMemoOnly = false` will also clear the manifest contents 
        %   from the disk cache

            arguments
                manifest (1,1) bot.item.internal.Manifest
                clearMemoOnly (1,1) logical = true
                itemTypeToClear (:, 1) string = "all"
            end

            if itemTypeToClear == "all"
                itemTypeToClear = manifest.ITEM_TYPES;
            end

            if ~clearMemoOnly
                for itemType = itemTypeToClear

                    % - Remove temporary item table data from disk cache
                    manifest.clearTempTableFromCache(itemType)

                    % - Remove complete item tables from disk cache
                    warning('off', 'LocalFileCache:FileNotInCache')
                    cacheKey = manifest.getManifestCacheKey(itemType);
                    manifest.cache.removeObject(cacheKey)
                    warning('on', 'LocalFileCache:FileNotInCache')
                end
            end

            % - Clear all caches for memoized access functions
            for strField = fieldnames(manifest.MemoizedFetcher)'
                manifest.MemoizedFetcher.(strField{1}).clearCache();
            end

            % - Clear the ondemand property cache
            manifest.clear_on_demand_cache()
        end
    end

    methods (Abstract, Access = protected)
        % Item tables downloaded from the S3 bucket are stored in different
        % formats for different dataset types. Use this function in
        % subclasses to read the table using appropriate methods.
        readS3ItemTable(manifest, filePath)
    end

    methods (Hidden, Access = protected) % Override matlab.mixin.CustomDisplay
        function str = getHeader(obj)
            str = getHeader@matlab.mixin.CustomDisplay(obj);
            str = replace(str, 'properties', 'item tables');
        end
        
        function groups = getPropertyGroups(obj)
        %getPropertyGroups Show on-demand status of manifest item tables

            if ~isscalar(obj) % Should not be a case for singletons...
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else                           
               propListing = obj.getOnDemandPropListing(obj.ON_DEMAND_PROPERTIES);
               propNameList = string( fieldnames(propListing)' );
               itemTypeList = obj.ITEM_TYPES;

               for i = 1:numel(propNameList)
                  thisPropName = propNameList(i);
                  thisItemType = itemTypeList(i);
                  
                  if strcmp(propListing.(thisPropName), '[on demand]')
                    if obj.cache.isObjectInCache(obj.getManifestCacheKey(thisItemType))
                        propListing.(thisPropName) = '[on demand - available in cache]';
                    else
                        propListing.(thisPropName) = '[on demand - download required]';
                    end
                  end
               end

               groups = matlab.mixin.util.PropertyGroup(propListing, "");
            end
        end
    end

    methods (Access = protected) % Download tables from allen brain observatory
        
        function itemTable = download_item_table(manifest, itemType)
        % download_item_table Download item table from Allen Brain Observatory dataset
        %
        % Usage: 
        %   itemTable = download_item_table(manifest, itemType) downloads
        %   the item table for the specified itemType.
        %
        %   itemType must be a character vector or a string and must be a
        %   member of one of the ITEM_TYPES of the concrete manifest.
            
        %   Todo: This should be managed by the cache
            downloadFrom = manifest.DOWNLOAD_FROM(itemType);

            if strcmp(downloadFrom, "")
                downloadFrom = bot.internal.Preferences.getPreferenceValue('DownloadFrom');
            end

            fprintf('Downloading %s table...\n', lower(itemType))
            
            if downloadFrom == "API"
                itemTable = manifest.download_table_from_api(itemType);
            else
                itemTable = manifest.download_table_from_s3(itemType);
            end
        end

        function dataTable = download_table_from_s3(manifest, itemType)
        %download_table_from_s3 download item table from ABO S3 bucket

            mustBeMember(itemType, manifest.ITEM_TYPES) % Sanity check
            
            strURI = manifest.FileResource.getItemTableURI(itemType);
            objURI = matlab.net.URI(strURI);

            switch objURI.Scheme
                case 'file'
                    strCachedFilepath = objURI.EncodedPath; % Uncached
                case 's3'
                    strCachedFilepath = manifest.cache.CacheFile(strURI, '', '', 'RetrievalMode', "Copy");
                case 'https'
                    strCachedFilepath = manifest.cache.CacheFile(strURI, '');
            end
            % Todo: Move the logic above into cache/CacheFile
            dataTable = manifest.readS3ItemTable(strCachedFilepath);
        end

        function dataTable = download_table_from_api(manifest, itemType)
        %download_table_from_api download item table from ABO api

            mustBeMember(itemType, manifest.ITEM_TYPES) % Sanity check
            datasetType = char(manifest.DATASET_TYPE);

            if strcmp(itemType, 'Cell')
                nvPairs = {'SortingAttributeName', "cell_specimen_id"};
            else
                nvPairs = {'SortingAttributeName', "id"};
            end
            
            fileResource = bot.internal.fileresource.WebApi.instance();
            strURL = fileResource.getItemTableURI(datasetType, itemType);
            dataTable = manifest.cache.CachedRMAQuery(strURL, nvPairs{:});
        end
    end
    
    methods (Access = protected) % Utility methods for subclasses
        
        function itemTable = addDatasetInformation(obj, itemTable)
            itemTable.Properties.UserData.DatasetType = string(obj.DATASET_TYPE);
            itemTable.Properties.UserData.DatasetName = string(obj.DATASET_NAME);
        end

        function clearTempTableFromCache(manifest, itemType)
        %clearTempTableFromCache Clear temporary item table from disk cache
        %
        %   clearTempTableFromCache(manifestObj, datasetType, itemType)
        %       clears temporary table data for specified manifest object 
        %       and itemType. 
        
        %   Note: Try to clear table data as retrieved from both S3 bucket
        %   and web API.
        
            datasetType = char(manifest.DATASET_TYPE);
            diskCache = manifest.cache;

            warning('off', 'LocalFileCache:FileNotInCache')
            strURI = manifest.FileResource.getItemTableURI(itemType);
            diskCache.CloudCacher.remove(strURI)

            if manifest.DATASET_NAME == bot.item.internal.enum.Dataset.VisualCoding
                apiFileResource = bot.internal.fileresource.WebApi.instance();
                strURI = apiFileResource.getItemTableURI(datasetType, itemType);
                diskCache.CloudCacher.removeURLsMatchingSubstring(strURI)
            end

            warning('on', 'LocalFileCache:FileNotInCache')
        end
    
        function cacheKey = getManifestCacheKey(manifest, itemType)
        %getManifestCacheKey Get cache key for manifest item type
        %
        %   cacheKey = getManifestCacheKey(manifest, itemType) returns a
        %   character vector representing a key to use in the disk cache
        %   for a itemtype of the manifest. itemType is a character vector
        %   and should be one of the ITEM_TYPES for the manifest
        %
        %   Example:
        %       cacheKey = getManifestCacheKey(ephysManifest, "Session")
        %
        %       ans =
        %           'allen_brain_observatory_ephys_sessions_manifest'

            datasetName = char(manifest.DATASET_NAME);
            datasetType = char(manifest.DATASET_TYPE);
            
            cacheKey = sprintf('allen_brain_observatory_%s_%s_%ss_manifest', ...
                lower(datasetName), lower(datasetType), lower(itemType));
        end
    
    end
    
    methods (Access = private)
        function doUpdate = checkRequiresUpdate(obj)
            
            % Latest version to trigger a reset of manifest tables.
            MIN_BOT_VERSION = '0.9.4';

            classNameSplit = strsplit(class(obj), '.');
            simpleClassName = classNameSplit{end};

            botCache = bot.internal.Cache.instance();
            
            if botCache.isObjectInCache('BOTVersionForCachedManifest')
                versionMap = botCache.retrieveObject('BOTVersionForCachedManifest');
                if isKey(versionMap, simpleClassName)
                    lastVersion = versionMap(simpleClassName);
                    doUpdate = bot.internal.util.isVerLessThan(lastVersion, MIN_BOT_VERSION);
                else
                    doUpdate = true;
                end
            else
                doUpdate = true;
            end
        end

        function logClearedManifest(obj)
        % logClearedManifest - Logs that manifest has been cleared for
        % current BOT version
            classNameSplit = strsplit(class(obj), '.');
            simpleClassName = classNameSplit{end};
            currentVersion = bot.internal.util.getToolboxVersion();
            
            botCache = bot.internal.Cache.instance();

            if botCache.isObjectInCache('BOTVersionForCachedManifest')
                versionMap = botCache.retrieveObject('BOTVersionForCachedManifest');
            else
                versionMap = dictionary();
            end

            versionMap(simpleClassName) = currentVersion;
            warning('off', 'ObjectCacher:FileExists')
            botCache.insertObject('BOTVersionForCachedManifest', versionMap)
            warning('on', 'ObjectCacher:FileExists')
        end
    end

    %% STATIC METHODS - PUBLIC
    methods (Static)

        function manifest = instance(type, dataset)
            
            arguments
                type (1,1) bot.item.internal.enum.DatasetType
                dataset (1,1) bot.item.internal.enum.Dataset = "VisualCoding"
            end
            
            switch dataset.Name
                case "VisualCoding"
                    switch lower(string(type))
                        case 'ophys'
                            manifest = bot.item.internal.OphysManifest.instance();
                        case 'ephys'
                            manifest = bot.item.internal.EphysManifest.instance();
                    end

                case "VisualBehavior"
                    switch lower(string(type))
                        case 'ophys'
                            manifest = bot.internal.metadata.VisualBehaviorOphysManifest.instance();
                        case 'ephys'
                            manifest = bot.internal.metadata.VisualBehaviorEphysManifest.instance();
                    end

                case "All"
                    error('Can only return one manifest, please specify one dataset')

                otherwise
                    error('Dataset "%s" does not have any associated item tables', dataset.Name)
            end
        end         
        
        function tbl = applyUserDisplayLogic(tbl)
            % Refine manifest table for user display as a table of Items
            
            assert(isa(tbl,'table'),"The input manifest must be a table object");
            
            varNames = string(tbl.Properties.VariableNames);
            
            
            tbl.Properties.UserData = struct();
            
            %% Remove columns whose values are "redundant" (the same for all rows); store these as table properties instead
            redundantVarNames = string([]);
            
            userDataString = "";
            
            for col = 1:length(varNames)
                
                if ~isstruct(tbl{1,col}) && ~iscell(tbl{1,col}) && numel(unique(tbl{:,col},'stable')) == 1 % all (non-compound) values in a column are equal
                    
                    redundantVar = varNames(col);
                    redundantVarNames = [redundantVarNames redundantVar]; %#ok<AGROW>
                    
                    %addfield(manifest.Properties.UserData,redundantVar);
                    redundantVal = tbl{1,col};
                    tbl.Properties.UserData.(redundantVar) = redundantVal;
                    
                    
                    userDataString = userDataString + redundantVar + ": " + string(redundantVal) + " - ";
                end
            end
            userDataString = userDataString.strip();
            userDataString = userDataString.strip("-");
            tbl.Properties.Description = userDataString;
            
            tbl = removevars(tbl, redundantVarNames);
            
            %% Remove columns repeating directory values (e.g. with OphysSession)
            
            containsDirVars = varNames(varNames.contains("directory"));
            tbl = removevars(tbl, containsDirVars);
            
            %% Convert ephys_structure_acronym from cell types to string/categorical type
            % TODO: refactor to generalize this for all cell2str convers (some of which is currently implemented in ephysmanifest)
            varIdx = find(varNames.contains("structure_acronym"));
            if varIdx
                var = tbl.(varNames(varIdx));
                
                if iscell(var)
                    if iscell(var{1}) % case of: cell string array with empty last value (ephys session case)
                        
                        % convert to cell string array
                        assert(all(cellfun(@(x)isempty(x{end}),var))); % all the cell string arrays end with an empty double array, for reason TBD
                        tbl.(varNames(varIdx)) = cellfun(@(x)join(string(x(1:end-1))',"; "),var); % convert each cell element to string, skipping the ending empty double array
                        
                    elseif iscategorical(var{1})
                        % pass

                    else % case of: 'almost' cell string arrays, w/ empty values represented as numerics
                        assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),var)))));
                        
                        var2 = var;
                        [var2{cellfun(@(x)~ischar(x), var)}] = deal('');
                        tbl.(varNames(varIdx)) = categorical(string(var2)); % strings are scalars in this case --> convert to categorical
                    end
                end
            end
            
            %% Convert ophys area from cell types to string/categorical type
            % TODO: refactor to generalize this for all cell2str converts (some of which is currently implemented in ephysmanifest)
            varIdx = find(varNames == "area");
            if varIdx
                var = tbl.(varNames(varIdx));
                
                if iscell(var)
                    if iscell(var{1}) % case of: cell string array with empty last value (ephys session case)
                        
                        % convert to cell string array
                        assert(all(cellfun(@(x)isempty(x{end}),var))); % all the cell string arrays end with an empty double array, for reason TBD
                        tbl.(varNames(varIdx)) = cellfun(@(x)join(string(x(1:end-1))',"; "),var); % convert each cell element to string, skipping the ending empty double array
                        
                    else % case of: 'almost' cell string arrays, w/ empty values represented as numerics
                        assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),var)))));
                        
                        var2 = var;
                        [var2{cellfun(@(x)~ischar(x), var)}] = deal('');
                        tbl.(varNames(varIdx)) = categorical(string(var2)); % strings are scalars in this case --> convert to categorical
                    end
                end
            end   
            
            %%  Handle _structure_id variable cases
                              
            areaIDVar = varNames(varNames.endsWith("_structure_id")); % "structure" variables mean a brain area 
            
            if ~isempty(areaIDVar)
            
                % Case of tandem struct variable
                areaStructVar = varNames(varNames.endsWith("_structure"));
                
                if  ~isempty(areaStructVar) % there's an ID variable and a struct variable --> no acronym decoding done yet

                    assert(isstruct(tbl.(areaStructVar)) && isfield(tbl.(areaStructVar),'acronym'));
                                        
                    areaStrVar = replace(areaIDVar,"id","acronym");
                                        
                    %idVals = tbl.(areaIDVar);
                    tbl.(areaIDVar) = categorical(string({tbl.(areaStructVar).acronym}')); % "structure" vars are scalar-valued, so can convert to categorical
                    tbl = renamevars(tbl,areaIDVar,areaStrVar);
                end
                
                % Case of tandem acronym var
                areaStrVar = varNames(varNames.endsWith("_structure_acronym"));
                                
                if ~isempty(areaStrVar)
                    areaStrVarVals = tbl.(areaStrVar);
                    areaStrVarVals(isundefined(areaStrVarVals)) = [];
                    
                    assert(numel(unique(areaStrVarVals)) == numel(setdiff(unique(tbl.(areaIDVar)),0))) % sanity-check for correspondence before removing ID var
                    tbl = removevars(tbl,areaIDVar);
%                     else
%                         % no-op TODO: handle cases of undefined values (e.g. channels table) which should also work since both id & acronym would be 'null' case
%                     end
                end
            end
            
            %% Initialize refined variable lists (names, values)
            refinedVars = setdiff(string(tbl.Properties.VariableNames),[redundantVarNames containsDirVars],"stable");

            %% Reorder columns
            
            %TODO: reimplement the mapping of string patterns to variable types programatically as a containers.Map
            
            % Identify variables containing string patterns identifying the kind of item info
            
            IDVar = refinedVars(refinedVars.matches("id")); % the Item ID will be shown first
            experIDVars = refinedVars(refinedVars.endsWith("experiment_id")); % experiments are "virtual" items; these will be ordered towards end
            specimenIDVars = refinedVars(refinedVars.endsWith("specimen_id")); % specimen structures are part of compound types at end; these will be ordered just before
            %structIDVars = refinedVars(refinedVars.endsWith("structure_id")); % specimen structures are part of compound types at end; these will be ordered just before
            
            linkedItemIDVars = setdiff(refinedVars(refinedVars.endsWith("id")), [IDVar experIDVars specimenIDVars]);
                
            countVars = refinedVars(refinedVars.contains("count")); % counts of linked items
            dateVars = refinedVars(refinedVars.contains("date"));
            typeVars = refinedVars(refinedVars.contains("_type")); % specifies some type of the item, i.e. a categorical
            genotypeVars = refinedVars(refinedVars.endsWith(["genotype" "cre_line", "driver_line", "reporter_line"])); % specifies the various transgenic lines crossed, can become a long string
            stimVars = refinedVars(refinedVars.contains("stimulus")); % specifies which named external stimulus set is applied for the item, i.e. a categorical           
            
            structVars = refinedVars(refinedVars.contains("structure")); %& ~refinedVars.endsWith("id")); % lists out brain structure(s) associated to the item in a stringish way
            longStructVars = string();
            shortStructVars = string();
            for var = structVars
                if iscategorical(tbl.(var))
                    shortStructVars = [shortStructVars var]; %#ok<AGROW>
                elseif isstring(tbl.(var)) 
                    if mean(strlength(tbl.(var))) > 10
                        longStructVars = [longStructVars var]; %#ok<AGROW>
                    else
                        shortStructVars = [shortStructVars var]; %#ok<AGROW>
                    end
                else
                    % no-op (for the brain structure id & struct vars in ophys)
                end
            end                                               
                        
            nameVars = refinedVars(refinedVars.matches("name")); 
            longNameVars = string();
            shortNameVars = string();
            for var = nameVars
                if iscategorical(tbl.(var))
                    shortNameVars = [shortNameVars var]; %#ok<AGROW>
                elseif isstring(tbl.(var)) || iscellstr(tbl.(var))
                    if mean(strlength(tbl.(var))) > 10
                        longNameVars = [longNameVars var]; %#ok<AGROW>
                    else
                        shortNameVars = [shortNameVars var]; %#ok<AGROW>
                    end
                else
                    assert(false);
                end
            end                                               
            
            reorderedVars = [IDVar linkedItemIDVars experIDVars specimenIDVars  countVars dateVars typeVars genotypeVars stimVars longNameVars shortNameVars shortStructVars longStructVars];
            
            % Identify any remaining variables with compound data
            firstRowVals = table2cell(tbl(1,:));
            compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
            compoundVars = setdiff(refinedVars(compoundVarIdxs), reorderedVars);
            
            % Create new column order
            reorderedVars = [reorderedVars compoundVars];
            newVarOrder = [IDVar  linkedItemIDVars countVars  shortNameVars typeVars stimVars shortStructVars setdiff(refinedVars,reorderedVars,"sort")  genotypeVars  longStructVars  experIDVars dateVars longNameVars specimenIDVars compoundVars];
            newVarOrder(newVarOrder.strlength == 0) = [];
            
            % Do reorder in one step
            tbl = tbl(:,newVarOrder);
        end

        function tbl = renameTableVariables(tbl)
        % renameTableVariables - Rename table variables

            import bot.internal.metadata.utility.itemTableVariableRenameMap

            nameMap = itemTableVariableRenameMap();
            tableVarNames = tbl.Properties.VariableNames;

            for iName = nameMap.keys()'
                isMatched = strcmp(tableVarNames, iName);
                if any(isMatched)
                    newName = nameMap(iName);
                    tbl.Properties.VariableNames(isMatched) = string(newName);
                end
            end
        end
    
        function T = recastTableVariables(T)
        % recastTableVariables - Change types of table variables

            import bot.internal.metadata.utility.itemTableTypeConversionMap

            % Load a map of conversion functions for variable names.
            recastFcnMap = itemTableTypeConversionMap();
            
            varNames = string(T.Properties.VariableNames);

            for iVarName = varNames
                if isKey(recastFcnMap, iVarName)
                    recastFcn = recastFcnMap(iVarName);
                    try
                        T.(iVarName) = recastFcn( T.(iVarName) );
                    catch ME
                        warning(ME.identifier, 'Could not convert "%s". Cause by: %s', iVarName, ME.message)
                    end
                end
            end
        end
    end

end
