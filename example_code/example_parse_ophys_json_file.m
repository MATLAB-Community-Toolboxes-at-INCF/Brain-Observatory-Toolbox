
% An example of:
%  1) reading in the ophys_experiments.json file and converting it to a matlab table
%  2) downloading a nwb file from an experiment


% pull all json files into a temporary folder
filePattern = fullfile('manifest_json','*.json');
theFiles = dir(filePattern);

% create empty structure to store all manifest tables
all_manifests = [];

for file = 1 : length(theFiles)
    baseFileName = theFiles(file).name;
    fid = fopen(fullFileName);
    % read in json files as text
    raw =  fread(fid, inf);
    manifest_raw_text = char (raw');
    fclose(fid);
    % parse the json files to structs
    manifest_struct = jsondecode(manifest_raw_text);
    % convert the structs to Matlab tables
    all_manifests.(baseFileName(1:length(baseFileName)-5)) =  struct2table(manifest_struct);
end

% create cre_lines table
cont_table = all_manifests.experiment_containers;
cre_lines = cell(size(cont_table,1),1);
for i = 1:size(cont_table,1)
    donor_info = cont_table(i,:).specimen.donor;
    transgenic_lines_info = struct2table(donor_info.transgenic_lines);
    cre_lines(i,1) = transgenic_lines_info.name(string(transgenic_lines_info.transgenic_line_type_name) == 'driver' & ...
            contains(transgenic_lines_info.name, 'Cre'));
end

% append cre_lines table to exp_cont table
all_manifests.experiment_containers = [cont_table, cre_lines]
all_manifests.experiment_containers.Properties.VariableNames{'Var13'} = 'cre_lines'

% save the manifest strucre
save('all_manifests','all_manifests');


% search for experiments by conditions
% all filters are optional; all successful experiments will be returned if no filter
% is applied

% Example 1: search for experiments that primary visual cortex was
% recorded at 275 mm deep as drifting gratings were shown
selected_exp = basic_selected_exp(all_manifests)
selected_exp.stimuli = 'drifting_grating'
selected_exp.targeted_structure = 'VISp'
selected_exp.image_depth = 275

% % failed experiments are excluded by default as property "failed" is set to
% % be 0 as default. to disable this feature, set "failed" to nonzero
% selected_exp.failed = 

% % other two filters:
% selected_exp.exp_cont_id =
% selected_exp.exp_id =

% get meta data for passed experiments
selected_table = get_info(selected_exp, session_by_stimuli)

% get id of the first experiment in the current list
exp_id = selected_table.id(1)



% get the NWB file URL for the first experiment in the current list
allen_institute_base_url = 'http://api.brain-map.org';
first_experiment = selected_table(1, :)
url_info = first_experiment.well_known_files
full_url = [allen_institute_base_url url_info.download_link]
% watch out: online file id differs from experiment id 

% now download the file...
save_directory_name = 'nwb_files/';
if ~exist(save_directory_name)
    mkdir(save_directory_name);
end

save_file_name = [save_directory_name num2str(first_experiment.id) '.nwb']

outfilename = websave(save_file_name, full_url)









