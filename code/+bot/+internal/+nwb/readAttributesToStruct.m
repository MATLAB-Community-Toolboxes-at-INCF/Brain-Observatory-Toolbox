function dataStruct = readAttributesToStruct(pathName, attributesMapping)
% readAttributesToStruct - Reads attributes from an h5 file and stores them in a struct.
%
% This function attempts to read each of the attributes from the specified 
% h5 file using the provided attributesMapping. It reads data entries 
% associated with each attribute and stores them in a struct.
%
%   Syntax:
%       S = readAttributesToStruct(filename, attributesMapping)
%
%   Input Arguments:
%       pathName          - Pathname of the h5 file to read attributes from.
%       attributesMapping - Mapping of names to their corresponding group 
%                           path and attribute names in the h5 file.
%
%   Output Arguments:
%       S - Struct containing the data for each field in attributesMapping
%
%   Example:
%       filename = 'example.h5';
%       mapping = struct('Attribute1', {{'/path/to/groupWithAttribute1', attribute1Name}}, ...
%                        'Attribute2', {{'/path/to/groupWithAttribute2', attribute2Name}} );
%       resultStruct = readAttributesToStruct(filename, mapping);

    dataStruct = attributesMapping;
    for fieldname = fieldnames(attributesMapping)'
        
        % - Convert to a string (otherwise it would be a cell)
        fieldname = fieldname{1}; %#ok<FXSET>
        groupName = dataStruct.(fieldname){1};
        attributeName = dataStruct.(fieldname){2};

        % - Try to read this metadata entry
        try
            dataStruct.(fieldname) = h5readatt(pathName, groupName, attributeName);
        catch
            dataStruct.(fieldname) = [];
        end
    end
end
