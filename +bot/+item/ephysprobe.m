classdef ephysprobe < bot.item.abstract.NWBItem
    
   %% USER INTERFACE
   
   % Linked Items
   properties (SetAccess = private)
      session;       % `bot.session` object containing this probe
      channels;      % Table of channels recorded from this probe
      units;         % Table of units recorded from this probe
   end
   
   % NWB Info
   properties (Dependent)
       lfpData (1,1) timetable; % Local field potential (lfp) data for this probe
       csdData (1,1) struct; % Current source density (csd) data for this probe      
   end
   
   % Property Access Methods
   methods
       function lfpData = get.lfpData(self)
           % fetch_lfp - METHOD Return local field potential data for this probe
           %
           % Usage: [lfp, timestamps] = probe.fetch_lfp()
           %
           % `lfp` will be a TxN matrix containing LFP data recorded from
           % this probe. `timestamps` will be a Tx1 vector of timestamps,
           % corresponding to each row in `lfp`.
           if ~self.in_cache('lfp')
               nwb_probe = bot.internal.nwb.nwb_probe(self.EnsureCached());
               [self.property_cache.lfp, self.property_cache.lfp_timestamps] = nwb_probe.fetch_lfp();
           end
           
           lfpData = timetable(seconds(self.property_cache.lfp_timestamps),self.property_cache.lfp,'VariableNames',"LocalFieldPotential");           
       end
       
       function csdData = get.csdData(self)
           % fetch_current_source_density - METHOD Return current source density data recorded from this probe
           %
           % Usage: [csd, timestamps, horizontal_position, vertical_position] = ...
           %           probe.fetch_current_source_density()
           %
           % `csd` will be a TxN matrix containing CSD data recorded from
           % this probe. `timestamps` will be a Tx1 vector of timestamps,
           % corresponding to each row in `csd`. `horizontal_position` and
           % `vertical_position` will be Nx1 vectors containing the
           % horizontal and vertical positions corresponding to each column
           % of `csd`.
           if ~self.in_cache('csd')
               nwb_probe = bot.internal.nwb.nwb_probe(self.EnsureCached());
               [self.property_cache.csd, ...
                   self.property_cache.csd_timestamps, ...
                   self.property_cache.horizontal_position, ...
                   self.property_cache.vertical_position] = nwb_probe.fetch_current_source_density();
           end
           
           csdData = struct;
           
           csdData.data = timetable(seconds(self.property_cache.csd_timestamps),self.property_cache.csd','VariableNames',"CurrentSourceDensity");
           csdData.horizontalPositions = self.property_cache.horizontal_position;
           csdData.verticalPositions = self.property_cache.vertical_position;
           
           %            csd = self.property_cache.csd';
           %            timestamps = self.property_cache.csd_timestamps;
           %            horizontal_position = self.property_cache.horizontal_position;
           %            vertical_position = self.property_cache.vertical_position;
       end
   end


   
   
   %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)
   properties (Access = protected)
       CORE_PROPERTIES_EXTENDED = [];
       LINKED_ITEM_PROPERTIES = ["session" "channels" "units"];
   end
   
   %% SUPERCLASS IMPLEMENTATION (bot.item.abstract.NWBItem)
   
   % User Properties
   properties (Dependent, SetAccess = protected)
       nwbIsCached; 
       nwbLocalFile;
   end   
   
   % User Property Access Methods
   methods
%        function tf = get.nwbIsCached(bos)
%            tf = bos.bot_cache.IsURLInCache(bos.nwbURL);
%        end
% %    
%        function url = get.nwbURL(bos)
%           %Get the cloud URL for the NWB data file corresponding to this session
%            
%            % - Get well known files
%            well_known_files = bos.info.well_known_files;
%            
%            % - Find (first) NWB file
%            file_types = [well_known_files.well_known_file_type];
%            type_names = {file_types.name};
%            nwb_file_index = find(cellfun(@(c)strcmp(c, bos.NWB_WELL_KNOWN_FILE_PREFIX.char()), type_names), 1, 'first');
%            
%            % - Build URL
%            url = [bos.bot_cache.strABOBaseUrl well_known_files(nwb_file_index).download_link];
%        end
%        
       function url = get.nwbURL(self)
         boc = bot.internal.cache;
         url = [boc.strABOBaseUrl self.well_known_file.download_link];
      end
      
      function tf = get.nwbIsCached(self)
         boc = bot.internal.cache;
         tf = boc.IsURLInCache(self.nwbURL);
      end
       
   end
   
   % Developer Properties
   properties (SetAccess = immutable, GetAccess = protected)
       NWB_DATA_PROPERTIES = ["lfpData" "csdData"];
   end
   
   properties (Dependent, Hidden)
       nwbURL;
   end
    
   % Developer Property Access Methods
   methods
       function local_nwb_file_location = get.nwbLocalFile(self)
         if ~self.nwbIsCached()
            local_nwb_file_location = "";
         else
            % - Get the local file location for the session NWB URL
            boc = bot.internal.cache;
            local_nwb_file_location = string(boc.ccCache.CachedFileForURL(self.nwbURL));
         end
       end
   end
   
   % Developer Methods
   methods (Hidden)
       function strNWBFile = EnsureCached(self)
           if ~self.nwbIsCached
               boc = bot.internal.cache;
               strNWBFile = boc.CacheFile([boc.strABOBaseUrl, self.well_known_file.download_link], self.well_known_file.path);
           else
               strNWBFile = self.nwbLocalFile;
           end
       end
   end
   
   
   %% HIDDEN INTERFACE
   
   % Hidden properties
   properties (Hidden)
      well_known_file; % Metadata about probe NWB files
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
               probe(nIndex) = bot.item.ephysprobe(probe_id(nIndex), oManifest);
            end
            return;
         end
         
         % - Assign metadata
         probe.check_and_assign_metadata(probe_id, oManifest.ephys_probes, 'probe');
         if istable(probe_id)
            probe_id = probe.info.id;
         end
         
         % - Assign associated table rows
         probe.channels = oManifest.ephys_channels(oManifest.ephys_channels.ephys_probe_id == probe_id, :);
         probe.units = oManifest.ephys_units(oManifest.ephys_units.ephys_probe_id == probe_id, :);
         
         % - Get a handle to the corresponding experimental session
         probe.session = bot.session(probe.info.ephys_session_id);
         
         % - Identify NWB file link
         probe.well_known_file = probe.fetch_lfp_file_link();
      end               

   end
   
   
   methods (Hidden)
      function well_known_file = fetch_lfp_file_link(probe)
         probe_id = probe.info.id;
         strRequest = sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe_id);
         
         boc = bot.internal.cache;
         well_known_file = table2struct(boc.CachedAPICall('criteria=model::WellKnownFile', strRequest));
      end
   end   
     
end

