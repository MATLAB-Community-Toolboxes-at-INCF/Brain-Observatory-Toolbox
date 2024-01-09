classdef Unit < bot.item.internal.abstract.Item & bot.item.internal.mixin.Metrics
    %
    % Represent direct, linked, and derived data for a Visual Coding Neuropixels dataset [1] unit item.
    %
    % [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
    %
    
    %% PROPERTIS - VISIBLE
    properties (SetAccess = private)
        session;
        channel;
        probe;
    end
    
    
    %% PROPERTIES - HIDDEN
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        DATASET = bot.item.internal.enum.Dataset("VisualCoding")
        DATASET_TYPE = bot.item.internal.enum.DatasetType("Ephys");
        ITEM_TYPE = bot.item.internal.enum.ItemType.Unit;
    end
    
    properties (Hidden)
        CORE_PROPERTIES = string.empty();
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];    
    end
    
    properties (Hidden, Constant)
        METRIC_PROPERTIES = ["L_ratio" "age_in_days" "air_channel_index" ...
            "amplitude_cutoff" "anterior_posterior_ccf_coordinate" ...
            "cumulative_drift" "d_prime" "dorsal_ventral_ccf_coordinate" ...
            "firing_rate" "isi_violations" "isolation_distance" ...
            "left_right_ccf_coordinate" "lfp_temporal_subsampling_factor" ...
            "max_drift" "nn_hit_rate" "nn_miss_rate" "peak_channel" ...
            "presence_ratio" "probe_horizontal_position" ...
            "probe_lfp_sampling_rate" "silhouette_score" "snr" ...
            "surface_channel_index" "waveform_PT_ratio" "waveform_amplitude" ...
            "waveform_duration" "waveform_halfwidth" "waveform_recovery_slope" ...
            "waveform_repolarization_slope" "waveform_spread" ...
            "waveform_velocity_above" "waveform_velocity_below" ...
            "probe_sampling_rate" "probe_vertical_position" "probe_phase"];
    end
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Unit(itemIDSpec)
            arguments
                itemIDSpec {bot.item.internal.abstract.Item.mustBeItemIDSpec};                
            end
            
            % Check that if we were provided a table, we use just the IDs,
            % to make sure that all metrics are included
            if nargin > 0 && istable(itemIDSpec)
                itemIDSpec = itemIDSpec.id;
            end
            
            % Superclass construction
            obj = obj@bot.item.internal.abstract.Item(itemIDSpec);
            
            % Only process attributes if we are constructing a scalar object
            if (~istable(itemIDSpec) && numel(itemIDSpec) == 1) || (istable(itemIDSpec) && height(itemIDSpec) == 1)
                % Assign linked Item objects
                obj.session = bot.getSessions(obj.info.ephys_session_id, "ephys");
                obj.channel = bot.getChannels(obj.info.ephys_channel_id);
                obj.probe = bot.getProbes(obj.info.ephys_probe_id);
                
                % Handle metric properties
                obj.init_metrics();
            end
        end
    end

    methods (Access = protected)
        function displayNonScalarObject(obj)
            displayNonScalarObject@bot.item.internal.abstract.Item(obj)

            % - Get unique channel IDs
            infos = [obj.info];
            ephys_channel_id = unique([infos.ephys_channel_id]);

            if numel(ephys_channel_id) == 1
                fprintf('     All units from channel id: %d\n', ephys_channel_id);
            else
                exp_ids_part = "[" + sprintf('%d, ', ephys_channel_id(1:end-1)) + sprintf('%d]', ephys_channel_id(end));
                fprintf('     From channel ids: %s\n', exp_ids_part)
            end

            % - Get unique probe IDs
            infos = [obj.info];
            ephys_probe_id = unique([infos.ephys_probe_id]);

            if numel(ephys_probe_id) == 1
                fprintf('     All units from probe id: %d\n', ephys_probe_id);
            else
                exp_ids_part = "[" + sprintf('%d, ', ephys_probe_id(1:end-1)) + sprintf('%d]', ephys_probe_id(end));
                fprintf('     From probe ids: %s\n', exp_ids_part)
            end        

            % - Get unique session IDs
            infos = [obj.info];
            ephys_session_id = unique([infos.ephys_session_id]);

            if numel(ephys_session_id) == 1
                fprintf('     All units from session id: %d\n\n', ephys_session_id);
            else
                exp_ids_part = "[" + sprintf('%d, ', ephys_session_id(1:end-1)) + sprintf('%d]', ephys_session_id(end));
                fprintf('     From session ids: %s\n\n', exp_ids_part)
            end        
        
        end
    end
end