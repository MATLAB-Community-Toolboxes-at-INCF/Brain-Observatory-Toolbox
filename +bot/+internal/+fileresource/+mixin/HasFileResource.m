classdef HasFileResource < handle
% HasFileResource - Provides methods for resolving remote file locations
%
%   This mixin class is used to resolve the remote (cloud) locations of
%   files belonging to any of the Allen Brain Observatory datasets. 
%
%   It provides two methods:
%       getFileUrl - Return the URL for a file associated with an item
%       getItemTableUrl - [Not implemented yet] Return the URL for a file containing an item 
%                         table for items of specified types.
%
%   This class internally holds file resources for the different datasets,
%   and will select the resource matching the dataset and dataset type of
%   a provided item (or data manifest).
%
%   Syntax:
%       downloadUrl = obj.getFileUrl(itemObject, fileNickname)


    properties (Constant, Access=private)
        ApiFileResource = bot.internal.fileresource.WebApi.instance()
        S3FileResource = dictionary(...
            "VisualCodingEphys", bot.internal.fileresource.visualcoding.VCEphysS3Bucket.instance(), ...
            "VisualCodingOphys", bot.internal.fileresource.visualcoding.VCOphysS3Bucket.instance(), ...
            "VisualBehaviorEphys", bot.internal.fileresource.visualbehavior.VBEphysS3Bucket.instance(), ...
            "VisualBehaviorOphys", bot.internal.fileresource.visualbehavior.VBOphysS3Bucket.instance() ...
            )
    end

    methods
        function downloadUrl = getFileUrl(obj, itemObject, fileNickname)
        % getFileUrl - Get download URL and local path for saving file.
        % 
        %   Syntax:
        %       downloadUrl = obj.getFileUrl(itemObject, fileNickname)
        %
        %   Input arguments:
        %       itemObject   - A bot item (i.e Session, Unit, Cell etc)
        %       fileNickname - Nickname of a file

            datasetName = itemObject.getDatasetName();
            datasetType = itemObject.getDatasetType();
            
            fileResource = obj.getFileResource(datasetName, datasetType);

            downloadUrl = fileResource.getDataFileURI(itemObject, fileNickname);
        end

        function downloadUrl = getItemTableUrl(obj, manifest, itemType)
            error('Not implemented yet')
        end
    end


    methods (Access = private)
        
        function fileResource = getFileResource(obj, datasetName, datasetType)
        % getFileResource - Get a file resource class for specified dataset
        %
        %   Syntax:
        %       fileResource = obj.getFileResource(datasetName, datasetType)

            arguments
                obj (1,1) bot.internal.fileresource.mixin.HasFileResource
                datasetName (1,1) string
                datasetType (1,1) string
            end

            prefs = bot.util.getPreferences();
            
            if prefs.DownloadFrom == "API"
                assert( datasetName == "VisualCoding", ...
                    "Download from API is only supported for the Visual Coding dataset")
                fileResource = obj.ApiFileResource;
            
            elseif prefs.DownloadFrom == "S3"
                fileResource = obj.S3FileResource(datasetName+datasetType);
            end
        end
    end
end