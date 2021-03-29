classdef NWBItem < bot.item.abstract.Item
    
    
    %% USER INTERFACE - Properties
    
    properties (Dependent, SetAccess=protected)
        nwbLocalFile (1,1) string
        nwbIsCached (1,1) logical % true if NWB file corresponding to this item is already cached        
    end
    
    properties (Abstract, Dependent, SetAccess=protected)
    end    
    
    %% DEVELOPER INTERFACE - Properties
    
    properties (Abstract, SetAccess = immutable, GetAccess = protected)
        NWB_DATA_PROPERTIES (1,:) string
    end
    
    properties (Hidden, SetAccess = protected)
        nwbFileInfo struct; 
    end
    
    properties (Abstract, Dependent, Hidden)
        nwbURL (1,1) string; % TODO: consider if this can be deprecated
    end
    
    %% PROPERTY ACCESS METHODS
    methods
        function loc = get.nwbLocalFile(self)
            if ~self.nwbIsCached()
                loc = "";
            else
                % - Get the local file location for the session NWB URL
                boc = bot.internal.cache;
                loc = string(boc.ccCache.CachedFileForURL(self.nwbURL));
            end
        end      
        
        function tf = get.nwbIsCached(obj)
            boc = bot.internal.cache;
            tf = boc.IsURLInCache(obj.nwbURL);
        end
    end
    
    
    %% DEVELOPER INTERFACE - METHODS
    
    methods (Hidden)
        function loc = ensureNWBCached(obj)
            boc = bot.internal.cache;
            if ~obj.nwbIsCached
                loc = boc.CacheFile([boc.strABOBaseUrl, obj.nwbFileInfo.download_link], obj.nwbFileInfo.path);            
            else        
                loc = string(boc.ccCache.CachedFileForURL(obj.nwbURL));
            end
        end
            
    end
    
    %% DEVELOPER PROPERTIES
    properties (Hidden = true)
        property_cache = struct();
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
                if ~obj.nwbIsCached
                    description = '[NWB download required]';
                else
                    description = '[on demand]';                
                end
                
                for prop = obj.NWB_DATA_PROPERTIES
                    if ~obj.in_cache(prop)
                        propList.(prop) = description;
                    elseif isscalar(obj.property_cache.(prop)) || isempty(obj.property_cache.(prop))
                        propList.(prop)  = obj.fetch_cached(prop);                                                
                    else
                        %propList.(prop) = convertStringsToChars("cached (class: " + class(obj.fetch_cached(prop)) + ", size: " + mat2str(size(obj.fetch_cached(prop))) + ")");
                        propList.(prop) = convertStringsToChars(class(obj.fetch_cached(prop)) + " of size: " + mat2str(size(obj.fetch_cached(prop))));
                    end

                end
                
                groups(end+1) = matlab.mixin.util.PropertyGroup(propList, 'NWB Info');
            end
        end
    end
    
    
end

