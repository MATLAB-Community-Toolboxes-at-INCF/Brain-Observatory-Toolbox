classdef HasLinkedFile < dynamicprops & handle
% HasLinkedFile - Mixin for items that have linked files

    properties (Access = protected)
        % LinkedFiles - An array of LinkedFile objects
        LinkedFiles (1,:) bot.behavior.internal.LinkedFile
    end
    
    properties (Dependent)
        % LinkedFilesInfo - A dictionary with file nicknames as keys and
        % the local cached filepath of the corresponding file as values
        LinkedFilesInfo
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
            keys = string( {obj.LinkedFiles.Nickname} );
            values = string( {obj.LinkedFiles.FilePath} );
            values(values=="")=missing;
            linkedFilesMap = dictionary(keys, values);
        end
    end

    methods (Access = private)
        function embeddLinkedFileProperties(obj)
            for i = 1:numel(obj)

                for linkedFile = obj(i).LinkedFiles % Loop over each linked file
                    
                    propertyNameList = string( properties( linkedFile ) );
                    propertyNameList = reshape(propertyNameList, 1, []);
                    for propertyName = propertyNameList % Loop over each property
                        dynamicProperty = obj(i).addprop(propertyName);
                        dynamicProperty.GetMethod = @(obj, file, name) ...
                            obj.getLinkedFilePropertyValue(linkedFile, propertyName);
                    end
                end
            end
        end

        function data = getLinkedFilePropertyValue(obj, linkedFile, propertyName)
        % getLinkedFilePropertyValue - Get value for a linked file property
            if ~linkedFile.exists()
                obj.downloadLinkedFile(linkedFile.Nickname);
            end

            data = linkedFile.fetchData(propertyName);
        end
    end
    
    methods (Hidden, Access = protected)
        
        function propertyGroups = getLinkedFilePropertyGroups(obj)
        % getLinkedFilePropertyGroups - Utility method for display
            import matlab.mixin.util.PropertyGroup
            propertyGroups = matlab.mixin.util.PropertyGroup.empty;

            for i = 1:numel(obj.LinkedFiles)
                propList = struct;
                propNames = properties(obj.LinkedFiles(i));
                
                for j = 1:numel(propNames)
                    thisPropName = propNames{j};
                    thisPropValue = obj.LinkedFiles(i).(thisPropName);

                    % Customize the property display if the value is empty.
                    if isempty(thisPropValue)
                        if obj.LinkedFiles(i).isInitialized()
                            thisPropValue = categorical({'<unknown>  (unavailable)'});
                        else
                            thisPropValue = categorical({'<unknown>  (download required)'});
                        end
                    end

                    propList.(thisPropName) = thisPropValue;
                end

                displayName = obj.LinkedFiles.DisplayName;
                groupTitle = "Linked File Values ('" + displayName + "')";
                propertyGroups(i) = PropertyGroup(propList, groupTitle);
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

            % Get filepath from cache.
            datasetCache = bot.behavior.internal.Cache.instance();

            % Todo
            % assert(~datasetCache.IsFileInCache(fileKey), "File has already been downloaded");
            
            filePath = datasetCache.getPathForFile(fileNickname, obj, 'AutoDownload', true);
            isCurrentLinkedFile = find(strcmp({obj.LinkedFiles.Nickname}, fileNickname));

            obj.LinkedFiles(isCurrentLinkedFile).updateFilePath(filePath);
        end
    end
end