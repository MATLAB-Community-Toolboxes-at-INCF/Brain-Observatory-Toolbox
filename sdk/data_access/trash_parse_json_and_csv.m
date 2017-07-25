% % reading in all manifest files and converting them to matlab tables
% filePattern = fullfile('manifest_json','*.json');
% theFiles = dir(filePattern);
% for cur_file = 1 : length(theFiles)
%     baseFileName = theFiles(cur_file).name;
%     fullFileName = ['manifest_json/' baseFileName]
%     fid = fopen(fullFileName);
%     % read in json files as text
%     raw =  fread(fid, inf);
%     manifest_raw_text = char (raw');
%     fclose(fid);
%     % parse the json files to structs
%     manifest_struct = jsondecode(manifest_raw_text);
%     % convert the structs to Matlab tables
%     all_manifests.(baseFileName(1:length(baseFileName)-5)) =  struct2table(manifest_struct);
% end
% 
% % create cre_lines table and append it to exp_cont table (all experiments within an experiment container
% % were performed on a single rat and shared imaging plane 
% cont_table = all_manifests.experiment_containers;
% cre_lines = cell(size(cont_table,1),1);
% for i = 1:size(cont_table,1)
%     donor_info = cont_table(i,:).specimen.donor;
%     transgenic_lines_info = struct2table(donor_info.transgenic_lines);
%     cre_lines(i,1) = transgenic_lines_info.name(string(transgenic_lines_info.transgenic_line_type_name) == 'driver' & ...
%             contains(transgenic_lines_info.name, 'Cre'));
% end
% all_manifests.experiment_containers = [cont_table, cre_lines]
% all_manifests.experiment_containers.Properties.VariableNames{'Var13'} = 'cre_lines'
% 
% % add cell_specimen_mapping table to all_manifests
% filename = 'cell_specimen_mapping.csv';
% cell_id_mapping_array = csvread(filename,2);
% all_manifests.cell_specimen_mapping = array2table(cell_id_mapping_array,'VariableNames',...
%     {'old_cell_id',	'session_A_new_cell_id', 'session_B_new_cell_id','session_C_new_cell_id'});
% 
% % save the manifest strucre
% save('all_manifests','all_manifests');