classdef URILookup
%URILookup Enumeration class wrapping available file resources

% Todo: Remove this, as it will be / is being replaced by  HasFileResource
% mixin class

    properties
        % An instance of a file resource for the Allen Brain Observatory
        FileResourceInstance bot.internal.abstract.FileResource = ...
            bot.internal.fileresource.S3Bucket.instance()
    end

    enumeration
        S3  ( bot.internal.fileresource.S3Bucket.instance() )
        API ( bot.internal.fileresource.WebApi.instance() )
    end
    
    methods
        function obj = URILookup(fileSourceInstance)
            %URILookup Construct an instance of this class
            %   Detailed explanation goes here
            obj.FileResourceInstance = fileSourceInstance;
        end
        
        function tf = isMounted(obj)
        %isMounted Determine whether file resource is mounted locally
            tf = obj.FileResourceInstance.isMounted();
        end

        function strURI = getDataFileURI(obj, varargin)
            strURI = obj.FileResourceInstance.getDataFileURI(varargin{:});
        end

        function strURI = getItemTableURI(obj, varargin)
            strURI = obj.FileResourceInstance.getItemTableURI(varargin{:});
        end
    end

    methods (Static)
        function members = getMembers()
            filename = mfilename('class');
            [~, members] = enumeration(filename);
        end
    end
end