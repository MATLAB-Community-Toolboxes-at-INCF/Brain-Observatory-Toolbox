classdef NWBItem < bot.item.abstract.Item
    
          
    %% USER INTERFACE - Properties
    
    properties (Abstract, Dependent, SetAccess=protected)
        nwbIsCached (1,1) logical % true if NWB file corresponding to this item is already cached
        nwbLocalFile (1,1) string
    end    
    
    
    %% DEVELOPER INTERFACE - Properties
    
    properties (Abstract, SetAccess = immutable, GetAccess = protected)
        NWB_DATA_PROPERTIES (1,:) string
    end
    
    properties (Abstract, Dependent, Hidden)
        nwbURL (1,1) string; % TODO: consider if this can be deprecated
    end    
    
    
    %% DEVELOPER INTERFACE - METHODS

    methods (Abstract, Hidden)
        EnsureCached(obj);
    end

    
    %% SUPERCLASS OVERRIDES (bot.item.abstract.Item)
    
    % Constructor extension
    methods 
        function obj = NWBItem()
           
            obj@bot.item.abstract.Item;
            
            % Add NWB information to the core property list for this item
            obj.CORE_PROPERTIES_EXTENDED = [obj.CORE_PROPERTIES_EXTENDED "nwbIsCached" "nwbLocalFile" "nwbInfo"];                                     
        end                
    end
    
    
    %% SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
    
    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                groups = getPropertyGroups@bot.item.abstract.Item(obj);
                
                % NWB-bound properties
                if obj.nwbIsCached
                    description = '[cached]';
                else
                    description = '[not cached]';
                end
                
                propList = struct();
                for prop = obj.NWB_DATA_PROPERTIES
                    propList.(prop) = description;
                end
                
                groups(end+1) = matlab.mixin.util.PropertyGroup(propList, 'NWB Info');
            end
        end
    end
    
    
end

