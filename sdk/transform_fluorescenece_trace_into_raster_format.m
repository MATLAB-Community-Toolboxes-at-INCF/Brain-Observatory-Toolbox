function current_raster_dir_name = transform_fluorescenece_trace_into_raster_format(fluorescenece_trace,session_id, stimuli,raster_dir_name)

nwb_name = [num2str(session_id) '.nwb'];

sampling_times = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/timestamps');

stimuli_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimuli, '_stimulus/timestamps'));

container_id = h5read(nwb_name,'/general/experiment_container_id');

session_id = h5read(nwb_name,'/general/session_id');

session_type = h5read(nwb_name,'/general/session_type');

new_cell_specimen_ids = h5read(nwb_name, '/processing/brain_observatory_pipeline/ImageSegmentation/cell_specimen_ids');


% create a head directory 'ratser/' that store all ratser formats

if ~exist(raster_dir_name,'dir')
    mkdir(raster_dir_name);
end

% under the head directory 'raster/', create a current direcotry that store
% all raster formats returned from the current analysis
current_raster_dir_name = [stimuli,'_', session_id ,'/'];
current_raster_dir_name_full  = [raster_dir_name,current_raster_dir_name];

if ~exist(current_raster_dir_name_full ,'dir')
    mkdir(current_raster_dir_name_full );


% fetching some parameters (hardcoded inside the function) that define the raster data such as window
% frames, sampling frequency, etc.

parameters_for_cur_stimulus = fetch_stimuli_based_parameters(stimuli);

% generate raster_labels, apply to every cell in the same session

raster_labels = generate_raster_labels (nwb_name, stimuli);

% create raster files

for iCell = 1:size(fluorescenece_trace,2)
    
    cur_new_cell_id = new_cell_specimen_ids(iCell);
    
    cur_raster_file_name = [num2str(cur_new_cell_id), '.mat'];
    % raster_data is a matrix of k dimensions of trials by n dimensions of
    % time
    raster_data = generate_raster_data(iCell, fluorescenece_trace, parameters_for_cur_stimulus, sampling_times, stimuli_onset_times);
    
    raster_site_info = generate_raster_site_info(container_id, parameters_for_cur_stimulus,session_id,session_type,cur_new_cell_id);
    
    save([current_raster_dir_name_full , cur_raster_file_name], 'raster_data', 'raster_labels', 'raster_site_info');
    
end

fprintf ( [num2str(size(fluorescenece_trace,2)) ' cells transformed into raster formats.'])
fprintf ([' There are ' num2str(length(dir(current_raster_dir_name_full))-2) ' raster files in folder ' current_raster_dir_name_full])


else
    fprintf([current_raster_dir_name_full ' already exists'])
end
end


%  generate raster_data

function raster_data = generate_raster_data(i, fluorescenece_trace, parameters_for_cur_stimulus, sample_times, stimuli_onset_times)

cur_cell_data = fluorescenece_trace (:,i);

% preallocation of cell_matrix: a trial by time matrix of dfOVerF of a
% single cell

cur_cell_matrix = NaN * ones(size(stimuli_onset_times,1), parameters_for_cur_stimulus.sampling_points_after_onset...
    - parameters_for_cur_stimulus.sampling_points_before_onset +1);

onset = 1;
% looking for the closet sampling time to stimuli onset time
for iTrial = 1:size(stimuli_onset_times,1)  %6000
    
    curr_stimulus_onset = stimuli_onset_times(iTrial);
    
    while curr_stimulus_onset - sample_times(onset) > parameters_for_cur_stimulus.sample_interval
        
        onset = onset + 1;
        
    end
    
    cur_cell_matrix (iTrial,:) = cur_cell_data(onset + parameters_for_cur_stimulus.sampling_points_before_onset:...
        onset + parameters_for_cur_stimulus.sampling_points_after_onset, 1)';
    
end
raster_data = cur_cell_matrix;
end

% generate raster_site_info

function raster_site_info = generate_raster_site_info(container_id, parameters_for_cur_stimulus,session_id,session_type,new_cell_id)

raster_site_info = parameters_for_cur_stimulus;

raster_site_info.container_id = container_id;

raster_site_info.new_cell_id = new_cell_id;

raster_site_info.session_id = session_id;

raster_site_info.session_type = session_type;

raster_site_info = orderfields(raster_site_info);

end

function parameters_for_cur_stimulus = fetch_stimuli_based_parameters(stimuli)

% set parameters for raster_data

stimuli_type = {'static_gratings';'drifting_gratings'};

sample_interval = repelem(0.033, length(stimuli_type)).';  % 30 Hz two-photon movie

stimuli_interval = [0.25; 3] ; % stimuli are shown every 250 ms

starts = [-0.25; -0.25]; % window starts 250 ms before stimulus onset

ends = [0.75; 2.75]; % window ends 75o ms after stimulus onset

sampling_points_before_onset = NaN * ones(length(stimuli_type),1); % number of sampling points before the onset of stimuli

for iStimulus_type = 1: length(stimuli_type)
    % total of sampling time points taken before stimulus onset
    sampling_points_before_onset(iStimulus_type) = round(starts(iStimulus_type)/sample_interval(iStimulus_type));
    
end

position_of_sampling_point_at_onset = 1 - sampling_points_before_onset;

sampling_points_after_onset = NaN * ones(length(stimuli_type),1);

for iStimulus_type = 1: length(stimuli_type)
    % total of sampling time points taken after stimulus onset
    sampling_points_after_onset(iStimulus_type) = round(ends(iStimulus_type)/sample_interval(iStimulus_type));
    
end

parameters_for_all_stimuli = table (sample_interval, stimuli_interval, starts, ends, sampling_points_before_onset ...
    , sampling_points_after_onset,position_of_sampling_point_at_onset ,'RowNames', stimuli_type);

parameters_for_cur_stimulus = table2struct(parameters_for_all_stimuli(stimuli,:));

end

function raster_labels = generate_raster_labels (nwb_name, stimuli)

variables = h5read(nwb_name, strcat('/stimulus/presentation/', stimuli, '_stimulus/features'));

% labels is a matrix of k dimensions of variables by n dimensions of trials
levels = h5read(nwb_name,strcat('/stimulus/presentation/', stimuli, '_stimulus/data'));

% In the case of drifting_gratings, there is this thrid variable called
% blank sweep with two levels 1 and 0, which is redundant and discarded
% here.

if strcmp(stimuli,'drifting_gratings') == 1
    
    variables = variables(1:2,:);
    
    levels = levels(1:2,:);
    
end

%     There were blank sweeps (i.e. mean luminance gray instead of grating)
%     presented roughly once every 25 gratings,
%     which have NaN for all three variables.
%     We are converting the levels matrix into levels cellarray, where numbers are converted to string
%     and NaNs are replaced with "blank"

parsed_levels = cell (size(levels, 1),size(levels, 2));

for iVariable = 1:size(levels, 1)
    
    for iLevel = 1:size(levels, 2)
        
        curr_level = levels(iVariable, iLevel);
        
        if isnan(curr_level)
            
            parsed_levels{iVariable}{iLevel} = 'blank';
            
        else
            parsed_levels{iVariable}{iLevel} = num2str(curr_level);
            
        end
    end
end

variables = cellstr(char(string(variables)));

for iVariable = 1:size(variables,1)
    
    raster_labels.(char(strcat("stimulus_", variables(iVariable)))) = parsed_levels{iVariable};
    
end
end







