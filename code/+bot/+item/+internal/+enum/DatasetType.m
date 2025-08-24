classdef DatasetType
    % Enumeration class encoding Allen Brain Observatory dataset types
    %
    % The Allen Brain Observatory [1] resource currently contains two types
    % of datasets supported by the BOT:
    % 
    % * Visual Coding 2P dataset [2]
    % * Visual Coding Neuropixels dataset [3]
    %    
    % [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits
    % [2] Copyright 2016 Allen Institute for Brain Science. Visual Coding 2P dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-2p
    % [3] Copyright 2019 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-coding-neuropixels
    %    
    
    enumeration 
        Ephys; % Visual Coding Neuropixels dataset
        Ophys; % Visual Coding 2P dataset
    end
    
    %     methods
    %         function prefix = getNWBWellKnownFilePrefix(obj)
    %             switch obj
    %                 case Ephys
    %                     prefix = "EcephysNwb";
    %                 case Ophys
    %                     prefix = "NWBOphys";
    %                 otherwise
    %                     assert(false);
    %             end
    %         end
    %     end


end
