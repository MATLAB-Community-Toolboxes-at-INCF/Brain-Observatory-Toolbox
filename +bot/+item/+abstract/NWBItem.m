classdef NWBItem < bot.item.abstract.Item & bot.item.mixin.OnDemandProps
    
    
    %% USER INTERFACE - Properties
    
    properties (Dependent, SetAccess=protected)
        nwbLocalFile (1,1) string
        nwbIsCached (1,1) logical % true if NWB file corresponding to this item is already cached        
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
        
    %% SUPERCLASS OVERRIDES (bot.item.abstract.Item)
    
    % Constructor extension
    methods
        function obj = NWBItem()
            
            obj@bot.item.abstract.Item;
                        
            % Add NWB information to the relevant property list PROPERTIES for this item
            obj.CORE_PROPERTIES_EXTENDED = [obj.CORE_PROPERTIES_EXTENDED "nwbIsCached" "nwbLocalFile" "nwbInfo"];
            obj.ON_DEMAND_PROPERTIES = [obj.ON_DEMAND_PROPERTIES obj.NWB_DATA_PROPERTIES];
        end
    end
    
    
    %% SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
    
    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                groups = getPropertyGroups@bot.item.abstract.Item(obj);
                
                [propListing, onDemandPropList] = obj.getOnDemandPropListing(obj.NWB_DATA_PROPERTIES);                                            
                
                % NWB-bound properties
                if ~obj.nwbIsCached
                    for odProp = onDemandPropList
                        propListing.(odProp) = '[NWB download required]';
                    end                    
                end                
     
                groups(end+1) = matlab.mixin.util.PropertyGroup(propListing, 'NWB Info');
            end
        end
    end
    
    
end

