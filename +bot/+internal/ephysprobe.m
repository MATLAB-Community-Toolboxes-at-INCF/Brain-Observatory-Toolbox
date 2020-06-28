classdef ephysprobe < bot.internal.ephysitem
   properties (SetAccess = private)
      tChannels;
      tUnits;
      session;
      sWellKnownFile;
      strNWBURL;
      strLocalNWBFileLocation;
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
         
         % - Identify NWB file link
         probe.sWellKnownFile = probe.get_lfp_file_link();
      end
      
      function sWellKnownFile = get_lfp_file_link(probe)
         probe_id = probe.sMetadata.id;
         strRequest = sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe_id);
         
         boc = bot.internal.cache;
         sWellKnownFile = table2struct(boc.CachedAPICall('criteria=model::WellKnownFile', strRequest));
      end
      
      function [lfp, timestamps] = get_lfp(self)
         if ~self.in_cache('lfp')
            nwb_probe = bot.nwb.nwb_probe(self.EnsureCached());
            [self.sPropertyCache.lfp, self.sPropertyCache.lfp_timestamps] = nwb_probe.get_lfp();
         end
         
         lfp = self.sPropertyCache.lfp;
         timestamps = self.sPropertyCache.lfp_timestamps;
      end
      
      function [csd, timestamps, horizontal_position, vertical_position] = get_current_source_density(self)
         if ~self.in_cache('csd')
            nwb_probe = bot.nwb.nwb_probe(self.EnsureCached());
            [self.sPropertyCache.csd, ...
               self.sPropertyCache.csd_timestamps, ...
               self.sPropertyCache.horizontal_position, ...
               self.sPropertyCache.vertical_position] = nwb_probe.get_current_source_density();
         end
         
         csd = self.sPropertyCache.csd;
         timestamps = self.sPropertyCache.csd_timestamps;
         horizontal_position = self.sPropertyCache.horizontal_position;
         vertical_position = self.sPropertyCache.vertical_position;
      end
      
      function strLocalNWBFileLocation = get.strLocalNWBFileLocation(self)
         % get.strLocalNWBFileLocation - GETTER METHOD Return the local location of the NWB file correspoding to this session
         %
         % Usage: strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         if ~self.IsNWBFileCached()
            strLocalNWBFileLocation = [];
         else
            % - Get the local file location for the session NWB URL
            boc = bot.internal.cache;
            strLocalNWBFileLocation = boc.ccCache.CachedFileForURL(self.strNWBURL);
         end
      end
      
      function strNWBURL = get.strNWBURL(self)
         boc = bot.internal.cache;
         strNWBURL = [boc.strABOBaseUrl self.sWellKnownFile.download_link];
      end
      
      function bIsCached = IsNWBFileCached(self)
         boc = bot.internal.cache;
         bIsCached = boc.IsURLInCache(self.strNWBURL);
      end
      
      function strNWBFile = EnsureCached(self)
         if ~self.IsNWBFileCached
            strNWBFile = boc.CacheFile([boc.strABOBaseUrl, self.sWellKnownFile.download_link], self.sWellKnownFile.path);
         else
            strNWBFile = self.strLocalNWBFileLocation;
         end
      end
   end
end

