classdef Item < handle & matlab.mixin.CustomDisplay
    
   %% PUBLIC INTERFACE
   properties (SetAccess = protected)
      info;         % Struct containing info about this item
      id;               % ID of this item
   end   
   
   %% SUBCLASS INTERFACE
   
   % Properties for Item construction
   properties (Abstract, Hidden, Constant)
        ITEM_MANIFEST (1,1) struct
        ITEM_MANIFEST_TABLE_NAME (1,1) string
    end
   
   % Properties for matlab.mixin.CustomDisplay superclass implementation 
   properties (Abstract, Access = protected)
       CORE_PROPERTIES_EXTENDED (1,:) string 
       LINKED_ITEM_PROPERTIES (1,:) string        
   end
   
   %% SUPERCLASS IMPLEMENTATION (matlab.mixin.CustomDisplay)
   
   properties (Constant, GetAccess = protected)
       CORE_PROPERTIES = ["info" "id"];                     
   end    
   
   methods (Access = protected)
          function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else                
                
                % Core properties
                groups(1) = matlab.mixin.util.PropertyGroup([obj.CORE_PROPERTIES obj.CORE_PROPERTIES_EXTENDED]);
                groups(2) = matlab.mixin.util.PropertyGroup(obj.LINKED_ITEM_PROPERTIES, 'Linked Items');               
            end
        end
       
   end   

   
   %% DEVEOPER INTERFACE - Methods
   
   % CONSTRUCTOR
   
   methods 
       
       function obj = Item(id)
                      
           if istable(id)
               assert(size(id, 1) == 1, 'BOT:Usage', 'Only a single table row may be provided.')
               
           else           
               % Handle array construction case
               for idx = numel(id):-1:1
                   obj(idx) = bot.item.abstract.Item(id(idx));
               end
               
               return;
           end
           
           znstConstructScalarItem(id);
           
           return;
           
           function znstConstructScalarItem(id)
               % - Check usage
               if istable(id)
                   assert(size(id, 1) == 1, 'BOT:Usage', 'Only a single table row may be provided.')
                   table_row = id;
               else
                   assert(isnumeric(id), 'BOT:Usage', '`nID` must be an integer ID.');
                   id = uint32(round(id));
                   
                   % - Locate an ID in the manifest table
                   manifest_table = obj.ITEM_MANIFEST.(obj.ITEM_MANIFEST_TABLE_NAME);
                   matching_row = manifest_table.id == id;
                   if ~any(matching_row)
                       error('BOT:Usage', 'Item not found in %s manifest.', type);
                   end
                   
                   table_row = manifest_table(matching_row, :);
               end
               
               % - Assign the table data to the metadata structure
               obj.info = table2struct(table_row);
               obj.id = obj.info.id;
           end
       end
      
       
   end              
   
   
end