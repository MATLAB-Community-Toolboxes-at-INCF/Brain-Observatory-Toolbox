classdef ephysprobe < bot.item.abstract.LinkedFilesItem
%
% Represent direct, linked, and derived data for a Visual Coding Neuropixels dataset [1] probe item.
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
% 
    
    
    %% PROPERTIES - VISIBLE
    
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
    properties (Hidden, Access = protected)
        CORE_PROPERTIES_EXTENDED = [];
        LINKED_ITEM_PROPERTIES = ["session" "channels" "units"];
    end

    % SUPERCLASS IMPLEMENTATION (bot.item.abstract.LinkedFilesItem)    
    properties (Hidden, SetAccess = protected)
        LINKED_FILE_PROP_BINDINGS = struct("LFPNWB",["lfpData" "csdData"]);
        LINKED_FILE_AUTO_DOWNLOAD = struct("LFPNWB",false);
    end
    
    
    %% PROPERTY ACCESS METHODS
    
    % VISIBLE PROPERTIES
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
                self.ensurePropFileDownloaded("lfpData");
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
                self.ensurePropFileDownloaded("csdData");
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
    
    % PROPERTY ACCESS HELPERS
    methods (Access=private)
        function [lfp, timestamps] = zprpGetLFP(self)
            
            id_ = uint64(self.id);
            
            nwbLocalFile = self.whichPropFile("lfpData");           
            
            % - Read lfp data
            lfp = h5read(nwbLocalFile, ...
                sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/data', id_, id_))';
            
            % - Read timestamps
            timestamps = h5read(nwbLocalFile, ...
                sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/timestamps', id_, id_));
        end
        
        
        function [csd, timestamps, virtual_electrode_x_positions, virtual_electrode_y_positions] = zprpGetCSD(self)
            
            nwbLocalFile = self.whichPropFile("csdData");

            % - Read CSD data
            csd = h5read(nwbLocalFile, ...
                '/processing/current_source_density/ecephys_csd/current_source_density/data');
            
            % - Read timestamps
            timestamps = h5read(nwbLocalFile, ...
                '/processing/current_source_density/ecephys_csd/current_source_density/timestamps');
            
            % - Read electrode position
            virtual_electrode_x_positions = h5read(nwbLocalFile, ...
                '/processing/current_source_density/ecephys_csd/virtual_electrode_x_positions');
            virtual_electrode_y_positions = h5read(nwbLocalFile, ...
                '/processing/current_source_density/ecephys_csd/virtual_electrode_y_positions');
        end
        
        
    end
    
    
    %% CONSTRUCTOR
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
            
            % Superclass initialization (bot.item.abstract.LinkedFilesItem)
            probe.fetchLinkedFileInfo("LFPNWB", sprintf('rma::criteria,well_known_file_type[name$eq''EcephysLfpNwb''],[attachable_type$eq''EcephysProbe''],[attachable_id$eq%d]', probe.id));
            probe.initLinkedFiles();
            
            
            return;            

        end
        
    end
    
end
