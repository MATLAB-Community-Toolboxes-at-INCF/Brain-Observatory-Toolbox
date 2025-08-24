function metadata = readOphysMetadata(nwbFileName)
% readOphysMetadata - Read ophys metadata from an NWB file

    import bot.internal.nwb.readDatasetsToStruct
    import bot.internal.nwb.readAttributesToStruct

    DATASET_MAPPING = struct(...
        'description', '/general/optophysiology/imaging_plane_1/description', ...
        'excitation_lambda', '/general/optophysiology/imaging_plane_1/excitation_lambda', ...
        'indicator', '/general/optophysiology/imaging_plane_1/indicator', ...
        'location', '/general/optophysiology/imaging_plane_1/location', ...
        'imaging_rate', '/general/optophysiology/imaging_plane_1/imaging_rate' );

    ATTRIBUTES_MAPPING = struct(...
        'fov_width', {{'/general/metadata', 'field_of_view_width' }}, ...  % NB: Documentation says /general/project_code
        'fov_height', {{'/general/metadata', 'field_of_view_height' }}, ...
        'imaging_depth', {{'/general/metadata', 'imaging_depth' }} ); 
    
    metadata = readDatasetsToStruct(nwbFileName, DATASET_MAPPING);
    metadata = structfun(@(v) string(v), metadata, 'UniformOutput', false);

    metadata = bot.internal.util.structmerge(metadata, ...
        readAttributesToStruct(nwbFileName, ATTRIBUTES_MAPPING));

    
    % Todo: Format name

    % Todo: Convert session start time to datetime value
    
end