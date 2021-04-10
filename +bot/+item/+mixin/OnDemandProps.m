classdef (Abstract) OnDemandProps < handle
    %ONDEMANDPROPS Implements an on-demand property cache, allow deferral of potentially expernsive property access operations
    
    %% PROPERTIES - HIDDEN
    properties (Hidden)
        property_cache = struct();
    end
    
    properties (Access = protected)
        ON_DEMAND_PROPERTIES (1,:) string = string.empty();
    end
    
    
    %% METHODS - HIDDEN
    
    methods (Hidden)
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
    
    methods (Access = protected)
    
        
        function [propListing,onDemandPropList] = getOnDemandPropListing(obj,propSet)
            %Helper for implementing getPropertyGroups
            
            arguments
               obj
               propSet (:,1) string = string.empty(); 
            end
            
            if ~isempty(propSet)
                assert(all(ismember(propSet, obj.ON_DEMAND_PROPERTIES)));
            else
                propSet = obj.ON_DEMAND_PROPERTIES;
            end
            
            onDemandPropList = string.empty();
            
            for prop = propSet'
                if ~obj.in_cache(prop)
                    propListing.(prop) = '[on demand]';
                    onDemandPropList(end+1) = prop; %#ok<AGROW>
                elseif isscalar(obj.property_cache.(prop)) || isempty(obj.property_cache.(prop))
                    propListing.(prop)  = obj.fetch_cached(prop);
                else
                    %propList.(prop) = convertStringsToChars("cached (class: " + class(obj.fetch_cached(prop)) + ", size: " + mat2str(size(obj.fetch_cached(prop))) + ")");
                    propListing.(prop) = convertStringsToChars(class(obj.fetch_cached(prop)) + " of size: " + mat2str(size(obj.fetch_cached(prop))));
                end
            end
        end
    end
end



