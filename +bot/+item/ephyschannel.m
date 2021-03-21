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
   
    % constructor
    methods
        function channel = ephyschannel(channel_id, oManifest)
            % - Handle "no arguments" usage
            if nargin == 0
                return;
            end
            
            % - Handle a vector of channel IDs
            if ~istable(channel_id) && (numel(channel_id) > 1)
                for nIndex = numel(channel_id):-1:1
                    channel(nIndex) = bot.item.ephyschannel(channel_id(nIndex), oManifest);
                end
                return;
            end
            
            % - Assign metadata
            channel = channel.check_and_assign_metadata(channel_id, oManifest.ephys_channels, 'channel');
            if istable(channel_id)
                channel_id = channel.info.id;
            end
            
            % - Assign associated table rows
            channel.units = oManifest.ephys_units(oManifest.ephys_units.ecephys_channel_id == channel_id, :);
            channel.probe = bot.probe(channel.info.ephys_probe_id);
            channel.session = bot.session(channel.info.ephys_session_id);
        end
    end
end
