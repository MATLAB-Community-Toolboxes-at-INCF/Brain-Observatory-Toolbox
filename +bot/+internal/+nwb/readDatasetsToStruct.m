function dataStruct = readDatasetsToStruct(pathName, datasetMapping)
% readDatasetsToStruct - Reads datasets from an h5 file and stores them in a struct.
%
% This function attempts to read each of the datasets from the specified 
% h5 file using the provided datasetMapping. It reads data entries 
% associated with each dataset and stores them in a struct.
%
%   Syntax:
%       S = readDatasetsToStruct(filename, datasetMapping)
%
%   Input Arguments:
%       pathName       - Pathname of the h5 file to read datasets from.
%       datasetMapping - Mapping of dataset field names to their 
%           corresponding dataset path names in the h5 file.
%
%   Output Arguments:
%       S - Struct containing the data for each field in datasetMapping
%
%   Example:
%       filename = 'example.h5';
%       mapping = struct('Dataset1', '/path/to/dataset1', ...
%                        'Dataset2', '/path/to/dataset2');
%       resultStruct = readDatasetsToStruct(filename, mapping);

    dataStruct = datasetMapping;
    for fieldname = fieldnames(datasetMapping)'
        
        % - Convert to a string (otherwise it would be a cell)
        fieldname = fieldname{1}; %#ok<FXSET>
        
        % - Try to read this metadata entry
        try
            dataStruct.(fieldname) = h5read(pathName, dataStruct.(fieldname));
        catch
            dataStruct.(fieldname) = [];
        end
    end

end
