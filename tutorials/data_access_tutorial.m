
% A tutorial of:
%  1) download needed files from brain observatory api and converting them to matlab tables
%  2) building a brain_observatory_cache object to a) get general information of the whole brain observatory dataset
%                                                  b) select sessions by conditions such as brain areas, imaging depth and stimuli
%                                                  c) download nwb files of selected sessions
%
%% important information:
%
% an experiment container (named by allen institute) 
% contains a set of subexperiments (defined by us as one subexperiment only 
% adopted one kind of stimuli) operated on a singe mouse, recorded in
% a single brain space (same targeted_structure and same imaging depth),
% performed during one of three sessions (allen institue equated session
% with experiment), that may have adopted the same stimulus as another
% subexperiment in another session within the same experiment container.
% 
% our shorthand:
% container = experiment_container
% 
% the three names we use:
% container > session > subexperiment
%
%% 0) 

% set your base_directory 
base_dir_name = '/om/user/xf15/Brain-Observatory-Toolbox/';

% add path to sdk
addpath([base_dir_name, 'sdk/data_access/'])

%% 1) download needed files from brain observatory api and converting them to matlab tables

get_files_from_brain_obs_api()

load('references')

%% 2) build a brain_observatory_cache object

% building a brain_observatory_cache object
boc = brain_observatory_cache (references)


%% 2a) get general information of the whole brain observatory dataset


boc.get_total_of_containers()
boc.get_summary_of_container_along_targeted_structures()
boc.get_summary_of_containers_along_imaing_depths()
boc.get_all_imaing_depths()
boc.get_all_cre_lines()
boc.get_all_targeted_structures()
boc.get_all_session_types()
boc.get_all_stimuli()
boc.get_summary_of_containers_along_depths_and_structures()

%% 2b) select sessions by conditions such as brain areas, imaging depth and stimuli

% Example: search for experiments that primary visual cortex was
% recorded at 275 mm deep as drifting gratings were shown

% set conditions
boc.stimuli = 'drifting_gratings'
boc.targeted_structure = 'VISp'
boc.imaging_depth = 275

% %  all filters are optional; all sessions will be retu% % reading in all manifest files and converting them to matlab tables
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
% save('all_manifests','all_manifests');rned if no filter
% %  is applied
% % 
% % 
% % you can also use brain_observatory_cache to look up manifest of
% % selected session(s) by container_id or session_id
% % 
% %
% boc = brain_observatory_cache(references)
% boc.container_id = 527550471
% boc.session_id = 527745328

%  pass conditions
boc.get_session()

% get manifest of selected sessions
boc.selected_session_table

% get id of the first session in the current list for fun
session_id = boc.selected_session_table.id(1)

%% 2c) download nwb files of selected sessions

% download the first session in selected sessions into a directory called nwb_files
boc.session_id = session_id
boc.get_session()
save_directory_name = [base_dir_name,'nwb_files/'];
boc.get_session_data(save_directory_name);
