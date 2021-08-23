classdef Unit < bot.item.internal.abstract.Item
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
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ephys;
        ITEM_TYPE = bot.item.internal.enum.ItemType.Unit;
    end
    
    properties (Hidden, Access = protected)
        CORE_PROPERTIES = string.empty();
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];
    end
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Unit(itemIDSpec)
            % Superclass construction
            obj = obj@bot.item.internal.abstract.Item(itemIDSpec);
            
            % Only process attributes if we are constructing a scalar object
            if (~istable(itemIDSpec) && numel(itemIDSpec) == 1) || (istable(itemIDSpec) && size(itemIDSpec, 1) == 1)
                % Assign linked Item objects
                obj.session = bot.session(obj.info.ephys_session_id);
                obj.channel = bot.channel(obj.info.ephys_channel_id);
                obj.probe = bot.probe(obj.info.ephys_probe_id);
            end
        end
    end
end