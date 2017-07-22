
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
%% 1) download needed files from brain observatory api and converting them to matlab tables

get_files_from_brain_obs_api()

load('references')

%% 2) build a brain_observatory_cache object

% building a brain_observatory_cache object
boc = brain_observatory_cache (references)

%% 2a) get general information of the whole brain observatory dataset

boc.get_all_targeted_structures() 
boc.get_all_session_types()
boc.get_all_stimuli()


%% 2b) select sessions by conditions such as brain areas, imaging depth and stimuli

% Example: search for experiments that primary visual cortex was
% recorded at 275 mm deep as drifting gratings were shown

% set conditions
boc.stimuli = 'drifting_gratings'
boc.targeted_structure = 'VISp'
boc.imaging_depth = 275

% %  all filters are optional; all successful experiments will be returned if no filter
% %  is applied
% % 
% % failed experiments (in the unit of experiment containers) are excluded by default as property "failed" is set to
% % 0 by default 
% % to disable this feature, set "failed" to nonzero
% %
% boc.failed = 1
% % 
% % you can also use brain_observatory_cache to look up manifest of
% % selected session(s) by container_id or session_id
% % make sure you have a new "empty" brain_observatory_cache object before you do this
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

%% c) download nwb files of selected sessions

% download the first session in selected sessions into a directory called nwb_files
boc.session_id = session_id
boc.get_session()
save_directory_name = 'nwb_files/';
boc.get_session_data(save_directory_name);
