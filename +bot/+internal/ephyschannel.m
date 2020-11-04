classdef ephyschannel < bot.internal.ephysitem
   properties (SetAccess = private)
      tUnits;
      session;
      probe;
   end
   
   methods
      function channel = ephyschannel(nID, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of channel IDs
         if ~istable(nID) && (numel(nID) > 1)
            for nIndex = numel(nID):-1:1
               channel(nIndex) = bot.internal.ephyschannel(nID(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         channel = channel.check_and_assign_metadata(nID, oManifest.tEPhysChannels, 'channel');
         if istable(nID)
            nID = channel.sMetadata.id;
         end
         
         % - Assign associated table rows
         channel.tUnits = oManifest.tEPhysUnits(oManifest.tEPhysUnits.ecephys_channel_id == nID, :); 
         channel.probe = oManifest.probe(channel.sMetadata.ephys_probe_id);
         channel.session = oManifest.session(channel.sMetadata.ephys_session_id);
      end
   end
end

