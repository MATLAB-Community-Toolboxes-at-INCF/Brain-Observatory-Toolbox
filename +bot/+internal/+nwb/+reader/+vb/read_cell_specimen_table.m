function cell_specimen_table = read_cell_specimen_table(nwbFilePath)
% read_cell_specimen_table - Read cell specimen data as a table

    % Define datasets to read from
    nwbDatasetPath = "/processing/ophys/image_segmentation/cell_specimen_table/";
    
    % Verify that dataset is present
    if ~bot.internal.nwb.has_path(nwbFilePath, nwbDatasetPath)
        error('BOT:DataNotPresent', 'This session has no cell specimen data.');
    end
    
    % Read cell specimen data as a table:
    cell_specimen_table = bot.internal.nwb.table_from_datasets_new_ll(...
        nwbFilePath,  nwbDatasetPath );

    % Convert data types to logicals
    cell_specimen_table.valid_roi = logical(cell_specimen_table.valid_roi);
    cell_specimen_table.image_mask = logical(cell_specimen_table.image_mask);

    % Rename id to cell_roi_id
    cell_roi_id = cell_specimen_table.id;
    cell_specimen_table = addvars(cell_specimen_table, cell_roi_id, 'After', "cell_specimen_id");
    cell_specimen_table = removevars(cell_specimen_table, 'id');
    
    % Convert each image mask to a cell and rename image_mask to roi_mask
    roi_mask = cell_specimen_table.image_mask;
    roi_mask = mat2cell(roi_mask, ones(height(cell_specimen_table),1),512,512);
    % Note: Squeeze and transpose mask to get dimensions in the right order
    roi_mask = cellfun(@(c) squeeze(c)', roi_mask, 'UniformOutput', false);
    cell_specimen_table.roi_mask = roi_mask;
    cell_specimen_table = removevars(cell_specimen_table, 'image_mask');
end
    