classdef Channel < bot.item.internal.abstract.Item
    %
    % Represent direct, linked, and derived data for a Visual Coding Neuropixels dataset [1] channel item.
    %
    % [1] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
    %
    
    %% PROPERTIES - VISIBLE
    properties (SetAccess = private)
        units;
        session;
        probe;
    end
    
    %% PROPERTIES - HIDDEN
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ephys;
        ITEM_TYPE= bot.item.internal.enum.ItemType.Channel;
    end
    
    properties (Hidden)
        CORE_PROPERTIES = string.empty(1,0);
        LINKED_ITEM_PROPERTIES = ["session" "probe" "units"];
    end
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Channel(itemIDSpec)
            % Superclass construction
            obj = obj@bot.item.internal.abstract.Item(itemIDSpec);
            
            % Only process attributes if we are constructing a scalar object
            if (~istable(itemIDSpec) && numel(itemIDSpec) == 1) || (istable(itemIDSpec) && height(itemIDSpec) == 1)
                % Assign linked Item tables (downstream)
                obj.units = obj.manifest.ephys_units(obj.manifest.ephys_units.ephys_channel_id == obj.id, :);
                
                % Assign linked Item objects (upstream)
                obj.probe = bot.probe(obj.info.ephys_probe_id);
                obj.session = bot.session(obj.info.ephys_session_id, "ephys");
            end
        end
    end

    methods (Access = protected)
        function displayNonScalarObject(obj)
            displayNonScalarObject@bot.item.internal.abstract.Item(obj)

            % - Get unique probe IDs
            infos = [obj.info];
            ephys_probe_id = unique([infos.ephys_probe_id]);

            if numel(ephys_probe_id) == 1
                fprintf('     All channels from probe id: %d\n', ephys_probe_id);
            else
                exp_ids_part = "[" + sprintf('%d, ', ephys_probe_id(1:end-1)) + sprintf('%d]', ephys_probe_id(end));
                fprintf('     From probe ids: %s\n', exp_ids_part)
            end        
            
            % - Get unique session IDs
            infos = [obj.info];
            ephys_session_id = unique([infos.ephys_session_id]);

            if numel(ephys_session_id) == 1
                fprintf('     All channels from session id: %d\n\n', ephys_session_id);
            else
                exp_ids_part = "[" + sprintf('%d, ', ephys_session_id(1:end-1)) + sprintf('%d]', ephys_session_id(end));
                fprintf('     From session ids: %s\n\n', exp_ids_part)
            end
        end
    end    
end

