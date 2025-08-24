function metadata = readGeneralMetadata(nwbFileName)
% readGeneralMetadata - Read general metadata from an NWB file

    import bot.internal.nwb.readDatasetsToStruct
    import bot.internal.nwb.readAttributesToStruct

    DATASET_MAPPING = struct(...
        'institution', '/general/institution', ...
        'devices', '/general/devices', ...
        'description', '/general/experiment_description', ...
        'session_description', '/session_description', ...
        'session_start_time', '/session_start_time', ...
        'keywords', '/general/keywords' );

    ATTRIBUTES_MAPPING = struct(...
        'allen_project_code', {{'/general/metadata', 'project_code' }}, ...  % NB: Documentation says /general/project_code
        'equipment_name', {{'/general/metadata', 'equipment_name' }}, ...
        'session_type', {{'/general/metadata', 'session_type' }} ...
    );
    
    metadata = readDatasetsToStruct(nwbFileName, DATASET_MAPPING);
    metadata = structfun(@(v) string(v), metadata, 'UniformOutput', false);

    metadata = bot.internal.util.structmerge(metadata, ...
        readAttributesToStruct(nwbFileName, ATTRIBUTES_MAPPING));

    if isfield(metadata, 'keywords') && ~isempty(metadata.keywords)
        metadata.keywords = reshape(metadata.keywords, 1, []);
    end

    % Convert session start time to datetime value
    if isfield(metadata, 'session_start_time') && ~isempty(metadata.session_start_time)
        dateString = metadata.session_start_time;
        
        % Patterns and matching datetime input formats
        pattern = {'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{6}\+\d{2}:\d{2}', 'yyyy-MM-dd''T''HH:mm:ss.SSSSSSZ'; ...
                   '\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\+\d{2}:\d{2}', 'yyyy-MM-dd''T''HH:mm:ssZ'};
        
        inFormat = '';
        for i = 1:size(pattern, 1)
            if ~isempty(regexp(dateString, pattern{i,1}, 'once'))
                inFormat = pattern{i,2};
                break
            end
        end

        if ~isempty(inFormat)
            dateTimeObj = datetime(dateString, 'InputFormat', inFormat, 'TimeZone','UTC');
            metadata.session_start_time = dateTimeObj;
        else
            try
                dateTimeObj = datetime(dateString);
                metadata.session_start_time = dateTimeObj;
            catch ME
                warning(ME.identifier, '%s', ME.message)
            end
        end
    end
    
    % Todo: Format name
end