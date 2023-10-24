classdef (Abstract) NWBData <  bot.item.internal.mixin.OnDemandProps
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
    
        function obj = NWBData(filePath)
            obj.FilePath = filePath;
            
            if isfile(filePath)
                obj.parseFile()
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
                obj.parseFile()
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
                    obj.parseGroup(thisPropName, groupName)
                else
                    obj.parseDataset(thisPropName, groupName, datasetName)
                end
            end
        end

        function parseGroup(obj, propName, groupName)
            
            % Get group info
            s = h5info(obj.FilePath, groupName);
        
            % Check for attributes
            neurodataType = obj.getNeurodataType(s);

            dataSize = obj.getDataSize(s, neurodataType);
            obj.(propName) = bot.internal.OnDemandProperty(dataSize, neurodataType, 'on-demand');
        end

        function parseDataset(obj, propName, groupName, datasetName)
            
            % Get group info
            s = h5info(obj.FilePath, groupName);
            
            % Check for neurodata type attribute
            neurodataType = obj.getNeurodataType(s);

            dataSize = obj.getDatasetSize(s, datasetName);
            obj.(propName) = bot.internal.OnDemandProperty(dataSize, neurodataType, 'on-demand');
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
            s = h5info(obj.FilePath, rootGroupName);

            numGroups = numel(groupSplit);
            
            for i = firstWildcardIdx:numGroups
                
                tmpGroupName = h5path(groupSplit{1:i});

                if ~hasWildcard(i)
                    s = h5info(obj.FilePath, tmpGroupName);
                    continue
                end
                
                subGroupNames = {s.Groups.Name};

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
                        matchedGroupSplit = strsplit(matchedGroupName, '/');
                        groupSplit{i} = matchedGroupSplit{i};
                        s = s.Groups(hasMatch);
                    end
                end
            end
            
            % Return the (hopefully) resolved group name
            groupName = h5path(groupSplit{:});
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

        function dataSize = getDataSize(obj, groupInfo, neurodataType)
            
            switch neurodataType
                case {'TimeSeries', 'RoiResponseSeries', 'IndexSeries'}
                    dataSize = obj.getDatasetSize(groupInfo, 'data');
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
        
        function neurodataType = getNeurodataType(groupInfo)
            neurodataType = '';
            if ~isempty(groupInfo.Attributes)
                attributeNames = {groupInfo.Attributes.Name};
                isMatch = strcmp(attributeNames, 'neurodata_type');
            
                if any(isMatch)
                    neurodataType = groupInfo.Attributes(isMatch).Value;
                end
            end

            if strcmp(neurodataType, 'Images')
                neurodataType = 'Image';
            end
        end
    
        function dataSize = getDatasetSize(groupInfo, datasetName)
                        
            datasetNames = {groupInfo.Datasets.Name};
            isMatch = strcmp(datasetNames, datasetName);

            if any(isMatch)
                dataSize = groupInfo.Datasets(isMatch).Dataspace.Size;
            else
                error('No dataset named "%s" in group "%s".', datasetName, groupInfo.Name)
            end

            if numel(dataSize) == 1
                dataSize = [1, dataSize];
            end
        end
    end
end

function pathStr = h5path(varargin)
    pathStr = strjoin(varargin, '/');
    if isempty(pathStr);pathStr='/'; end
end
