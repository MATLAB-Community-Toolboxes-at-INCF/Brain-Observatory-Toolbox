
%% A tutorial of:
%  1) downloading needed files from brain observatory api and converting them to matlab tables
%  2) building a brain_observatory_cache object to a) get general information of the whole brain observatory dataset
%                                                  b) select sessions by
%                                                  conditions such as brain
%                                                  areas, imaging depth and
%                                                  stimuli
%                                                  c) download nwb files of selected sessions
%  3) importing imgaging data from nwb files to a) get fluorescence traces
%                                               b) plot fluorescence traces
%                                               c) transform the interested 
%                                                  fluorescence trace data of
%                                                  the interested subexperiment 
%                                                  into raster formats for decoding
%% important information about this dataset:
%
% An "experiment container" (named by allen institute) 
% contains a set of "subexperiments" (defined by us as one subexperiment only 
% adopted one kind of stimuli, allen institue doesn't seem to have a name 
% for this concept) that were operated on a singe mouse, recorded in
% a single brain space (same targeted_structure and same imaging depth),
% performed during one out of three sessions (allen institue equates
% "session"
% with "ophys_experiment", in allen_sdk they use "ophys_experiment, in whitepapers
% they use "session").
%
% Different sessions in the same experiment container 
% may have adopted the same stimulus, which means they may share the same type of
% "subexperiment":
% 
% session_by_stimuli.three_session_A = {'drifting_gratings','natural_movie_one','natural_movie_three','spontaneous_activity'};
%             session_by_stimuli.three_session_B = {'static_gratings','natural_scene','natural_movie_one','spontaneous_activity'};
%             session_by_stimuli.three_session_C = {'locally_sparse_noise_four_degree','natural_movie_one','natural_movie_two','spontaneous_activity'};
%             session_by_stimuli.three_session_C2 = {'locally_sparse_noise_four_degree','locally_sparse_noise_eight_degree', ...
%                 'natural_movie_one','natural_movie_two','spontaneous_activity'};
%
%
% our shorthand:
% container = experiment_container
% 
% the three names we use:
% container > session > subexperiment
%% 0) 

% set your bot_dir
bot_dir_name = '/om/user/xf15/Brain-Observatory-Toolbox/';

% add path to bot_dir
addpath(bot_dir_name)

%% 1) download needed files from brain observatory api and converting them to matlab tables

get_files_from_brain_obs_api()

load('references')

%% 2) build a brain_observatory_cache object

% building a brain_observatory_cache object
boc = brain_observatory_cache (references)


%% 2a) get general information of the whole brain observatory dataset


boc.get_total_of_containers()
boc.get_all_imaing_depths()
boc.get_all_cre_lines()
boc.get_all_targeted_structures()
boc.get_all_session_types()
boc.get_all_stimuli()
boc.get_summary_of_container_along_targeted_structures()
boc.get_summary_of_containers_along_imaing_depths()
boc.get_summary_of_containers_along_depths_and_structures()

%% 2b) select sessions by conditions such as brain areas, imaging depth and stimuli

% Example: search for experiments that primary visual cortex was
% recorded at 275 mm deep as drifting gratings were shown

% reinitialize to have a "clean start"
boc = brain_observatory_cache (references)

% set conditions
boc.get_sessions_by_stimuli('drifting_gratings')
boc.get_sessions_by_targeted_structure('VISp')
boc.get_sessions_by_imaging_depth(275)
boc.get_sessions_by_container_id(527550471)

% get more detailed metedata of selected session(s)
boc.selected_session_table

% % you can also use brain_observatory_cache to look up metedata of
% % selected session(s) by container_id or session_id
% %
% boc = brain_observatory_cache(references)
% boc.get_sessions_by_container_id (506823562)
% boc.get_sessions_by_session_id (527676626)

%% 2c) download nwb files of selected sessions

% download nwb file of the first session in selected sessions into a directory called nwb_files
nwb_dir_name = [bot_dir_name,'nwb_files/'];

% the size of a nwb file is at the scale of 100 MB
boc.get_session_data(nwb_dir_name);

%% 3 import imgaging data from nwb files

% add path to nwb files
addpath ([bot_dir_name, 'nwb_files/'])

%% 3a) get_fluorescence_traces_of_selected_session

[raw,demixed,neuropil_corrected,DfOverF] = get_fluorescence_traces_of_selected_session (boc.session_id);

%% 3b) plot the f traces of one cell in session 517745328

cell_specimen_id = 529022196;
plot_fluorecence_traces_of_selected_cell_in_selected_session(boc.session_id,cell_specimen_id);

%% 3c) transform data of the selected fluorescence trace of the selected subexperiment into raster format

raster_dir_name = [bot_dir_name, 'raster/'];

stimuli = 'drifting_gratings';
fluorescence_trace = DfOverF;

current_raster_dir_name = transform_fluorescenece_trace_into_raster_format(fluorescence_trace,...
    boc.session_id, stimuli,raster_dir_name);
