classdef (Abstract) OnDemandProps < handle
    %ONDEMANDPROPS A mixin class implementing an on-demand property cache, allowing deferral of potentially expensive property access operations
    
    %% PROPERTIES - HIDDEN
    properties (Hidden)
        property_cache = struct();
    end
    
    properties (SetAccess = protected, Hidden)
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
                
                try 
                    self.property_cache.(property) = fun_access();
                catch 
                    self.property_cache.(property) = bot.item.internal.OnDemandState.Unavailable;
                end
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
            is_in_cache = isfield(self.property_cache, property);
        end
    end
    
    methods (Hidden, Access = protected)
    
        
        function [propListing,onDemandPropList] = getOnDemandPropListing(obj,propSet)
            %Helper for implementing getPropertyGroups
            
            arguments
               obj
               propSet (:,1) string = string.empty(); 
            end
            
            propListing = struct();
            onDemandPropList = string.empty();
            
            if isempty(propSet)
                return;
            else
                assert(all(ismember(propSet, obj.ON_DEMAND_PROPERTIES)));
            end                
            
            for prop = propSet(:)'
                if ~obj.in_cache(prop)
                    propListing.(prop) = '[on demand]';
                    onDemandPropList(end+1) = prop; %#ok<AGROW>
                elseif isa(obj.property_cache.(prop),'bot.item.internal.OnDemandState')
                    %Decode the state
                    if isequal(obj.property_cache.(prop),bot.item.internal.OnDemandState.Unavailable)
                       propListing.(prop) = '[unavailable]'; 
                    end
                else                    
                    szProp = size(obj.property_cache.(prop));
                    clsProp = class(obj.property_cache.(prop));
                    
                    if numel(szProp) == 2 && min(szProp) == 1 && ~ismember(clsProp,"timetable") && ~ismember(clsProp,"table")
                        val = obj.fetch_cached(prop);                        
                        propListing.(prop)  = val(:)';                        
                    else 
                        %propList.(prop) = convertStringsToChars("cached (class: " + class(obj.fetch_cached(prop)) + ", size: " + mat2str(size(obj.fetch_cached(prop))) + ")");
                        %propListing.(prop) = convertStringsToChars(class(obj.fetch_cached(prop)) + " of size: " + mat2str(size(obj.fetch_cached(prop))));
                        %propListing.(prop) = "[" +                        
                        propSummaryStr = "[";
                        for ii = 1:numel(szProp)
                            propSummaryStr = propSummaryStr + szProp(ii);
                            if ii < numel(szProp)
                                propSummaryStr = propSummaryStr + "x";
                            end
                        end
                        propSummaryStr = propSummaryStr + " " + class(obj.fetch_cached(prop)) + "]";
                        
                        propListing.(prop)  = propSummaryStr.char();
                    end                                           
                end
            end
        end
    end
end



