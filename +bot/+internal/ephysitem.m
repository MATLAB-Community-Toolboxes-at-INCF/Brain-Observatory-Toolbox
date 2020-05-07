classdef ephysitem < handle
   properties (SetAccess = private)
      sMetadata;
   end
   
   methods (Access = protected)
      function item = check_and_assign_metadata(item, nID, tManifestTable, strType, varargin)
         % - Check usage
         assert(isnumeric(nID), 'BOT:Usage', '`nID` must be an integer ID.');
         nID = uint32(round(nID));
         
         % - Locate an ID in the manifest table
         vbTableRow = tManifestTable.id == nID;
         if ~any(vbTableRow)
            error('BOT:Usage', 'Item not found in %s manifest.', strType);
         end
         
         tItem = tManifestTable(vbTableRow, :);
         
         % - Assign the table data to the metadata structure
         item.sMetadata = table2struct(tItem);
      end
   end   
end