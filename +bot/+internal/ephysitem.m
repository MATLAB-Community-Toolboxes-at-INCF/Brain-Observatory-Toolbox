classdef ephysitem < handle
   properties (SetAccess = protected)
      sMetadata;
      sPropertyCache;
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
   
   methods (Access = protected)
      function oData = get_cached(self, strProperty, fhAccessFun)
         % - Check for cached property
         if ~isfield(self.sPropertyCache, strProperty)
            % - Use the access function
            self.sPropertyCache.(strProperty) = fhAccessFun();
         end
         
         % - Return the cached property
         oData = self.sPropertyCache.(strProperty);
      end
      
      function bInCache = in_cache(self, strProperty)
         bInCache = isfield(self.sPropertyCache, strProperty) && ~isempty(self.sPropertyCache.(strProperty));
      end
   end
end