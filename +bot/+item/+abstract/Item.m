classdef Item < handle & matlab.mixin.CustomDisplay
    
   %% PUBLIC INTERFACE
   properties (SetAccess = protected)
      info;         % Struct containing info about this item
      id;               % ID of this item
   end   
   
   %% SUBCLASS INTERFACE
   
   % Properties for matlab.mixin.CustomDisplay superclass implementation 
   properties (Abstract, Access = protected)
       CORE_PROPERTIES_EXTENDED (1,:) string 
       LINKED_ITEM_PROPERTIES (1,:) string        
   end
   
   properties (SetAccess=protected, GetAccess = protected)
       ITEM_INFO_VALUE_PROPERTIES (1,:) string = string.empty();
       LINKED_ITEM_VALUE_PROPERTIES (1,:) string = string.empty();
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
                
                % Derived properties from Info
                if ~isempty(obj.ITEM_INFO_VALUE_PROPERTIES)
                    groups(end+1) = matlab.mixin.util.PropertyGroup(obj.ITEM_INFO_VALUE_PROPERTIES, 'Item Info Values');
                end
                
                % Linked item tables
                groups(end+1) = matlab.mixin.util.PropertyGroup(obj.LINKED_ITEM_PROPERTIES, 'Linked Items');
                
                % Derived properties from Linked Item Tables
                if ~isempty(obj.LINKED_ITEM_VALUE_PROPERTIES)
                    groups(end+1) = matlab.mixin.util.PropertyGroup(obj.LINKED_ITEM_VALUE_PROPERTIES, 'Linked Item Values');
                end
            end
        end
       
   end   

   
   %% METHODS - HIDDEN 
           
   
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
           item.info = table2struct(table_row);
           item.id = item.info.id;
       end       
       
   end
   
   %% METHODS - STATIC
   
   %    methods (Static)
   %
   %        function tbl = removeUnusedCategories(tbl)
   %        % TODO: Consider if it's a desired behavior for category lists to be narrowed for linked item tables? Or better to retain the "global" view of all available in the container session?
   %
   %            if isempty(tbl)
   %                return;
   %            end
   %
   %            varTypes = string(cellfun(@class,table2cell(tbl(1,:)),'UniformOutput',false));
   %            varNames = string(tbl.Properties.VariableNames);
   %
   %            catVarIdxs = find(varTypes.matches("categorical"));
   %
   %            for idx = catVarIdxs
   %                varName = varNames(idx);
   %
   %                validCats = unique(tbl.(varName));
   %                allCats = categories(tbl{1,varName});
   %                invalidCats = setdiff(allCats,validCats);
   %
   %                tbl.(varName) = removecats(tbl.(varName),invalidCats);
   %
   %            end
   %
   %        end
   %    end
   
end