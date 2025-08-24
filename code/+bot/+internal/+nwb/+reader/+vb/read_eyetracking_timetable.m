function eye_tracking_timetable = read_eyetracking_timetable(nwbFilePath)
% read_eyetracking_timetable - Read eyetracking data as time table

    % Define datasets to read from
    nwbGroupPath = "/acquisition/EyeTracking";
    nwbDatasetPath = dictionary(...
          "eye", nwbGroupPath + "/eye_tracking", ...
        "pupil", nwbGroupPath + "/pupil_tracking", ...
        "blink", nwbGroupPath + "/likely_blink/data" );
    
    % Verify that dataset is present
    if ~bot.internal.nwb.has_path(nwbFilePath, nwbDatasetPath("pupil"))
        error('BOT:DataNotPresent', 'This session has no pupil data.');
    end
    
    % Read and rearrange pupil data:
    pupil_data_table = bot.internal.nwb.table_from_datasets(...
        nwbFilePath,  nwbDatasetPath("pupil"), {'reference_frame'});
    
    pupil_data_table = decoupleCenterCoords(pupil_data_table);
    pupil_data_table = movevars(pupil_data_table, "angle", "After", 'width');
    pupil_data_table = prefixToVariableNames(pupil_data_table, 'pupil');
    
    % Read and rearrange eye data:
    eye_tracking_table = bot.internal.nwb.table_from_datasets(...
        nwbFilePath, nwbDatasetPath("eye"), {'reference_frame'});
    
    eye_tracking_table = decoupleCenterCoords(eye_tracking_table);
    eye_tracking_table = movevars(eye_tracking_table, "angle", "After", 'width');
    eye_tracking_table.timestamps = seconds(eye_tracking_table.timestamps);
    eye_tracking_timetable = table2timetable(eye_tracking_table);    
    eye_tracking_timetable = prefixToVariableNames(eye_tracking_timetable, 'eye');

    % Read likely blinks:
    likely_blink = h5read(nwbFilePath, nwbDatasetPath("blink"));
    likely_blink = strcmpi(likely_blink, 'true');
    
    % Add blinks and pupil data to eyetracking timetable
    eye_tracking_timetable = addvars(eye_tracking_timetable, likely_blink, 'Before', 'eye_area');
    eye_tracking_timetable = cat(2, eye_tracking_timetable, pupil_data_table);
end 

function tbl = decoupleCenterCoords(tbl)
% decoupleCenterCoords - Decouple center coordinates and add them as
% individual variables in the table.
%
%   Note: center coords are stored as a nx2 matrix in the "data" variable 
%   of the eye and pupil tables.
    center_x = tbl.data(:, 1);
    center_y = tbl.data(:, 2);
    tbl = removevars(tbl, 'data');
    tbl = addvars(tbl, center_x, center_y, 'After', 3);
end

function tbl = prefixToVariableNames(tbl, prefix)
% prefixToVariableNames - Add a prefix to variable names of a table
    tbl.Properties.VariableNames = strcat(prefix, '_', tbl.Properties.VariableNames);
end
