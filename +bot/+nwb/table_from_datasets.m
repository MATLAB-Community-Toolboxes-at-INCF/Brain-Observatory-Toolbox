function tTable = table_from_datasets(strFile, strNWBKey, cstrIgnoreKeys, cstrSelectKeys, bTestExist)

% table_from_datasets - FUNCTION Read a group of datasets from an NWB file as a table
%
% Usage: tTable = table_from_datasets(strFile, strNWBKey <, cstrIgnoreKeys, cstrSelectKeys, bTestExist>)
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


if nargin < 2
   help bot.nwb.table_from_datasets;
   error('BOT:Usage', 'Incorrect usage.');
end

if ~exist('bTestExist', 'var') || isempty(bTestExist)
   bTestExist = false;
end

%% - Read the data from the NWB file

% - Get the root key form the NWB file
sRootKey = h5info(strFile, strNWBKey);

% - Read each dataset into a variable
cstrVariables = {sRootKey.Datasets.Name};

cData = {};
for nDSIndex = numel(cstrVariables):-1:1
   strDSName = cstrVariables{nDSIndex};
   
   cData{nDSIndex} = h5read(strFile, string(strNWBKey) + "/" + string(strDSName)); % HDF5 paths are always forward slashes
   
   if size(cData{nDSIndex}, 2) > 1
      cData{nDSIndex} = cData{nDSIndex}';
   end
end

%% - Choose keys to select, and ignore keys to ignore

if ~exist('cstrSelectKeys', 'var') || isempty(cstrSelectKeys)
   % - By defualt return everything
   cstrSelectKeys = cstrVariables;
end

if ~exist('cstrIgnoreKeys', 'var') || isempty(cstrIgnoreKeys)
   cstrIgnoreKeys = {};
end

% - Filter variables
vbSelectKeys = ismember(cstrVariables, cstrSelectKeys);
vbSelectKeys = vbSelectKeys & ~ismember(cstrVariables, cstrIgnoreKeys);

% - Test whether required variables are present
if bTestExist
   assert(~all(ismember(cstrSelectKeys, cstrVariables)), ...
      'BOT:VariablesNotInNWB', ...
      'One or more variables in `cstrSelectKeys` was not found in the NWB file.');
end

%% Convert to a table

tTable = table(cData{vbSelectKeys}, 'VariableNames', cstrVariables(vbSelectKeys));

