classdef HasLinkedFile < dynamicprops & handle
% HasLinkedFile - Mixin for items that have linked files

    properties (Access = protected)
        % LinkedFiles - An array of LinkedFile objects
        LinkedFiles (1,:) bot.internal.behavior.LinkedFile
    end
    
    properties (Dependent)
        % LinkedFilesInfo - A dictionary with file nicknames as keys and
        % the local cached filepath of the corresponding file as values
        LinkedFilesInfo dictionary
    end

    properties (Abstract, Access = protected)
        % Dictionary mapping file nickname to a file class
        LinkedFileTypes dictionary
    end
    
    methods (Abstract, Access=protected)
        % Todo: Will there be any common routines for this step?
        % The responsibility of this method is to initialize all the linked
        % files that should belong to an item. That means to create the
        % File instances and add them to the LinkedFiles property
        initLinkedFiles(obj)
    end
    
    methods % Constructor
        function obj = HasLinkedFile()
            
            if numel(obj)>1; return; end
            % Ad hoc workaround. Item classes takes care of array item
            % creation and so if numel(obj)>1 the HasLinkedFile constructor
            % has already been initialized.

            if isempty(obj.id); return; end

            obj.initLinkedFiles()
            obj.embeddLinkedFileProperties()
        end
    end

    methods
        function status = getLinkedFilesStatus(obj)
        % getLinkedFilesStatus - Get availability status of linked files.
        %
        %   Syntax:
        %       status = getLinkedFilesStatus(obj) returns a string
        %       describing if data is available or if file(s) need to be
        %       downloaded.

            tf = arrayfun(@(x) exists(x), obj.LinkedFiles);
            if all(tf)
                status = 'Data Available';
            elseif sum(tf) > 1
                status = 'Downloads Required';
            else
                status = 'Download Required';
            end
        end
    end

    methods
        function linkedFilesMap = get.LinkedFilesInfo(obj)
        % get.LinkedFilesInfo - Get mapping for file nicknames to pathnames

            % Build a dictionary with file nicknames as keys and filepaths 
            % as values.
            keys = string( {obj.LinkedFiles.Nickname} );
            values = string( {obj.LinkedFiles.FilePath} );
            values(values=="")=missing;
            linkedFilesMap = dictionary(keys, values);
        end
    end

    methods (Hidden)
        function url = getRemoteFilePath(obj, fileNickname)
            arguments
                obj (1,1) bot.internal.behavior.mixin.HasLinkedFile
                fileNickname (1,1) string
            end
            % Consider whether HasLinkedFile should subclass HasFileResource
            % However, this method is more of a debugging method and will
            % likely only be used occasionally.
            fileResource = bot.internal.fileresource.mixin.HasFileResource();
            url = fileResource.getFileUrl(obj, fileNickname);
        end
    end

    methods (Access = private)

        function refreshLinkedFilePath(obj)
            
            % Check preferences if file should be downloaded
            prefs = bot.util.getPreferences();
            autoDownload = prefs.AutoDownloadNwb;

            fileNicknames = obj.LinkedFileTypes.keys;
             
            for fileNickname = fileNicknames
                filePath = obj.getLinkedFilePath(fileNickname, autoDownload);

                isMatchedLinkedFile = find(strcmp({obj.LinkedFiles.Nickname}, fileNickname));
                obj.LinkedFiles(isMatchedLinkedFile).updateFilePath(filePath);
            end
        end

        function embeddLinkedFileProperties(obj)
        % embeddLinkedFileProperties - Embedd linked file's properties on object
        %
        %   This method will embedd all the public (non-hidden) properties
        %   from each of the linked file objects to the object of a class
        %   that inherits from this mixin class.

            for i = 1:numel(obj) % <- Todo: Is this necessary? Seems like no from the constructor

                for linkedFile = obj(i).LinkedFiles % Loop over each linked file
                    propertyNameList = string( properties( linkedFile ) );
                    propertyNameList = reshape(propertyNameList, 1, []);

                    for propertyName = propertyNameList % Loop over each property
                        dynamicProperty = obj(i).addprop(propertyName);
                        dynamicProperty.GetMethod = @(obj, file, name) ...
                            obj.getLinkedFilePropertyValue(linkedFile, propertyName);
                        
                        % Add a hidden property with a pythonic name to
                        % allow users to access data using same names that
                        % are used in the allen sdk.
                        pythonicName = pascal2snake(propertyName);
                        dynamicPropertyPythonic = obj(i).addprop(pythonicName);
                        dynamicPropertyPythonic.Hidden = true;
                        dynamicPropertyPythonic.GetMethod = dynamicProperty.GetMethod;
                    end
                end
            end
        end

        function data = getLinkedFilePropertyValue(obj, linkedFile, propertyName)
        % getLinkedFilePropertyValue - Get value for a linked file property
            
            if linkedFile.isRemote()
                prefs = bot.util.getPreferences();
                if prefs.DownloadFrom == "S3" && prefs.DownloadRemoteFiles
                    obj.downloadLinkedFile(linkedFile.Nickname);
                end
            end

            if ~linkedFile.exists()
                obj.downloadLinkedFile(linkedFile.Nickname);
            end

            try
                data = linkedFile.fetchData(propertyName);
            catch ME
                throwAsCaller(ME)
            end
        end
    end
    
    methods (Hidden, Access = protected)
        
        function propertyGroups = getLinkedFilePropertyGroups(obj)
        % getLinkedFilePropertyGroups - Utility method for display
            import matlab.mixin.util.PropertyGroup
            propertyGroups = matlab.mixin.util.PropertyGroup.empty;

            for i = 1:numel(obj.LinkedFiles)
                propertyGroups = [propertyGroups, ...
                    obj.LinkedFiles(i).getPropertyGroups()]; %#ok<AGROW>
            end
        end

        function downloadLinkedFile(obj, fileNickname)
        %downloadLinkedFile - Retrieve a linked file (from cache or api/s3)
        %
        %  This method will retrieve a file using different strategies which
        %  depends on preference selections. 
        %
        %    1) If an Allen Brain Observatory S3 bucket is mounted locally
        %    and the preferences is set to download from S3, the file is
        %    copied from the bucket to the local cache
        %
        %    2) If an S3 bucket is not mounted locally, and the preference is
        %    set to download from S3, the file will be downloaded from the
        %    bucket using the https protocol.
        %
        %    3) If an S3 bucket is not mounted locally, and the preference is
        %    set to download from API, the file will be downloaded from the
        %    Allen Brain Observatory API
            
            filePath = obj.getLinkedFilePath(fileNickname, true);
            isMatchedLinkedFile = find(strcmp({obj.LinkedFiles.Nickname}, fileNickname));

            obj.LinkedFiles(isMatchedLinkedFile).updateFilePath(filePath);
        end

        function filePath = getLinkedFilePath(obj, fileNickname, autoDownload)
        %getLinkedFilePath - Get filepath for a linked file
                    
            % Get filepath from cache.
            datasetCache = bot.internal.behavior.Cache.instance();
            filePath = datasetCache.getPathForFile(fileNickname, obj, ...
                'AutoDownload', autoDownload);
        end
    end
end

function snakeCaseStr = pascal2snake(pascalCaseStr)
%pascal2snake Convert pascalcase string to snakecase string
%
%   snakeCaseStr = pascal2snake(pascalCaseStr) will convert a string of
%   pascal case to a string of snake case.
%
%   Example
%       pascalCaseStr = 'BrainObservatory'
%       snakeCaseStr = pascal2snake(pascalCaseStr)
%        
%       snakeCaseStr =
%        
%            'brain_observatory'
       
    % Note: Does not work if abbreviations as uppercased in a pascal case
    % string, e.g NWBData would return n_w_b_data

    pascalCaseStr = char(pascalCaseStr);
    capitalLetterStrIdx = regexp(pascalCaseStr, '[A-Z, 1-9]');

    % Work from tail to head, since we are inserting underscores and 
    % changing the length of the string
    for i = fliplr(capitalLetterStrIdx) 
        if i ~= 1
            pascalCaseStr = insertBefore(pascalCaseStr, i , '_');
        end
    end
    snakeCaseStr = lower(pascalCaseStr);
end
