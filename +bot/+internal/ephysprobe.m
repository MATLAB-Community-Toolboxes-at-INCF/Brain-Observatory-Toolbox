classdef ephysprobe < bot.internal.ephysitem
   properties (SetAccess = private)
      channels;
      units;
      session;
      well_known_file;
      nwb_url;
      local_nwb_file_location
   end
   
   methods
      function probe = ephysprobe(probe_id, oManifest)
         % - Handle "no arguments" usage
         if nargin == 0
            return;
         end
         
         % - Handle a vector of probe IDs
         if ~istable(probe_id) && (numel(probe_id) > 1)
            for nIndex = numel(probe_id):-1:1
               probe(nIndex) = bot.internal.ephysprobe(probe_id(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         probe.check_and_assign_metadata(probe_id, oManifest.ephys_probes, 'probe');
         if istable(probe_id)
            probe_id = probe.metadata.id;
         end
         
         % - Assign associated table rows
         probe.channels = oManifest.ephys_channels(oManifest.ephys_channels.ephys_probe_id == probe_id, :);
         probe.units = oManifest.ephys_units(oManifest.ephys_units.ephys_probe_id == probe_id, :);
         
         % - Get a handle to the corresponding experimental session
         probe.session = oManifest.session(probe.metadata.ephys_session_id);
         
         % - Identify NWB file link
         probe.well_known_file = probe.get_lfp_file_link();
      end
      
      function well_known_file = get_lfp_file_link(probe)
         probe_id = probe.metadata.id;
         strRequest = sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe_id);
         
         boc = bot.internal.cache;
         well_known_file = table2struct(boc.CachedAPICall('criteria=model::WellKnownFile', strRequest));
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
            local_nwb_file_location = boc.ccCache.CachedFileForURL(self.nwb_url);
         end
      end
      
      function nwb_url = get.nwb_url(self)
         boc = bot.internal.cache;
         nwb_url = [boc.strABOBaseUrl self.well_known_file.download_link];
      end
      
      function bIsCached = is_nwb_cached(self)
         boc = bot.internal.cache;
         bIsCached = boc.IsURLInCache(self.nwb_url);
      end
      
      function strNWBFile = EnsureCached(self)
         if ~self.is_nwb_cached
            boc = bot.internal.cache;
            strNWBFile = boc.CacheFile([boc.strABOBaseUrl, self.well_known_file.download_link], self.well_known_file.path);
         else
            strNWBFile = self.local_nwb_file_location;
         end
      end
   end
end

