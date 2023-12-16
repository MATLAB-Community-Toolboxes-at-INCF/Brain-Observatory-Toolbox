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
        Nickname char
    end

    properties (Access = protected, Hidden)
        AutoDownload = false
    end

    properties (SetAccess = private, Hidden)
        FilePath
    end

    properties (Access = protected, Hidden)
        IsInitialized = false
    end

    methods % Constructor
        function obj = LinkedFile(filePath, nickname)
            obj.ON_DEMAND_PROPERTIES = properties(obj);

            obj.FilePath = filePath;
            obj.Nickname = nickname;
            
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

    methods
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

        function parseFile(obj)
            % Subclass may implement
        end

        function openFile(obj)
            try
                obj.parseFile()
                obj.IsInitialized = true;
            catch ME
                throw(ME)
                %pass (File not available)
            end
        end
    end
end