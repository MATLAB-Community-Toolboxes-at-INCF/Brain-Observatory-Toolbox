classdef ephysunit < bot.items.internal.Item
    
    %% UESR INTERFACE
    properties (SetAccess = private)
        session;
        channel;
        probe;
    end
        
    
    %% SUPERCLASS IMPLEMENTATION (bot.items.internal.Item)

    properties (Access = protected)
        CORE_PROPERTIES_EXTENDED = [];
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];
    end
    
    methods                
                
        % Constructor
        function unit = ephysunit(unit_id, oManifest)
            % - Handle "no arguments" usage
            if nargin == 0
                return;
            end
            
            % - Handle a vector of unit IDs
            if ~istable(unit_id) && (numel(unit_id) > 1)
                for nIndex = numel(unit_id):-1:1
                    unit(nIndex) = bot.items.ephysunit(unit_id(nIndex), oManifest);
                end
                return;
            end
            
            % - Assign metadata
            unit = unit.check_and_assign_metadata(unit_id, oManifest.ephys_units, 'unit');
            
            % - Get a handle to the corresponding experimental session
            unit.session = bot.session(unit.metadata.ephys_session_id);
            unit.channel = bot.channel(unit.metadata.ephys_channel_id);
            unit.probe = bot.probe(unit.metadata.ephys_probe_id);
        end
    end
end