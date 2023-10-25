classdef (Abstract) LLNWBData <  bot.item.internal.mixin.OnDemandProps
% NWBData - Abstract class providing an object interface to data in NWB file
%
%   Subclasses of this class should define properties representing datasets
%   in an NWB file, and a map to bind property names to group/dataset names
%   within the NWB file.
%
%   This class subclasses the OnDemandProps mixin, so once data is loaded
%   from file, it will stay in memory.

%   Todo: add support for adding processorFcn function handle on fetch. 

    properties (Abstract, Hidden)
        Name
    end

    properties (Abstract, Access = protected)
        PropertyGroupMapping
    end

    properties (SetAccess = private, Hidden)
        FilePath
    end

    properties (Access = private)
        H5FileID
    end

    methods % Constructor
    
        function obj = LLNWBData(filePath)
            obj.FilePath = filePath;
        
            try 
                obj.parseFile()
            catch ME
                throw(ME)
                %pass (File not available)
            end
            
            obj.ON_DEMAND_PROPERTIES = properties(obj);
        end

        function delete(obj)
            if ~isempty(obj.H5FileID)
                H5F.close(obj.H5FileID)
            end
        end
    end

    methods % Public

        function data = fetchData(obj, propertyName)
        %fetchData - Fetch data for given property
            
            if isempty(obj.H5FileID)
                try
                    obj.parseFile()
                catch ME
                    throw(ME)
                    %pass (File not available)
                end
            end
            
            accessFcn = @(name) obj.loadDataset(propertyName);
            data = obj.fetch_cached(propertyName, accessFcn);
        end
    end

    methods (Access = protected)
        
        function parseFile(obj)
        % parseFile - Get information about data properties from file.

            obj.H5FileID = H5F.open(obj.FilePath); % Question : remove?

            fields = fieldnames(obj.PropertyGroupMapping);

            for i = 1:numel(fields)
                thisPropName = fields{i};

                [groupName, datasetName] = obj.getMappedNamesForProperty(thisPropName);
                         
                if contains(groupName, '*')
                    groupName = obj.resolveGroupNameWithWildcard(groupName);
                    obj.updateGroupNameForProperty(thisPropName, groupName)
                end

                % Todo: If group name is empty, need to add an unavailable
                % ondemand property.

                if isempty(datasetName)
                    [neurodataType, dataSize] = obj.parseGroup(groupName);
                else
                    [neurodataType, dataSize] = obj.parseDataset(groupName, datasetName);
                end

                if ~isempty(neurodataType)
                    obj.(thisPropName) = bot.internal.OnDemandProperty(dataSize, neurodataType, 'on-demand');
                else
                    obj.(thisPropName) = bot.internal.OnDemandProperty('N/A', '', 'missing');
                end
            end
        end

        function tf = existsGroup(obj, groupName)
            
            groupNameSplit = strsplit(groupName, '/');

            for i = 2:numel(groupNameSplit)
                tempGroupName = h5path(groupNameSplit{1:i});
                tf = H5L.exists(obj.H5FileID, tempGroupName, []);
                if ~tf; break; end
            end
        end

        function [neurodataType, dataSize] = parseGroup(obj, groupName)
            
            [neurodataType, dataSize] = deal([]);

% % %             if ~obj.existsGroup(groupName)
% % %                 return
% % %             end
            
            try

                gid = H5G.open(obj.H5FileID, groupName);
                
                % Check for attributes
                neurodataType = obj.getNeurodataType(gid);
    
                dataSize = obj.getDataSize(gid, neurodataType);
    
                H5G.close(gid)
            end
        end

        function [neurodataType, dataSize] = parseDataset(obj, groupName, datasetName)
            
            [neurodataType, dataSize] = deal([]);
