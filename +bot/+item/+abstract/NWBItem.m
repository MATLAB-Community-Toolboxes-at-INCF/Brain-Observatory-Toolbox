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
    
    %% DEVELOPER PROPERTIES
    properties (Hidden = true)
        property_cache;
    end
    
    %% DEVELOPER METHODS
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

