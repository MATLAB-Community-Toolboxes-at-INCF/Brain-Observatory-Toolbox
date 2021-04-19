function tTable = xarray_from_dataset(strFile, strNWBKey, strDataKey, strRowKey, strColKey)

% xarray_from_dataset - FUNCTION Read a dataset from an NWB file as an "xarray" table
%
% Usage: tTable = table_from_datasets(strFile, strNWBKey, strDataKey, strRowKey, strColKey)
%
% `strFile` is a string identifying an NWB file to read.
%
% `strNWBKey` is a key (directory) within the NWB file to access. e.g.
% '/intervals/epochs'. This must identify a node with in the NWB file that
% contains a number of HD5 datasets.
%

if nargin < 5
   help bot.internal.nwb.xarray_from_dataset;
   error('BOT:Usage', 'Incorrect usage.');
end


%% - Read the data from the NWB file

data = h5read(strFile, fullfile(strNWBKey, strDataKey))';
rowLabels = h5read(strFile, fullfile(strNWBKey, strRowKey));
colLabels = h5read(strFile, fullfile(strNWBKey, strColKey));

%% Convert to a table

tTable = array2table(data, 'VariableNames', colLabels, 'RowNames', rowLabels);

