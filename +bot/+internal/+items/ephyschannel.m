classdef ephyschannel < bot.internal.items.ephysitem
   properties (SetAccess = private)
      units;
      session;
      probe;
   end
   
   methods
      function channel = ephyschannel(channel_id, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of channel IDs
         if ~istable(channel_id) && (numel(channel_id) > 1)
            for nIndex = numel(channel_id):-1:1
               channel(nIndex) = bot.internal.items.ephyschannel(channel_id(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         channel = channel.check_and_assign_metadata(channel_id, oManifest.ephys_channels, 'channel');
         if istable(channel_id)
            channel_id = channel.metadata.id;
         end
         
         % - Assign associated table rows
         channel.units = oManifest.ephys_units(oManifest.ephys_units.ecephys_channel_id == channel_id, :); 
         channel.probe = bot.probe(channel.metadata.ephys_probe_id);
         channel.session = bot.session(channel.metadata.ephys_session_id);
      end
   end
end

