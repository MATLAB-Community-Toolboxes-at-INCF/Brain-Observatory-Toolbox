classdef (Abstract) LinkedFile < bot.item.internal.mixin.OnDemandProps

    % Implementations of this class should make data which is available in
    % the file accessible from properies.

    properties (Abstract, Constant, Hidden)
        % This is the nickname of the file as needed by the file resource
        % classes to resolve the remove file location of a file.
        Name
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

    methods
        function obj = LinkedFile(filePath)
            obj.ON_DEMAND_PROPERTIES = properties(obj);

            obj.FilePath = filePath;
            
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