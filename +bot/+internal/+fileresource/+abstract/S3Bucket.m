classdef S3Bucket < bot.internal.abstract.FileResource
%S3Bucket Builder of URIs for files that are part of the ABO S3 bucket
%
%   This class implements methods for retrieving URIs for data files and 
%   item tables from the Allen Brain Observatory S3 Bucket.
%
%   The class is implemented as a singleton

    % Todo: 
    % Use the manifest.json in the ABO S3 root dataset folder to map
    % variables to filenames / file expressions

    % Note. 
    % The implementation of this fileresource is different from the api
    % fileresource implementation by encapsulating only ephys or
    % ophys data, whereas the api resource encapsulates both.
    %
    % This also implies that the getItemTable function does not need the
    % data type input as is needed for the api/getItemTable method

    properties (Constant, Abstract)
        % Name of AWS S3 bucket
        BucketName

        % Region code of AWS S3 bucket
        RegionCode

        % Name of root folder containing dataset files
        RootFolderName
    end

    properties (Dependent)

        % Base URI for the Allen Brain Observatory S3 Bucket (s3 protocol)
        S3BaseUri

        % Base URL for the Allen Brain Observatory S3 Bucket (https protocol)
        S3BaseUrl
        
        % Directory path if S3 bucket is mounted as a local file system     % Todo: Should this be a preference instead?
        S3LocalMount
    end

    properties (Abstract, Access = protected)
        
        % Filenames for item manifest tables 
        ItemTableFileNames
    end

    properties (Access = protected, Dependent)
        ItemTypes
    end

    properties (Access = private) % Todo: make dependent or abstract.
        % For dependent, use the dataset and dataset type constant
        % properties
        InternalName = 's3-abo-vbo' % Allen brain observatory, visual behavior ophys
    end

    properties (Dependent) % Todo: Access = protected
        PreferredScheme
    end

    methods (Abstract, Static)
        relativePathURI = getRelativeFileUriPath(itemObject, fileNickname, varargin)
    end

    methods (Access = protected) % Constructor
        function obj = S3Bucket()
            % Constructor is protected in order to implement as singleton
        end
    end

    methods % Dependent property get methods
        function baseUri = get.S3BaseUri(obj)
            baseUri = sprintf("s3://%s", obj.BucketName);
        end

        function baseUrl = get.S3BaseUrl(obj)
            baseUrl = sprintf("https://%s.s3.%s.amazonaws.com", obj.BucketName, obj.RegionCode);
        end
                   
        function pathStr = get.S3LocalMount(obj)
            pathStr = fullfile("/home", "ubuntu", obj.InternalName); % Todo: Should get from preferences
        end
    end


    methods % Public methods
        function tf = isMounted(~)
        %isMounted Determine if s3 bucket is mounted as local file system
            tf = bot.internal.Preferences.getPreferenceValue('UseLocalS3Mount') && ...
                isfolder( bot.internal.Preferences.getPreferenceValue('S3MountDirectory') );
        end

        function strURI = getDataFileURI(obj, itemObject, fileNickname, varargin)
        %getDataFileURI Get URI for a data file (file belonging to item)
            filename = obj.getRelativeFileUriPath(itemObject, fileNickname, varargin{:});
            baseURI = obj.getDataFolderUri();
            strURI = uriJoin(baseURI, filename);
        end
        
        function strURI = getItemTableURI(obj, itemType)
        %getItemTableURI Get URI for item table

            itemType = validatestring(itemType, obj.ItemTypes);

            filename = obj.ItemTableFileNames(itemType);
            baseURI = obj.getDataFolderUri();
            strURI = uriJoin(baseURI, filename);
        end
    end

    methods % Set /get
        
        function preferredScheme = get.PreferredScheme(obj)
            if obj.isMounted() && ~obj.useCloudCacher()
                preferredScheme = "file";
            else
                preferredScheme = "https";
            end

            if obj.useS3Protocol() % Todo
                preferredScheme = 's3';
            end

            % Note. The s3 scheme is currently not in use, but might be
            % relevant if a mode is implemented where on demand properties
            % are retrieved from a file on the s3 instead of a local file.
        end
        
    end

    methods (Access = protected)
        function baseUrl = getVirtualHostedStyleBaseUrl(obj)
        %getVirtualHostedStyleBaseUrl Get base url in virtual-hosted–style

        %   Amazon S3 virtual-hosted–style URLs use the following format:
        %       https://bucket-name.s3.region-code.amazonaws.com/key-name

            baseUrl = sprintf('https://%s.s3.%s.amazonaws.com', ...
                obj.BucketName, obj.RegionCode);
        end

        function baseUrl = getS3SchemeBaseUrl(obj)
        %getS3SchemeBaseUrl Get base url in s3 scheme format
        %
        %   A url using the S3 scheme has the following format:
        %       S3://bucket-name/key-name
            
            baseUrl = sprintf('s3://%s', obj.BucketName);
        end
    end

    methods % Get protected dependent properties
        function itemTypes = get.ItemTypes(obj)
            itemTypes = keys(obj.ItemTableFileNames);
        end
    end

    methods (Hidden, Access = protected)

        function tf = retrieveFileFromS3Bucket(~)
            tf = bot.internal.Preferences.getPreferenceValue('DownloadFrom') == "S3";
        end
        
        function tf = useCloudCacher(~)
            tf = bot.internal.Preferences.getPreferenceValue('UseCacheWithS3Mount');
        end

        function tf = useS3Protocol(~)
            try
                tf = strcmp( bot.internal.Preferences.getPreferenceValue('DownloadMode'), 'Variable'); %#ok<UNRCH> 
            catch
                tf = false;
            end
        end
    end

    methods (Access = protected)
        
        function folderURI = getDataFolderUri(obj, currentScheme)
            arguments
                obj bot.internal.fileresource.abstract.S3Bucket % Object of this class
                currentScheme string {mustBeMember(currentScheme, ["s3", "https", "file", ""])} = ""
            end
            
            if currentScheme == ""
                currentScheme = obj.PreferredScheme;
            end

            switch lower(currentScheme)
                case 's3'
                    baseURI = obj.S3BaseUri;
                case 'https'
                    baseURI = obj.S3BaseUrl;
                case 'file'
                    baseURI = "file://" + obj.S3LocalMount;
            end

            folderURI = uriJoin( baseURI, obj.RootFolderName );
        end
    
        % function relativePathURI = getRelativeFileUriPath(obj, itemObject, fileNickname, varargin) %#ok<INUSL> 
        % 
        %     itemClassName = class(itemObject);
        %     itemClassNameSplit = strsplit(itemClassName, '.');
        % 
        %     filenameLookupFcn = str2func(sprintf('%s.get%sFileRelativePath', class(obj), itemClassNameSplit{end}));
        % 
        %     relativePathURI = filenameLookupFcn(itemObject, fileNickname, varargin{:});
        % end

    end

    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
        
            arguments
                clearResource (1,1) logical = false
            end

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = bot.internal.fileresource.abstract.S3Bucket();
            end
            
            % - Return the instance
            fileResource = FILE_RESOURCE;
            
            % - Clear the fle resource if requested
            if clearResource
                FILE_RESOURCE = [];
                clear fileResource;
            end
        end
    end

end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    strURI = bot.internal.util.uriJoin(varargin{:});
end
