
% An example of:
%  1) reading in the ophys_experiments.json file and converting it to a matlab table
%  2) downloading a nwb file from an experiment



% read in the ophys_experiments.json as text
fname = 'ophys_experiments.json'; 
fid = fopen(fname);
raw = fread(fid,inf);
json_raw_text = char(raw');
fclose(fid);

% parse the json file to a struct
json_struct = jsondecode(json_raw_text);

% convert the struct to a Matlab table
experiment_table = struct2table(json_struct);




% example 1: get only the sessions where the imaging depth was 275
experiment_table(experiment_table.imaging_depth == 275, :)



% example 2a: get the NWB file URL for the first experiment
allen_institute_base_url = 'http://api.brain-map.org';
first_experiment = experiment_table(1, :)
url_info = first_experiment.well_known_files
full_url = [allen_institute_base_url url_info.download_link]


% example 2b: now download the file...
save_directory_name = 'nwb_files/';
if ~exist(save_directory_name)
    mkdir(save_directory_name);
end

save_file_name = [save_directory_name num2str(first_experiment.id) '.nwb']

outfilename = websave(save_file_name, full_url)








