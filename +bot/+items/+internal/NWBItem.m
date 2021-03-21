classdef NWBItem < bot.items.internal.Item
    
    %% SUBCLASS INTERFACE
    
    properties (Abstract, SetAccess = immutable, GetAccess = protected)
        NWB_FILE_PROPERTIES (1,:) string 
    end

    properties (Abstract, Dependent, SetAccess=protected)
        nwbIsCached (1,1) logical % true if NWB file corresponding to this item is already cached
        nwbURL (1,1) string 
    end       
   
%    properties (Hidden, Access=protected)
%        well_known_file;           % Metadata about probe NWB files
%       nwb_url;                   % URL for probe NWB file
%       local_nwb_file_location;
%    end                       
    
   %% SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
    
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
                for prop = obj.NWB_FILE_PROPERTIES
                    propList.(prop) = description;
                end
                
                groups(end+1) = matlab.mixin.util.PropertyGroup(propList, 'NWB data');                
            end
        end        
    end

    
end

