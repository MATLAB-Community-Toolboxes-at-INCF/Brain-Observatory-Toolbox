function tTable = readDynamicTable(strFile, strNWBKey, cstrIgnoreKeys, cstrSelectKeys, bTestExist)

% readDynamicTable - FUNCTION Read a group of datasets from an NWB file as a table
%
% Usage: tTable = readDynamicTable(strFile, strNWBKey <, cstrIgnoreKeys, cstrSelectKeys, bTestExist>)
%
% `strFile` is a string identifying an NWB file to read.
%
% `strNWBKey` is a key (directory) within the NWB file to access. e.g.
% '/intervals/epochs'. This must identify a node with in the NWB file that
% contains a number of HD5 datasets. The datasets at this node will be read
% into a table, with one dataset per column of the table. The names of the
% datasets will be set as the variable names in the table.
%
% The optional argument `cstrSelectKeys` is a cell array of strings
% identifying datasets to return, if they exist in the NWB file. If `{}`,
% then all datasets in the NWB file will be returned.
%
% The optional argument `cstrIgnoreKeys` is a cell array of strings
% identifying datasets to skip, if they occur in the NWB file. If `{}`,
% then no datasets will be skipped.
%
% The optional argument `bTestExist` will raise an error if any variable in
% `cstrSelectKeys` does not exist in the NWB file. By default, no test is
% performed.
%
% `tTable` will be a MATLAB table, with one column per dataset in the NWB
% file.

% Note: this function is based of the bot.interna.nwb.table_from_datasets
% function but with three modifications:
%
%   1) Filtering of dataset to read occurs before, not after reading of
%      data
%   2) Ragged arrays are handled if they are detected. Ragged arrays are
%      column data where each cell can have a different size. Use a
%      modified version of 'deindex_table_from_datasets' to handle ragged
%      arrays.
%   3) Use low level H5 functions for opening groups and reading datasets.
%      This improves the performance in many cases, expecially for large 
%      boolean datasets. 

if nargin < 2
   help bot.internal.nwb.reader.readDynamicTable;
   error('BOT:Usage', 'Incorrect usage.');
end

if ~exist('bTestExist', 'var') || isempty(bTestExist)
   bTestExist = false;
end


%% - Find names of all datasets in the provided group

% - Get the information about a specified location (group) in the NWB file
sGroupInfo = h5info(strFile, strNWBKey);

% - Get list of all available dataset names
cstrVariables = {sGroupInfo.Datasets.Name};


%% - Choose datasets to select, and datasets to ignore

if ~exist('cstrSelectKeys', 'var') || isempty(cstrSelectKeys)
   % - By default return everything
   cstrSelectKeys = cstrVariables;
end

if ~exist('cstrIgnoreKeys', 'var') || isempty(cstrIgnoreKeys)
   cstrIgnoreKeys = {};
end

% - Filter dataset/column names
cstrSelectKeys = intersect(cstrSelectKeys, cstrVariables, 'stable');
cstrSelectKeys = setdiff(cstrSelectKeys, cstrIgnoreKeys, 'stable');

% - Test whether required variables are present
if bTestExist
   assert(all(ismember(cstrSelectKeys, cstrVariables)), ...
      'BOT:VariablesNotInNWB', ...
      'One or more variables in `cstrSelectKeys` was not found in the NWB file.');
end

H5FileID = H5F.open(strFile);
groupID = H5G.open(H5FileID, strNWBKey);

%% - Check for presence of ragged arrays. These need to be "deindexed"
[vectorIndexNames, raggedVectorDataNames] = findRaggedVectorData(cstrSelectKeys);

if ~isempty(raggedVectorDataNames)
    raggedData = cell(1, numel(raggedVectorDataNames));
    for i = 1:numel(raggedVectorDataNames)

        datasetID = H5D.open(groupID, raggedVectorDataNames{i});
        raggedData{i} = H5D.read(datasetID);
        H5D.close(datasetID)

        datasetID = H5D.open(groupID, vectorIndexNames{i});
        index = H5D.read(datasetID);
        H5D.close(datasetID)

        raggedData{i} = deindexRaggedVector(raggedData{i}, index);
    end
    cstrSelectKeys = setdiff(cstrSelectKeys, vectorIndexNames, 'stable');
    cstrSelectKeys = setdiff(cstrSelectKeys, raggedVectorDataNames, 'stable');
else
    raggedData = {};
end

%% - Read the remaining data from the NWB file

cData = {};
for nDSIndex = numel(cstrSelectKeys):-1:1
   strDSName = cstrSelectKeys{nDSIndex};
   
    %cData{nDSIndex} = h5read(strFile, string(strNWBKey) + "/" + string(strDSName)); % HDF5 paths are always forward slashes
   
    datasetID = H5D.open(groupID, strDSName);
    cData{nDSIndex} = H5D.read(datasetID);
    H5D.close(datasetID)

   if ismatrix(cData{nDSIndex}) && size(cData{nDSIndex}, 2) > 1
      cData{nDSIndex} = cData{nDSIndex}';
   elseif ~ismatrix(cData{nDSIndex})
       order = 1:ndims(cData{nDSIndex});
       order([1,end]) = order([end,1]);
       % Todo: Flip all dimensions, or reorder first and last?
       cData{nDSIndex} = permute(cData{nDSIndex}, order);
   end
end

H5G.close(groupID)
H5F.close(H5FileID)

cData = cat(2, cData, raggedData);
cstrVariables = cat(2, cstrSelectKeys, raggedVectorDataNames');

%% Convert to a table

tTable = table(cData{:}, 'VariableNames', cstrVariables);

end

function [vectorIndexNames, raggedVectorDataNames] = findRaggedVectorData(columnNames)
% Initialize an empty cell array to store pairs
    [vectorIndexNames, raggedVectorDataNames] = deal( {} );

    % Iterate through each string in the input vector
    for i = 1:length(columnNames)
        % Extract the current string
        currentString = columnNames{i};

        % Check if the current string ends with '_index'
        if endsWith(currentString, '_index')
            % Remove '_index' from the current string
            originalString = strrep(currentString, '_index', '');

            % Check if the original string is present in the input vector
            if any(strcmp(columnNames, originalString))
                % Add the pair to the cell array
                vectorIndexNames = [vectorIndexNames; {currentString}]; %#ok<AGROW>
                raggedVectorDataNames = [raggedVectorDataNames; {originalString}]; %#ok<AGROW>
            end
        end
    end
end


function [groupName, datasetName] = splitH5PathName(h5PathName)
    h5sep = '/';
    splitPathName = strsplit(h5PathName, h5sep);
    
    datasetName = splitPathName{end};
    groupName = strjoin(splitPathName(1:end-1), h5sep);

    datasetName = char(datasetName);
    groupName = char(groupName);
end

function cmfData = deindexRaggedVector(data, index)

    if size(data, 1) > 1 && size(data, 2) == 1
       data = data';
    end
    
    data = permute(data, ndims(data):-1:1);

    vnEnds = index(:);
    vnStarts = [1; vnEnds(1:end-1)+1];
    
    cnSize = num2cell(size(data));
    cnSize{1} = [];
    
    for nRow = numel(vnStarts):-1:1
       % - Get the data for this entry
       cmfData{nRow, 1} = data(vnStarts(nRow):vnEnds(nRow), :);
       cmfData{nRow, 1} = reshape(cmfData{nRow}, cnSize{:});
    end
end