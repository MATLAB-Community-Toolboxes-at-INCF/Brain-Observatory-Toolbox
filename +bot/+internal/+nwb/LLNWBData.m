classdef (Abstract) LLNWBData < bot.internal.behavior.LinkedFile
% NWBData - Abstract class providing an object interface to data in NWB file
%
%   Note: This class uses primarily low-level H5 library functions.
%
%   Subclasses of this class should define properties representing datasets
%   in an NWB file, and a map to bind property names to group/dataset names
%   within the NWB file.
%
%   This class subclasses the OnDemandProps mixin, so once data is loaded
%   from file, it will stay in memory.

%   Todo:
%       Make NWBData / NWB File class, and make nwb readers (most of the
%       functionality in this class should be in a reader class) Note: the
%       reader class should be assigned on a property of the NWBData class.


    properties (Abstract, Access = protected)
        % PropertyToDatasetMap - Dictionary with mapping from property name 
        % to dataset name/path in h5 file
        PropertyToDatasetMap dictionary

        % PropertyToDatasetMap - Dictionary with mapping from property name
        % to the name of a data processing function. The function should be
        % a method of the defining class and it should accept two input 
        % arguments, an object of the class and a data value (which is 
        % read using the PropertyToDatasetMap)
        PropertyProcessingFcnMap dictionary
    end

    properties (Access = private, Dependent)
        H5FileID
    end

    properties (Access = private)
        H5FileID_
    end

    methods % Constructor
        function obj = LLNWBData(filePath, nickName)
            obj = obj@bot.internal.behavior.LinkedFile(filePath, nickName)
        end

        function delete(obj)
            if ~isempty(obj.H5FileID_)
                H5F.close(obj.H5FileID_)
            end
        end
    end

    methods % Public
        function data = fetchData(obj, propertyName)
        %fetchData - Fetch data for given property
            accessFcn = @(name) obj.getProcessedData(propertyName);
            data = obj.fetch_cached(propertyName, accessFcn);
        end
    end

    methods % Get
        function h5FileID = get.H5FileID(obj)
            if isempty(obj.H5FileID_)            
                obj.H5FileID_ = H5F.open(obj.FilePath);
            end
            h5FileID = obj.H5FileID_;
        end
    end
    
    methods (Access = private)
        function data = getProcessedData(obj, propertyName)
            % Load dataset from file
            try
                data = obj.loadDataset(propertyName);
            catch MECause
                ME = MException('BOT:FailedToLoadDataset', ...
                    sprintf('Could not load dataset for property "%s"', propertyName));
                ME = ME.addCause(MECause);
                throw(ME)
            end

            % Process data / use custom reader functions
            if isKey(obj.PropertyProcessingFcnMap, propertyName)
                processingFcn = obj.PropertyProcessingFcnMap(propertyName);
                data = feval(processingFcn, obj, data);
            end

            % Update on-demand property
            obj.(propertyName).OnDemandState = 'in-memory';
            obj.(propertyName) = obj.(propertyName).updateFromData(data);
        end
    end

    methods (Access = protected)
        
        function parseFile(obj)
        % parseFile - Get information about data properties from file.

            propertyNames = obj.PropertyToDatasetMap.keys();
            propertyNames = reshape(propertyNames, 1, []);

            for thisPropName = propertyNames

                h5PathName = char( obj.PropertyToDatasetMap(thisPropName) );
                [groupName, datasetName] = obj.splitH5PathName(h5PathName);
                                         
                if contains(groupName, '*')
                    groupName = obj.resolveGroupNameWithWildcard(groupName);
                    newPathName = h5path(groupName, datasetName);
                    obj.PropertyToDatasetMap(thisPropName) = newPathName;
                end

                % Initialize on-demand property if property is empty
                if isempty(obj.(thisPropName))
                    obj.(thisPropName) = bot.internal.OnDemandProperty();
                end

                % Continue to next if group name is empty.
                if isempty(groupName) %|| ~obj.existsGroup(groupName)
                    obj.(thisPropName).OnDemandState = 'unavailable';
                    continue
                end

                [neurodataType, dataType, dataSize] = ...
                    obj.parseDataset(groupName, datasetName);
            
                if ~isempty(neurodataType)
                    obj.(thisPropName).NeuroDataType = neurodataType;
                end
                if ~isempty(dataType)
                    obj.(thisPropName).DataType = dataType;
                end
                if ~isempty(dataSize)
                    obj.(thisPropName).DataSize = dataSize;
                end
                
                if all(cellfun(@(c) isempty(c), {neurodataType, dataType, dataSize}))
                    obj.(thisPropName).OnDemandState = 'unavailable';
                else
                    obj.(thisPropName).OnDemandState = 'on-demand';
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
        
        function [neurodataType, dataType, dataSize] = parseDataset(obj, groupName, datasetName)
            
            [neurodataType, dataType, dataSize] = deal([]);
            
            try
                % Get group info
                gid = H5G.open(obj.H5FileID, groupName);
    
                % Check for neurodata type attribute
                neurodataType = obj.getNeurodataType(gid);
                
                %dataType = obj.getDataType(gid, datasetName);
                [dataSize, dataType] = obj.getDatasetSize(gid, datasetName);

                H5G.close(gid)
            catch ME
                % Todo: collect error message...
            end
        end
    
        function data = loadDataset(obj, propertyName)
            
            h5PathName = obj.PropertyToDatasetMap(propertyName);
            [groupName, datasetName] = obj.splitH5PathName(h5PathName);

            groupID = H5G.open(obj.H5FileID, groupName);
            datasetID = H5D.open(groupID, datasetName);
            data = H5D.read(datasetID);
            H5D.close(datasetID)

            if ismissing( obj.(propertyName).NeuroDataType )
                neurodataType = obj.getNeurodataType(groupID);
                obj.(propertyName).NeuroDataType = neurodataType;
            end

            switch obj.(propertyName).NeuroDataType
            
                case {'TimeSeries', 'RoiResponseSeries', 'IndexSeries', 'OphysEventDetection', 'EllipseSeries'}
                    
                    tsDatasetID = H5D.open(groupID, 'timestamps');
                    timestamps = H5D.read(tsDatasetID);
                    H5D.close(tsDatasetID)

                    %timestamps = h5read(obj.FilePath, [groupName, '/timestamps']);
                    timestamps = obj.convertToDurationVector(timestamps, groupName);

                    if ismatrix(data) && ~isvector(data) % Is this general?
                        numTimesteps = numel(timestamps);
                        if size(data, 2) == numTimesteps
                            data = data';
                        end
                    end
                    
                    data = timetable(timestamps, data, 'VariableNames', propertyName);
                
                 otherwise
                    % Pass for now 
            end
            
            H5G.close(groupID)

            if strcmp(datasetName, 'timestamps')
                data = obj.convertToDurationVector(data, groupName);
            end
            
            obj.(propertyName).OnDemandState = 'in-memory';
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
                    %warning('No match found for given wildcard group "%s"', tmpGroupName)
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

        function [groupName, datasetName] = splitH5PathName(obj, h5PathName)
            h5sep = '/';
            splitPathName = strsplit(h5PathName, h5sep);
            
            datasetName = splitPathName{end};
            groupName = strjoin(splitPathName(1:end-1), h5sep);

            datasetName = char(datasetName);
            groupName = char(groupName);
        end
    
        function timeseriesUnit = getTimeSeriesUnit(obj, groupName)
            groupName = h5path(groupName, 'timestamps');
            % Todo: use H5A
            timeseriesUnit = h5readatt(obj.FilePath, groupName, 'unit');
        end

        function time = convertToDurationVector(obj, time, groupName)
            
            timestampsUnit = obj.getTimeSeriesUnit(groupName);
            
            if strcmpi(timestampsUnit, 'seconds')
                time = seconds(time);
            else
                error('Time unit %s is not implemented yet', timestampsUnit)
            end
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

