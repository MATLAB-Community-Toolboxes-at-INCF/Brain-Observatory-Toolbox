classdef ephysprobe < bot.internal.ephysitem
   properties (SetAccess = private)
      channels;
      units;
      session;
      sWellKnownFile;
      strNWBURL;
      local_nwb_file_location
   end
   
   methods
      function probe = ephysprobe(nID, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of probe IDs
         if ~istable(nID) && (numel(nID) > 1)
            for nIndex = numel(nID):-1:1
               probe(nIndex) = bot.internal.ephysprobe(nID(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         probe.check_and_assign_metadata(nID, oManifest.tEPhysProbes, 'probe');
         if istable(nID)
            nID = probe.metadata.id;
         end
         
         % - Assign associated table rows
         probe.channels = oManifest.tEPhysChannels(oManifest.tEPhysChannels.ephys_probe_id == nID, :);
         probe.units = oManifest.tEPhysUnits(oManifest.tEPhysUnits.ephys_probe_id == nID, :);
         
         % - Get a handle to the corresponding experimental session
         probe.session = oManifest.session(probe.metadata.ephys_session_id);
         
         % - Identify NWB file link
         probe.sWellKnownFile = probe.get_lfp_file_link();
      end
      
      function sWellKnownFile = get_lfp_file_link(probe)
         probe_id = probe.metadata.id;
         strRequest = sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe_id);
         
         boc = bot.internal.cache;
         sWellKnownFile = table2struct(boc.CachedAPICall('criteria=model::WellKnownFile', strRequest));
      end
      
      function [lfp, timestamps] = get_lfp(self)
         if ~self.in_cache('lfp')
            nwb_probe = bot.nwb.nwb_probe(self.EnsureCached());
            [self.property_cache.lfp, self.property_cache.lfp_timestamps] = nwb_probe.get_lfp();
         end
         
         lfp = self.property_cache.lfp;
         timestamps = self.property_cache.lfp_timestamps;
      end
      
      function [csd, timestamps, horizontal_position, vertical_position] = get_current_source_density(self)
         if ~self.in_cache('csd')
            nwb_probe = bot.nwb.nwb_probe(self.EnsureCached());
            [self.property_cache.csd, ...
               self.property_cache.csd_timestamps, ...
               self.property_cache.horizontal_position, ...
               self.property_cache.vertical_position] = nwb_probe.get_current_source_density();
         end
         
         csd = self.property_cache.csd;
         timestamps = self.property_cache.csd_timestamps;
         horizontal_position = self.property_cache.horizontal_position;
         vertical_position = self.property_cache.vertical_position;
      end
      
      function local_nwb_file_location = get.local_nwb_file_location(self)
         % get.local_nwb_file_location - GETTER METHOD Return the local location of the NWB file correspoding to this session
         %
         % Usage: local_nwb_file_location = get.local_nwb_file_location(bos)
         if ~self.is_nwb_cached()
            local_nwb_file_location = [];
         else
            % - Get the local file location for the session NWB URL
            boc = bot.internal.cache;
            local_nwb_file_location = boc.ccCache.CachedFileForURL(self.strNWBURL);
         end
      end
      
      function strNWBURL = get.strNWBURL(self)
         boc = bot.internal.cache;
         strNWBURL = [boc.strABOBaseUrl self.sWellKnownFile.download_link];
      end
      
      function bIsCached = is_nwb_cached(self)
         boc = bot.internal.cache;
         bIsCached = boc.IsURLInCache(self.strNWBURL);
      end
      
      function strNWBFile = EnsureCached(self)
         if ~self.is_nwb_cached
            boc = bot.internal.cache;
            strNWBFile = boc.CacheFile([boc.strABOBaseUrl, self.sWellKnownFile.download_link], self.sWellKnownFile.path);
         else
            strNWBFile = self.local_nwb_file_location;
         end
      end
   end
end

