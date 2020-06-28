function cmfData = deindex_table_from_datasets(strFile, strDataKey, strIndexKey)

% deindex_table_from_datasets - FUNCTION Read data plus a data index from an NWB file, and deindex the data table
%
% Usage: tTable = deindex_table_from_datasets(strFile, strDataKey, strIndexKey)
%
% `strFile` is an NWB file on disk.
% `strDataKey` identifies a wrapped dataset
% `strIndexKey` identifies an index into the wrapped dataset
%
% `cmfData` will be a MATLAB cell array, with one de-indexed data entry per element

if nargin < 2
   help bot.nwb.table_from_datasets;
   error('BOT:Usage', 'Incorrect usage.');
end

% - Read dataset
mfData = h5read(strFile, strDataKey);

if size(mfData, 1) > 1 && size(mfData, 2) == 1
   mfData = mfData';
end

mfData = permute(mfData, ndims(mfData):-1:1);

% - Read index

vnEnds = h5read(strFile, strIndexKey);
vnEnds = vnEnds(:);
vnStarts = [1; vnEnds(1:end-1)+1];

cnSize = num2cell(size(mfData));
cnSize{1} = [];

for nRow = numel(vnStarts):-1:1
   % - Get the data for this entry
   cmfData{nRow, 1} = mfData(vnStarts(nRow):vnEnds(nRow), :);
   cmfData{nRow, 1} = reshape(cmfData{nRow}, cnSize{:});
end