%             if H5L.exists(gid, attributeName, 'H5P_DEFAULT')
%             % The subgroup exists, so you can open it.
%                 aid = H5A.open(group_id, attributeName);
%             else
%                 % The subgroup does not exist.
%                 disp(['Attribute "', attributeName, '" does not exist.']);
%             end
        end
    
        function dataType = getDataType(groupID, datasetName)
            datasetID = H5D.open(groupID, datasetName);
            typeId = H5D.get_type(datasetID);
            dataType = bot.external.matnwb.io.getMatType(typeId);
            H5T.close(typeId);
            H5D.close(datasetID)
        end

        function [dataSize, dataType] = getDatasetSize(groupID, datasetName)
            %Todo?: Get dataType in separate function 

            datasetNames = bot.internal.nwb.LLNWBData.listLinkNames(groupID);

            isMatch = strcmp(datasetNames, datasetName);

            if any(isMatch)
                % Get data size:
                datasetID = H5D.open(groupID, datasetName);
                spaceID = H5D.get_space(datasetID);
                [~, h5Dims, ~] = H5S.get_simple_extent_dims(spaceID);
                %dataSize = fliplr(h5Dims);
                dataSize = h5Dims;
                H5S.close(spaceID);

                % Get data type:
                typeId = H5D.get_type(datasetID);
                dataType = bot.external.matnwb.io.getMatType(typeId);
                H5T.close(typeId);

                H5D.close(datasetID)
            else
                error('No dataset named "%s" in group "%s".', datasetName, groupInfo.Name)
            end

            if numel(dataSize) == 1
                dataSize = [dataSize, 1];
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