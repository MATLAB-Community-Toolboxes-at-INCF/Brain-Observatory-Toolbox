function sData = struct_from_attributes(strFile, strNWBKey)

% struct_from_attributes - FUNCTION 


if nargin < 2
   help bot.nwb.table_from_datasets;
   error('BOT:Usage', 'Incorrect usage.');
end

%% - Read the data from the NWB file

% - Get the root key form the NWB file
sRootKey = h5info(strFile, strNWBKey);

% - Read each attribute into a variable
cstrVariables = string({sRootKey.Attributes.Name});
cData = {sRootKey.Attributes.Value};

sData = cell2struct(cData(:), cstrVariables);

