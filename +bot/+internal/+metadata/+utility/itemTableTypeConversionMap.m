function map = itemTableTypeConversionMap()
% itemTableTypeConversionMap - Provide a map of type conversion functions
    
    persistent dict; 
    if ~isempty(dict)
        map = dict;
        return
    end
    
    dict = dictionary();
    
    % Id variables:
    dict('id')                      = @uint32;
    dict('behavior_session_id')     = @uint32;
    dict('ophys_session_id')        = @uint32;
    dict('ecephys_session_id')      = @uint32;
    dict('ephys_session_id')        = @uint32;
    %dict('ophys_experiment_id')    = @uint32; % Resolve. Sometimes this is an array, sometimes not
    %dict('ophys_container_id')     = @uint32; % Resolve. Sometimes this is an array, sometimes not
    dict('mouse_id')                = @uint32;
    dict('experiment_container_id') = @uint32;
    dict('isi_experiment_id')       = @uint32;
    dict('file_id')                 = @uint32;
    dict('cell_roi_id')             = @uint32;
    dict('cell_specimen_id')        = @uint32;
    dict('ephys_probe_id')          = @uint32;
    dict('ephys_channel_id')        = @uint32;
    dict('unit_id')                 = @uint32;
    
    % Categoricals
    dict('sex')                     = @categorical;
    dict('session_type')            = @categorical;
    dict('image_set')               = @categorical;
    dict('behavior_type')           = @categorical;
    dict('equipment_name')          = @categorical;
    dict('indicator')               = @categorical;
    dict('project_code')            = @categorical;
    dict('experience_level')        = @categorical;
    dict('targeted_structure')      = @categorical;
    dict('experience_level')        = @categorical;

    dict('phase')                   = @categorical;

    % Genotypes
    dict('full_genotype')           = @string;
    dict('cre_line')                = @string;
    dict('reporter_line')           = @string;
    
    % Misc
    dict('storage_directory')       = @string;
    dict('name')                    = @string;
    dict('passive')                 = @(x) strcmp(x, "True");
    dict('has_lfp_data')            = @(x) strcmp(x, "True");
    dict('valid_data')              = @(x) strcmp(x, "True");

    % Character vector to numeric arrays
    dict('ophys_experiment_id') = @(x) cellfun(@(c) uint32(eval(c)), x, 'uni', 0);
    dict('ophys_container_id')  = @(x) cellfun(@(c) uint32(eval(c)), x, 'uni', 0);

    % Character vector to string arrays 
    dict('driver_line')  = @(x) cellfun(@(c) eval( strrep(c, '''', '"') ), x, 'uni', 0);

    % Date
    % Todo: Verify that this is valid for all tables.
    dict('date_of_acquisition') = @(x) datetime(x, ...
        'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
    
    % It seems to be variable:
    %BehaviorSession (VB Ophys):  2019-05-24 11:06:39.332000+00:00
    %OphysSession (VB Ophys):     2019-12-17 11:17:36.617000
    %EphysSession (VB Ephys):     2021-08-26 14:32:42.128000+00:00
    map = dict;
end
