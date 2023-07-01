classdef Cell < bot.item.internal.abstract.Item & bot.item.internal.mixin.Metrics
    %
    % Represent direct, linked, and derived data for a Visual Coding dataset [1] cell item.
    %
    % [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding dataset. Available from: http://observatory.brain-map.org/visualcoding
    %
    
    %% PROPERTIS - VISIBLE
    properties (SetAccess = private)
        sessions;
        experiment;
    end
    
    
    %% PROPERTIES - HIDDEN
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
        ITEM_TYPE = bot.item.internal.enum.ItemType.Cell;
    end
    
    properties (Hidden)
        CORE_PROPERTIES = string.empty();
        LINKED_ITEM_PROPERTIES = ["sessions" "experiment"];
    end

    properties (Hidden, Constant)
        METRIC_PROPERTIES = ["g_dsi_dg" "dsi_dg" "g_osi_dg" "g_osi_sg" ...
            "image_sel_ns" "osi_dg" "osi_sg" "p_dg" "p_ns" "p_run_mod_dg" ...
            "p_run_mod_dg" "p_run_mod_sg" "p_sg" "peak_dff_dg" "peak_dff_ns" ...
            "peak_dff_sg" "pref_dir_dg" "pref_image_ns" "pref_ori_sg" ...
            "pref_phase_sg" "pref_sf_sg" "pref_tf_dg" "reliability_dg" ...
            "reliability_nm1_a" "reliability_nm1_b" "reliability_nm1_c" ...
            "reliability_nm2" "reliability_nm3" "reliability_ns" ...
            "reliability_sg" "rf_area_off_lsn" "rf_area_on_lsn" ...
            "rf_center_off_x_lsn" "rf_center_off_y_lsn" ...
            "rf_center_on_x_lsn" "rf_center_on_y_lsn" "rf_chi2_lsn" ...
            "rf_distance_lsn" "rf_overlap_index_lsn" "run_mod_dg" ...
            "run_mod_ns" "run_mod_sg" "sfdi_sg" "tfdi_dg" "time_to_peak_ns" ...
            "time_to_peak_sg" "p_run_mod_ns"];
    end        
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Cell(itemIDSpec)            
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
            if (~istable(itemIDSpec) && numel(itemIDSpec) == 1) || (istable(itemIDSpec) && size(itemIDSpec, 1) == 1)
                % Assign linked Item objects
                obj.experiment = bot.getExperiments(obj.info.experiment_container_id);
                obj.sessions = obj.experiment.sessions;
                
                % Initialise Metrics
                obj.init_metrics();
            end
        end
    end
end