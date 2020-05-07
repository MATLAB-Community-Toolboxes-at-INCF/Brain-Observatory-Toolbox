classdef ephysprobe < bot.internal.ephysitem
   properties (SetAccess = private)
      tChannels;
      tUnits;
      session;
   end
   
   methods
      function probe = ephysprobe(nID, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of probe IDs
         if numel(nID) > 1
            for nIndex = numel(nID):-1:1
               probe(nIndex) = bot.internal.ephysprobe(nID(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         probe = probe.check_and_assign_metadata(nID, oManifest.tEPhysProbes, 'probe');
         
         % - Assign associated table rows
         probe.tChannels = oManifest.tEPhysChannels(oManifest.tEPhysChannels.ephys_probe_id == nID, :);
         probe.tUnits = oManifest.tEPhysUnits(oManifest.tEPhysUnits.ephys_probe_id == nID, :);
         
         % - Get a handle to the corresponding experimental session
         probe.session = oManifest.session(probe.sMetadata.ephys_session_id);
      end
   end
end
