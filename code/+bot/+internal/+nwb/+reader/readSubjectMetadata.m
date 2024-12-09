function metadata = readSubjectMetadata(nwbFileName)
% readSubjectMetadata - Read subject metadata from an NWB file

    import bot.internal.nwb.readDatasetsToStruct

    FILE_METADATA_MAPPING = struct(...
        'age', '/general/subject/age', ...
        'description', '/general/subject/description', ...
        'genotype', '/general/subject/genotype', ...
        'sex', '/general/subject/sex', ...
        'species', '/general/subject/species', ...
        'identifier', '/general/subject/subject_id' );

    SEX_MAPPING = dictionary('M', 'male', 'F', 'female');
    
    metadata = readDatasetsToStruct(nwbFileName, FILE_METADATA_MAPPING);
    
    if isfield(metadata, 'sex') && ~isempty(metadata.sex)
        if isKey(SEX_MAPPING, metadata.sex)
            metadata.sex = SEX_MAPPING(metadata.sex);
        end
    end
    
    % Todo: Format name
end
