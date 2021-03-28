classdef ephysprobe < bot.item.abstract.NWBItem
    
   %% PROPERTIES - USER
   
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
   
   
   %% PROPERTIES - HIDDEN
      
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)
   properties (Access = protected)
       CORE_PROPERTIES_EXTENDED = [];
       LINKED_ITEM_PROPERTIES = ["session" "channels" "units"];
   end
   
   properties (Hidden, Constant)
       ITEM_MANIFEST = bot.internal.ephysmanifest.instance();
       ITEM_MANIFEST_TABLE_NAME = "ephys_probes";
   end
   
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.NWBItem)      
      
   properties (SetAccess = immutable, GetAccess = protected)
       NWB_DATA_PROPERTIES = ["lfpData" "csdData"];
   end  
    
%    properties (Dependent, Hidden)
%        nwbURL;
%    end  

    
   %% PROPERTY ACCESS METHODS
   
   % USER PROPERTIES
   methods
       function lfpData = get.lfpData(self)
           % zprpGetLFP - METHOD Return local field potential data for this probe
           %
           % Usage: [lfp, timestamps] = probe.zprpGetLFP()
           %
           % `lfp` will be a TxN matrix containing LFP data recorded from
           % this probe. `timestamps` will be a Tx1 vector of timestamps,
           % corresponding to each row in `lfp`.
           if ~self.in_cache('lfp')
               self.ensureNWBCached();
               [self.property_cache.lfp, self.property_cache.lfp_timestamps] = self.zprpGetLFP();
           end
           
           lfpData = timetable(seconds(self.property_cache.lfp_timestamps),self.property_cache.lfp,'VariableNames',"LocalFieldPotential");           
       end
       
       function csdData = get.csdData(self)
           % zprpGetCSD - METHOD Return current source density data recorded from this probe
           %
           % Usage: [csd, timestamps, horizontal_position, vertical_position] = ...
           %           probe.zprpGetCSD()
           %
           % `csd` will be a TxN matrix containing CSD data recorded from
           % this probe. `timestamps` will be a Tx1 vector of timestamps,
           % corresponding to each row in `csd`. `horizontal_position` and
           % `vertical_position` will be Nx1 vectors containing the
           % horizontal and vertical positions corresponding to each column
           % of `csd`.
           if ~self.in_cache('csd')
               self.ensureNWBCached();
               [self.property_cache.csd, ...
                   self.property_cache.csd_timestamps, ...
                   self.property_cache.horizontal_position, ...
                   self.property_cache.vertical_position] = self.zprpGetCSD();
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
   
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.NWBItem)
%    methods
%        function url = get.nwbURL(self)
%            boc = bot.internal.cache;
%            url = [boc.strABOBaseUrl self.nwbFileInfo.download_link];
%        end      
%   
%    end
   
   % PROPERTY ACCESS HELPERS
   methods
       function [lfp, timestamps] = zprpGetLFP(self)
           
           id_ = uint64(self.id);
           
           % - Read lfp data
           lfp = h5read(self.nwbLocalFile, ...
               sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/data', id_, id_))';
           
           % - Read timestamps
           timestamps = h5read(self.nwbLocalFile, ...
               sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/timestamps', id_, id_));
       end
      
   
      function [csd, timestamps, virtual_electrode_x_positions, virtual_electrode_y_positions] = zprpGetCSD(self)
         % - Read CSD data
         csd = h5read(self.nwbLocalFile, ...
            '/processing/current_source_density/ecephys_csd/current_source_density/data');
         
         % - Read timestamps
         timestamps = h5read(self.nwbLocalFile, ...
            '/processing/current_source_density/ecephys_csd/current_source_density/timestamps');
         
         % - Read electrode position
         virtual_electrode_x_positions = h5read(self.nwbLocalFile, ...
            '/processing/current_source_density/ecephys_csd/virtual_electrode_x_positions');
         virtual_electrode_y_positions = h5read(self.nwbLocalFile, ...
            '/processing/current_source_density/ecephys_csd/virtual_electrode_y_positions');
      end 
       
       
   end   
   
   
   %% METHODS - THIS CLASS 

   % CONSTRUCTOR
   methods
      function obj = ephysprobe(id)
          %          % - Handle "no arguments" usage
          %          if nargin == 0
          %             return;
          %          end
          %
          %          % - Handle a vector of probe IDs
          %          if ~istable(probe_id) && (numel(probe_id) > 1)
          %             for nIndex = numel(probe_id):-1:1
          %                probe(nIndex) = bot.item.ephysprobe(probe_id(nIndex), oManifest);
          %             end
          %             return;
          %          end
          %
          %          % - Assign metadata
          %          probe.check_and_assign_metadata(probe_id, oManifest.ephys_probes, 'probe');
          %
          
          obj@bot.item.abstract.NWBItem(id);           
          
          % - Assign associated table rows
          manifest = obj.ITEM_MANIFEST;
          obj.channels = manifest.ephys_channels(manifest.ephys_channels.ephys_probe_id == obj.id, :);
          obj.units = manifest.ephys_units(manifest.ephys_units.ephys_probe_id == obj.id, :);
          
          % - Get a handle to the corresponding experimental session
          obj.session = bot.session(obj.info.ephys_session_id);
          
          % - Identify NWB file link
          obj.nwbFileInfo = znstGetLFPFileInfo(obj);
          
          return;
         
          function info = znstGetLFPFileInfo(probe)
              probe_id = probe.info.id;
              strRequest = sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe_id);
              
              boc = bot.internal.cache;
              info = table2struct(boc.CachedAPICall('criteria=model::WellKnownFile', strRequest));
          end
      end

   end          
     
end
