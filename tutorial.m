
%% A tutorial of:
%  1) downloading needed files from brain observatory api and converting them to matlab tables
%  2) building a brain_observatory_cache object to a) get general information of the whole brain observatory dataset
%                                                  b) select sessions by
%                                                  conditions such as brain
%                                                  areas, imaging depth and
%                                                  stimuli
%                                                  c) download nwb files of selected sessions
%  3) importing imgaging data from nwb files to a) plot fluorescence traces
%                                               b) transform them into raster formats for decoding
%% important information about this dataset:
%
% an experiment container (named by allen institute) 
% contains a set of subexperiments (defined by us as one subexperiment only 
% adopted one kind of stimuli) operated on a singe mouse, recorded in
% a single brain space (same targeted_structure and same imaging depth),
% performed during one out of three sessions (allen institue equated session
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
addpath([base_dir_name, 'sdk/'])

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
boc.stimuli = 'drifting_gratings'
boc.targeted_structure = 'VISp'
boc.imaging_depth = 275

% %  all filters are optional; all sessions will be returned if no filter
% %  is applied 
% % 
% % you can also use brain_observatory_cache to look up manifest of
% % selected session(s) by container_id or session_id
% %
% boc = brain_observatory_cache(references)
% boc.container_id = 527550471
% boc.session_id = 527745328

%  pass conditions
boc.get_session()
boc

% get manifest of selected sessions
boc.selected_session_table

% get id of the first session in the current list for fun
session_id = boc.selected_session_table.id(1)

%% 2c) download nwb files of selected sessions

% download nwb file of the first session in selected sessions into a directory called nwb_files
boc.session_id = session_id
boc.get_session()
nwb_dir_name = [base_dir_name,'nwb_files/'];

% the size of a nwb file is at the scale of 100 MB
boc.get_session_data(nwb_dir_name);

%% 3 import imgaging data from nwb files

% add path to nwb files
addpath ([base_dir_name, 'nwb_files/'])

%% 3a) plot fluorescence traces of the selcted cell from the selected session


% get fluoroscence traces of all cells in this session and plot ones of
% selected cells
session_id = 527745328;
cell_specimen_id = 529022196;

[raw,demixed,neuropil_corrected,DfOverF] = get_fluorescence_traces (session_id,cell_specimen_id);

%% 3b) transform data of the selected fluorescence trace of the selected subexperiment into raster format

raster_dir_name = [base_dir_name, 'raster/'];

stimuli = 'drifting_gratings';
fluorescence_trace = DfOverF;

current_raster_dir_name = transform_fluorescenece_trace_into_raster_format(fluorescence_trace,...
    session_id, stimuli,raster_dir_name);
