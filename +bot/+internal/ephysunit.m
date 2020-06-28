classdef ephysunit < bot.internal.ephysitem
   properties (SetAccess = private)
      session;
   end
   
   methods
      function unit = ephysunit(nID, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of unit IDs
         if numel(nID) > 1
            for nIndex = numel(nID):-1:1
               unit(nIndex) = bot.internal.ephysunit(nID(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         unit = unit.check_and_assign_metadata(nID, oManifest.tEPhysUnits, 'unit');
         
         % - Get a handle to the corresponding experimental session
         unit.session = oManifest.session(unit.sMetadata.ephys_session_id);
      end
   end
end