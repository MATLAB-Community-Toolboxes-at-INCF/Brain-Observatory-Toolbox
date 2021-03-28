classdef ephyschannel < bot.item.abstract.Item
   
    %% USER INTERFACE 
    properties (SetAccess = private)
      units;
      session;
      probe;
    end
   
    %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)

    properties (Access = protected)
        CORE_PROPERTIES_EXTENDED = [];
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];
    end
    
    properties (Hidden, Constant)
        ITEM_MANIFEST = bot.internal.ephysmanifest.instance();
        ITEM_MANIFEST_TABLE_NAME = "ephys_channels";
    end
   
    % constructor
    methods
        function obj = ephyschannel(id)
            %             % - Handle "no arguments" usage
            %             if nargin == 0
            %                 return;
            %             end
            
            %             % - Handle a vector of channel IDs
            %             if ~istable(channel_id) && (numel(channel_id) > 1)
            %                 for nIndex = numel(channel_id):-1:1
            %                     channel(nIndex) = bot.item.ephyschannel(channel_id(nIndex), oManifest);
            %                 end
            %                 return;
            %             end
            
            %             % - Assign metadata
            %             channel = channel.check_and_assign_metadata(channel_id, oManifest.ephys_channels, 'channel');
            %             if istable(channel_id)
            %                 channel_id = channel.info.id;
            %             end
            
            obj@bot.item.abstract.Item(id);                   
            
            % - Assign associated table rows
            manifest = obj.ITEM_MANIFEST;
            obj.units = manifest.ephys_units(manifest.ephys_units.ecephys_channel_id == obj.id, :);
            obj.probe = bot.probe(obj.info.ephys_probe_id);
            obj.session = bot.session(obj.info.ephys_session_id);
        end
    end
end