% % %             if ~obj.existsGroup(groupName)
% % %                 return
% % %             end

            try
                % Get group info
                gid = H5G.open(obj.H5FileID, groupName);
    
                % Check for neurodata type attribute
                neurodataType = obj.getNeurodataType(gid);
    
                dataSize = obj.getDatasetSize(gid, datasetName);
                H5G.close(gid)
            end
        end
    
        function data = loadDataset(obj, propertyName)
            
            [groupName, datasetName] = obj.getMappedNamesForProperty(propertyName);
            
            switch obj.(propertyName).DataType
                
                case {'TimeSeries', 'RoiResponseSeries', 'IndexSeries'}
                    data = h5read(obj.FilePath, [groupName, '/data']);
                    time = h5read(obj.FilePath, [groupName, '/timestamps']);
                
                    if ismatrix(data) % Is this general?
                        data = data'; 
                    end
                    
                    timestampsUnit = obj.getTimeSeriesUnit(groupName);
                    
                    if strcmp(timestampsUnit, 'seconds')
                        data = timetable(seconds(time), data, 'VariableNames', {'Data'});
                    else
                        error('Time unit %s is not implemented yet', timestampsUnit)
                    end
                otherwise
                    if ~isempty(datasetName)
                        data = h5read(obj.FilePath, [groupName, ['/',datasetName]]);
                    else
                        warning('Data loading for %s is not supported yet', propertyName)
                    end
            end

            obj.(propertyName).OnDemandState = '';
        end

        function groupName = resolveGroupNameWithWildcard(obj, groupName)
        % resolveGroupNameWithWildcard - Resolve group names with wildcard 
        %
        %   Note: Useful if group names have "variable" names

            groupSplit = strsplit(groupName, '/');
            
            hasWildcard = cellfun(@(c) contains(c, '*'), groupSplit);

            % Find group with wildcard
            firstWildcardIdx = find(hasWildcard, 1, "first");
            
            rootGroupName = h5path(groupSplit{1:firstWildcardIdx-1});
            gid = H5G.open(obj.H5FileID, rootGroupName);
            
            numGroups = numel(groupSplit);
            
            for i = firstWildcardIdx:numGroups
                
                tmpGroupPath = h5path(groupSplit{1:i});
                tmpGroupName = groupSplit{i};


                if ~hasWildcard(i)
                    H5G.close(gid)
                    gid = h5info(obj.FilePath, tmpGroupPath);
                    continue
                end

                subGroupNames = bot.internal.nwb.LLNWBData.listLinkNames(gid);

                matchInd = regexp(subGroupNames, tmpGroupName);
                hasMatch = cellfun(@(c) ~isempty(c), matchInd);

                if ~any(hasMatch)
                    warning('No match found for given wildcard group "%s"', tmpGroupName)
                    groupName = '';
                    return
                else
                    if sum(hasMatch) > 1
                        warning('Multiple groups matched the given wildcard group "%s"', tmpGroupName)
                        groupName = '';
                        return
                    else
                        matchedGroupName = subGroupNames{hasMatch};
                        groupSplit{i} = matchedGroupName;
                    end
                end
            end
            
            % Return the (hopefully) resolved group name
            groupName = h5path(groupSplit{:});
            H5G.close(gid)
        end

        function [groupName, datasetName] = getMappedNamesForProperty(obj, propertyName)
        
            mappedNames = obj.PropertyGroupMapping.(propertyName);
            if isa(mappedNames, 'cell')
                groupName = mappedNames{1};
                datasetName = mappedNames{2};
            else
                groupName = mappedNames;
                datasetName = '';
            end
        end
        
        function updateGroupNameForProperty(obj, propertyName, groupName)
        % updateGroupNameForProperty - Update PropertyGroupMapping
        %
        %   Note: This function is useful if a group name had wildcards
        %   which has been resolved.
        
            mappedNames = obj.PropertyGroupMapping.(propertyName);
            if isa(mappedNames, 'cell')
                mappedNames{1} = groupName;
            else
                mappedNames = groupName;
            end
            obj.PropertyGroupMapping.(propertyName) = mappedNames;
        end

        function dataSize = getDataSize(obj, groupID, neurodataType)
            
            switch neurodataType
                case {'TimeSeries', 'RoiResponseSeries', 'IndexSeries'}
                    dataSize = obj.getDatasetSize(groupID, 'data');
                case ''
                
                otherwise
                    dataSize = 'N/A';
                    disp('NotImplementedYet')
            end
            %groupInfo.Datasets.Name

        end
    
        function timeseriesUnit = getTimeSeriesUnit(obj, groupName)
            groupName = h5path(groupName, 'timestamps');
            timeseriesUnit = h5readatt(obj.FilePath, groupName, 'unit');
        end
    
    end

    methods (Static, Access=private)
        
        function tf = hasNeurodataTypeAttribute(groupInfo)
        %hasNeurodataTypeAttribute Check if neurodata type is in attributes
        % groupInfo - struct returned from h5info
            
            tf = false;

            if ~isempty(groupInfo.Attributes)
                attributeNames = {groupInfo.Attributes.Name};
                tf = any(strcmp(attributeNames, 'neurodata_type'));
            end
        end
        
        function neurodataType = getNeurodataType(gid)
                     
            attributeName = 'neurodata_type';
            %bot.internal.nwb.LLNWBData.listAttributeNames(gid)
            try
                aid = H5A.open(gid, attributeName);
                neurodataType = H5A.read(aid);
                H5A.close(aid)
            catch
                neurodataType = 'N/A';
            end

            %fcn = @(a,b) disp(b)


%             if H5L.exists(gid, attributeName, 'H5P_DEFAULT')
%             % The subgroup exists, so you can open it.
%                 aid = H5A.open(group_id, attributeName);
%             else
%                 % The subgroup does not exist.
%                 disp(['Attribute "', attributeName, '" does not exist.']);
%             end

            if strcmp(neurodataType, 'Images')
                neurodataType = 'Image';
            end
        end
    
        function dataSize = getDatasetSize(groupID, datasetName)
                        
            datasetNames = bot.internal.nwb.LLNWBData.listLinkNames(groupID);

            isMatch = strcmp(datasetNames, datasetName);

            if any(isMatch)
                %dataSize = groupInfo.Datasets(isMatch).Dataspace.Size;
                
                datasetID = H5D.open(groupID, datasetName);
                spaceID = H5D.get_space(datasetID);
                [~, h5Dims, ~] = H5S.get_simple_extent_dims(spaceID);
                dataSize = fliplr(h5Dims);
                H5S.close(spaceID);
                H5D.close(datasetID)
            else
                error('No dataset named "%s" in group "%s".', datasetName, groupInfo.Name)
            end

            if numel(dataSize) == 1
                dataSize = [1, dataSize];
            end
        end

        function attributeNameList = listAttributeNames(groupId)
                
            function [status, cData] = collectAttributeNames(id, name, info, cData)
                cData{end+1} = name;
                status=0;
            end

            [~, ~, cdataOut] = H5A.iterate(groupId, "H5_INDEX_NAME", "H5_ITER_INC", 0, @collectAttributeNames, {});
            attributeNameList = cdataOut;
        end
    
        function linkNameList = listLinkNames(groupId)
                
            function [status, cData] = collectLinkNames(id, name, cData)
                cData{end+1} = name;
                status=0;
            end

            [~, ~, cdataOut] = H5L.iterate(groupId, "H5_INDEX_NAME", "H5_ITER_INC", 0, @collectLinkNames, {});
            linkNameList = cdataOut;
        end
    
    
    end
end

function pathStr = h5path(varargin)
    pathStr = strjoin(varargin, '/');
    if isempty(pathStr);pathStr='/'; end
end

function status = disp_attr_name(id, name)
    disp(name)
    status = 0;
end