classdef Dataset
    % Enumeration class encoding Allen Brain Observatory dataset names
    %
    % The Allen Brain Observatory [1] resource currently contains two
    % datasets supported by the BOT:
    % 
    % * Visual Coding
    % * Visual Behavior
    %    
    % [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: https://portal.brain-map.org/explore/circuits

    enumeration
        VisualCoding("VisualCoding");
        VisualBehavior("VisualBehavior")
    end

    properties
        Name
        ShortName
    end

    methods % Constructor
        function obj = Dataset(name)
            obj.Name = name;
            
            upperIdx = isstrprop(obj.Name, 'upper');
            obj.ShortName = obj.Name{1}(upperIdx);
        end
    end
end
