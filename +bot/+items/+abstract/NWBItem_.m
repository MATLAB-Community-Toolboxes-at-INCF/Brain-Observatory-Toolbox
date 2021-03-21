classdef NWBItem < bot.items.internal.Item
    
    %% SUBCLASS INTERFACE
    
    properties (Abstract, SetAccess = immutable, GetAccess = protected)
        nwb_property_list (1,:) string {mustBeNonempty}
    end

    properties (Abstract, Dependent, Access = protected)
        nwbIsCached (1,1) logical % true if NWB file corresponding to this item is already cached
    end
    
    % superclass extensions
    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else                                
                groups = getPropertyGroups@bot.items.internal.Item(obj);
                
                % NWB-bound properties
                if obj.nwbIsCached
                    description = '[cached]';
                else
                    description = '[not cached]';
                end
                
                propList = struct();
                for prop = obj.lazy_property_list
                    propList.(prop) = description;
                end
                
                groups(end+1) = matlab.mixin.util.PropertyGroup(propList, 'NWB data');                
            end
        end        
    end
    
end

