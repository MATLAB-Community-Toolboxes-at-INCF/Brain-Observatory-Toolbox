function lick_data = read_lick_timetable(nwbFilePath)
% read_lick_timetable - Read lick data as a timetable
    
    nwbDatasetPath = '/processing/licking/licks/';
    
    if ~bot.internal.nwb.has_path(nwbFilePath, nwbDatasetPath)
    error('BOT:DataNotPresent', 'This session has no lick data.');
    end
    
    lick_data = bot.internal.nwb.table_from_datasets(nwbFilePath, nwbDatasetPath );
    timestamps = seconds(lick_data.timestamps);
    lick_data = timetable(timestamps, lick_data.data, 'VariableNames', {'frame'});
end
