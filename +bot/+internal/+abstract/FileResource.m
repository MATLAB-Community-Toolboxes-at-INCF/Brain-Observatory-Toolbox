classdef FileResource < handle
%FileResource Abstract class for a file resource
%
%   A file resource class provides methods for getting URIs for files that
%   are available through the Allen Brain Observatory. 

    methods (Abstract)
        tf = isMounted(obj)

        strURI = getDataFileURI(obj, itemObject, fileNickname, varargin)

        strURI = getItemTableURI(obj, datasetType, itemType)
    end

end