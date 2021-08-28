classdef Cell < bot.item.internal.abstract.Item
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
    
    properties (Hidden, Access = protected)
        CORE_PROPERTIES = string.empty();
        LINKED_ITEM_PROPERTIES = ["sessions" "experiment"];
    end
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Cell(itemIDSpec)
            % Superclass construction
            obj = obj@bot.item.internal.abstract.Item(itemIDSpec);
            
            % Only process attributes if we are constructing a scalar object
            if (~istable(itemIDSpec) && numel(itemIDSpec) == 1) || (istable(itemIDSpec) && size(itemIDSpec, 1) == 1)
                % Assign linked Item objects
                obj.experiment = bot.experiment(obj.info.experiment_container_id);
                obj.sessions = obj.experiment.sessions;
            end
        end
    end
end