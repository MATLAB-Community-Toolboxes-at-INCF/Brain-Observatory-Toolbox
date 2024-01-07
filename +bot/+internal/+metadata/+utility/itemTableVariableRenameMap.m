function nameMap = itemTableVariableRenameMap()
% itemTableVariableRenameMap - Return a map for renaming table variables

    nameMap = dictionary();
    nameMap('ephys_structure_acronyms') = 'targeted_structure_acronyms';
    nameMap('structure_acronyms') = 'targeted_structure_acronyms';

    % Mapping names from visual coding to match with visual behavior
    nameMap('specimen_id') = 'mouse_id';
    nameMap('stimulus_name') = 'session_type';

    % Visual behavior Ephys
    nameMap('genotype') = 'full_genotype';

    nameMap('ecephys_session_id') = 'ephys_session_id';
    nameMap('ecephys_probe_id') = 'ephys_probe_id';
    nameMap('use_lfp_data') = 'has_lfp_data';

    nameMap('ecephys_channel_id') = 'ephys_channel_id';

    

end
    