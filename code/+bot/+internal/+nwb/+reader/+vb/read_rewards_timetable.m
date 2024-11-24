function rewards_timetable = read_rewards_timetable(nwbFilePath)
% read_rewards_timetable - Read rewards data as time table

    % Define datasets to read from
    nwbGroupPath = "/processing/rewards";
    nwbDatasetPath = dictionary(...
            "volume", nwbGroupPath + "/volume", ...
        "autoreward", nwbGroupPath + "/autorewarded/data" );       

    % Verify that dataset is present
    if ~bot.internal.nwb.has_path(nwbFilePath, nwbDatasetPath("volume"))
        error('BOT:DataNotPresent', 'This session has no reward data.');
    end
    
    % Read rewards data (volumes)
    rewards_table = bot.internal.nwb.table_from_datasets(...
        nwbFilePath, nwbDatasetPath("volume") );
    
    rewards_table.timestamps = seconds(rewards_table.timestamps);
    rewards_timetable = table2timetable(rewards_table);
    rewards_timetable.Properties.VariableNames = {'volume'};
    
    % Read boolean vector for autorewarded rewards
    autorewarded = h5read(nwbFilePath, nwbDatasetPath("autoreward"));
    autorewarded = strcmp( autorewarded, 'TRUE' );
    rewards_timetable.auto_rewarded = autorewarded;
end
