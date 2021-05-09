classdef ephysunit < bot.item.abstract.Item
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

    % SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)
    properties (Hidden, Access = protected)
        CORE_PROPERTIES = string.empty();
        LINKED_ITEM_PROPERTIES = ["session" "channel" "probe"];
    end
    
    %% LIFECYCLE 
    
    % CONSTRUCTOR
    methods                                       
        function unit = ephysunit(unit_id, oManifest)
            % - Handle "no arguments" usage
            if nargin == 0
                return;
            end
            
            % - Handle a vector of unit IDs
            if ~istable(unit_id) && (numel(unit_id) > 1)
                for nIndex = numel(unit_id):-1:1
                    unit(nIndex) = bot.item.ephysunit(unit_id(nIndex), oManifest);
                end
                return;
            end
            
            % - Assign metadata
            unit = unit.check_and_assign_metadata(unit_id, oManifest.ephys_units, 'unit');
            
            % - Get a handle to the corresponding experimental session
            unit.session = bot.session(unit.info.ephys_session_id);
            unit.channel = bot.channel(unit.info.ephys_channel_id);
            unit.probe = bot.probe(unit.info.ephys_probe_id);
        end
    end
end