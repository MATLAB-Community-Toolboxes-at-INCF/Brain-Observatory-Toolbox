classdef ephysunit < bot.item.abstract.Item
    
    %% UESR INTERFACE
    properties (SetAccess = private)
        session;
        channel;
        probe;
    end
        
    
    %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)

    properties (Access = protected)
        CORE_PROPERTIES_EXTENDED = [];
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];
    end
    
    properties (Hidden, Constant)
        ITEM_MANIFEST = bot.internal.ephysmanifest.instance();
        ITEM_MANIFEST_TABLE_NAME = "ephys_units";
    end
    
    methods                
                
        % Constructor
        function obj = ephysunit(id)
            %             % - Handle "no arguments" usage
            %             if nargin == 0
            %                 return;
            %             end
            %
            %             % - Handle a vector of unit IDs
            %             if ~istable(unit_id) && (numel(unit_id) > 1)
            %                 for nIndex = numel(unit_id):-1:1
            %                     unit(nIndex) = bot.item.ephysunit(unit_id(nIndex), oManifest);
            %                 end
            %                 return;
            %             end
            %
            %             % - Assign metadata
            %             unit = unit.check_and_assign_metadata(unit_id, oManifest.ephys_units, 'unit');
            
            obj@bot.item.abstract.Item(id);      
            
            % - Get a handle to the corresponding experimental session
            obj.session = bot.session(obj.info.ephys_session_id);
            obj.channel = bot.channel(obj.info.ephys_channel_id);
            obj.probe = bot.probe(obj.info.ephys_probe_id);
        end
    end
end