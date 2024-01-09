classdef LinkedFile < bot.item.internal.mixin.OnDemandProps
% LinkedFile - Represent a linked file of a Brain Observatory item

    % Implementations of this class should make data which is available in
    % a file accessible from properies.

    properties (Hidden, Dependent)
        % DisplayName - A variation of the class name to use as display name
        DisplayName
    end

    properties (SetAccess = immutable, GetAccess=?bot.behavior.internal.mixin.HasLinkedFile)
        % Nickname - This is the name of a linked file instance as it is
        % referred to in a FileResource class and it is used to resolve the
        % remote file location for the file.
        Nickname char % Todo: string
    end

    properties (Access = protected, Hidden)
        AutoDownload (1,1) logical = false
    end

    properties (SetAccess = private, Hidden)
        FilePath % Todo: string
    end

    properties (Access = protected, Hidden)
        IsInitialized (1,1) logical = false
    end

    methods % Constructor
        function obj = LinkedFile(filePath, nickname)
            obj.ON_DEMAND_PROPERTIES = properties(obj);

            obj.FilePath = filePath;
            obj.Nickname = nickname;
            
            obj.initializeProperties()

            if nargin < 1; return; end
            if isempty(char(obj.FilePath)); return; end

            obj.openFile()
        end
    end

    methods (Hidden)

        function tf = exists(obj) % Access = ?Cache ?
            tf = ~isempty( obj.FilePath ) && isfile( obj.FilePath );
        end

        function tf = isInitialized(obj)
            tf = obj.IsInitialized;
        end

        function updateFilePath(obj, filePath) % Access = ?HasLinkedFiles ?
            obj.FilePath = filePath;
            obj.openFile()
        end
    end

    methods % Set/get methods
        function set.FilePath(obj, newFilePath)
            if ~isempty(char(newFilePath)) && ~isfile(newFilePath)
                error('BOT:LinkedFile:FileDoesNotExist', ...
                    'File "%s" does not exist', newFilePath)
            else
                obj.FilePath = newFilePath;
            end
        end

        function displayName = get.DisplayName(obj)
            classNameSplit = strsplit( class(obj), '.') ;
            displayName = classNameSplit{end};
            displayName = strrep(displayName, 'File', '');
        end
    end

    methods (Access = protected)

        function initializeProperties(obj)
            propertyNames = string( properties(obj) );
            for propertyName = propertyNames'
                % Initialize an OnDemandProperty object if necessary
                if isempty(obj.(propertyName))
                    obj.(propertyName) = bot.internal.OnDemandProperty();
                end
                if isfile(obj.FilePath)
                     obj.(propertyName).OnDemandState = 'on-demand';
                else
                     obj.(propertyName).OnDemandState = 'download required';
                end
            end
        end

        function parseFile(obj)
            % Subclass may implement
        end

        function openFile(obj)
            % Todo: If opening a file directly from s3, consider whether to
            % skip parsing the file as this can be time consuming.
            if strncmp(obj.FilePath, 's3', 2); return; end
            if obj.FilePath == ""; return; end

            try
                obj.parseFile()
                obj.IsInitialized = true;
            catch ME
                throw(ME)
                %pass (File not available)
            end
        end
    end

    methods (Access = {?bot.behavior.internal.mixin.HasLinkedFile, ?bot.behavior.internal.LinkedFile})
        function propertyGroups = getPropertyGroups(obj)
            
            import matlab.mixin.util.PropertyGroup

            propList = struct;
            propNames = properties(obj);
            
            for j = 1:numel(propNames)
                thisPropName = propNames{j};
                thisPropValue = obj.(thisPropName);

                % Customize the property display if the value is empty.
                if isempty(thisPropValue)
                    if obj.isInitialized()
                        thisPropValue = categorical({'<unknown>  (unavailable)'});
                    else
                        thisPropValue = categorical({'<unknown>  (download required)'});
                    end
                end

                propList.(thisPropName) = thisPropValue;
            end

            displayName = obj.DisplayName;
            groupTitle = "Linked File Values ('" + displayName + "')";
            propertyGroups = PropertyGroup(propList, groupTitle);
        end
    end
end