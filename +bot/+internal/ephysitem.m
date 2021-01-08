classdef ephysitem < handle
   properties (SetAccess = protected)
      metadata;
      id;
   end
   
   properties (Hidden = true)
      property_cache;
   end
   
   methods (Access = protected)
      function item = check_and_assign_metadata(item, id, manifest_table, type, varargin)
         % - Check usage
         if istable(id)
            assert(size(id, 1) == 1, 'BOT:Usage', 'Only a single table row may be provided.')
            table_row = id;
         else
            assert(isnumeric(id), 'BOT:Usage', '`nID` must be an integer ID.');
            id = uint32(round(id));
            
            % - Locate an ID in the manifest table
            matching_row = manifest_table.id == id;
            if ~any(matching_row)
               error('BOT:Usage', 'Item not found in %s manifest.', type);
            end
            
            table_row = manifest_table(matching_row, :);
         end
         
         % - Assign the table data to the metadata structure
         item.metadata = table2struct(table_row);
         item.id = item.metadata.id;
      end
   end   
   
   methods (Access = protected)
      function data = fetch_cached(self, property, fun_access)
         % fetch_cached - METHOD Access a cached property
         %
         % Usage: data = fetch_cached(self, property, fun_access)
         %
         % `property` is a string containing a property name. `fun_access`
         % is a function handle that returns the property data, if not
         % found in the cache. The property data will be returned from the
         % local property cache, or else inserted after calling
         % `fun_access`.
         %
         % `data` will be the cached property data.
         
         % - Check for cached property
         if ~isfield(self.property_cache, property)
            % - Use the access function
            self.property_cache.(property) = fun_access();
         end
         
         % - Return the cached property
         data = self.property_cache.(property);
      end
      
      function is_in_cache = in_cache(self, property)
         % in_cache — METHOD Test if a property value has been cached
         %
         % Usage: is_in_cache = in_cache(self, property)
         %
         % `property` is a string containing a property name. `is_in_cache`
         % will be `true` iff the property is present in the property
         % cache.
         is_in_cache = isfield(self.property_cache, property) && ~isempty(self.property_cache.(property));
      end
   end
end