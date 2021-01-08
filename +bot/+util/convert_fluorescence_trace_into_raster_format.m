function convert_fluorescence_trace_into_raster_format(fluorescence_trace_type, session_id, ...
                                                       stimulus, raster_dir_name)

% convert_fluorescence_trace_into_raster_format - FUNCTION Store experimental data in the NDT raster format
%
% Usage: convert_fluorescence_trace_into_raster_format(fluorescence_trace_type, session_id,...
%                                                      stimulus, raster_dir_name)
%
% This function saves the experimental data from a BO session into the raster
% format required by the Neural Decoding Toolbox.
%
% `fluorescence_trace_type` is one of {'raw', 'demixed', 'neuropil_corrected',
% 'DfOverF'}.
%
% `session_id` is a valid session ID from an Allen Brain Observatory dataset[1].
%
% `stimulus` is one of {'static_gratings', 'drifting_gratings',
% 'locally_sparse_noise_4deg', 'locally_sparse_noise_8deg', 'natural_scenes',
% 'natural_movie_one', 'natural_movie_two', 'natural_movie_three'}.
%
% `raster_dir_name` is a path under which to store the raster format .mat files.
% It will be created if it does not already exist.
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits


% - Permitted arguments
trace_types = {'raw', 'demixed', 'neuropil_corrected', 'DfOverF'};
stim_types = {'static_gratings', 'drifting_gratings', 'locally_sparse_noise_4deg', ...
   'locally_sparse_noise_8deg', 'natural_scenes', 'natural_movie_one', ...
   'natural_movie_two', 'natural_movie_three'};

% -- Check arguments

if ~ismember(fluorescence_trace_type, trace_types)
   error('BOT:Argument', '''fluorescence_trace_type'' must be one of {%s}.', ...
      sprintf('''%s'', ', trace_types{:}));
end

if ~ismember(stimulus, stim_types)
   error('BOT:Argument', '''stimulus'' must be one of {%s}.', ...
      sprintf('''%s'', ', stim_types{:}));
end


% - Create a session object
session = bot.session(session_id);

% - Extract fluorescence traces from this experiment session
switch fluorescence_trace_type
   case 'raw'
      [~, fluorescence_trace] = session.fluorescence_traces;
      
   case 'demixed'
      fluorescence_trace = session.demixed_traces;
      
   case 'neuropil_corrected'
      [~, fluorescence_trace] = session.corrected_fluorescence_traces;
      
   case 'DfOverF'
      [~, fluorescence_trace] = session.get_dff_traces();
      
   otherwise
      error('BOT:Argument', 'Unknown fluorescence trace type.');
end

% - Get list of cell_ids
new_cell_specimen_ids = session.get_cell_specimen_ids();

% - create a head directory that stores all raster formats
if ~exist(raster_dir_name, 'dir')
   mkdir(raster_dir_name);
end

% - Under the head directory 'raster/', create a directory for one stimulus type
stimulus_dir_name = fullfile(raster_dir_name, stimulus);
if ~exist(stimulus_dir_name, 'dir')
   mkdir(stimulus_dir_name);
end

% - Under the head directory 'raster/', create a current directory that stores
% all raster formats returned from the current analysis
current_raster_dir_name = [stimulus, '_', num2str(session_id)];
current_raster_dir_name_full = fullfile(stimulus_dir_name, current_raster_dir_name);

% - create dir for currrent session
if ~exist(current_raster_dir_name_full ,'dir')
   mkdir(current_raster_dir_name_full );
end

% - If the process of converting for this session was aborted once that the
% session dir exists with no raster file or partial raster files, or the
% session was newly made, we (re)convert all raster files
if size(fluorescence_trace, 2) ~=...
      length(dir(current_raster_dir_name_full))-2
   
   % - Fetch some parameters (hardcoded inside the function) that help build the
   % raster data such as window frames, sampling frequency, etc.
   
   parameters_for_cur_stimulus = fetch_stimulus_based_parameters(stimulus);
   
   % - Generate raster_labels, which applys to all cells in the same session
   raster_labels = generate_raster_labels(session, stimulus); %#ok<NASGU>
   
   % - Loop over cells to create raster files
   for iCell = 1:size(fluorescence_trace, 2)
      cur_new_cell_id = new_cell_specimen_ids(iCell);      
      cur_raster_file_name = [num2str(cur_new_cell_id), '.mat'];
      
      % - raster_data is a matrix of k dimensions of trials by n dimensions of time
      raster_data = generate_raster_data(iCell, fluorescence_trace, parameters_for_cur_stimulus, session, stimulus); %#ok<NASGU>
      
      raster_site_info = generate_raster_site_info(session, stimulus, parameters_for_cur_stimulus, cur_new_cell_id); %#ok<NASGU>
   
      % - Write out the raster format
      save(fullfile(current_raster_dir_name_full, cur_raster_file_name), 'raster_data', 'raster_labels', 'raster_site_info', '-v7.3');
   end
   
   % - Display some status information
   fprintf('[%d] cells converted into raster format.\n', size(fluorescence_trace,2));
   fprintf('There are [%d] raster files in directory [%s].\n', ...
      length(dir(current_raster_dir_name_full))-2,  current_raster_dir_name_full)
   
else
   fprintf('All raster files already exist in directory [%s].\n', current_raster_dir_name_full)
end

end


%  generate raster_data

function raster_data = generate_raster_data(i, fluorescenece_trace, parameters_for_cur_stimulus, bos, stimulus)

% - Ensure data is cached locally
bos.EnsureCached();
nwb_name = bos.local_nwb_file_location;

if isequal(bos.sSessionInfo.stimulus_name, 'three_session_C') && isequal(stimulus, 'locally_sparse_noise_4deg')
   
   stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/locally_sparse_noise_stimulus/timestamps'));
else
   
   stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/timestamps'));
   
end
sampling_times = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/timestamps');


sampling_times = sampling_times * 1000; % change unit from s to ms

stimulus_onset_times = stimulus_onset_times * 1000; % change unit from s to ms

cur_cell_data = fluorescenece_trace (:,i);

% preallocation of cell_matrix: a trial by time matrix of dfOVerF of a
% single cell

cur_cell_matrix = NaN * ones(size(stimulus_onset_times,1), parameters_for_cur_stimulus.num_sample_after_onset.....
   - parameters_for_cur_stimulus.num_sample_before_onset +1);

onset = 1;
% looking for the closet sampling time to stimulus onset time
for iTrial = 1:size(stimulus_onset_times,1)  %6000
   
   curr_stimulus_onset = stimulus_onset_times(iTrial);
   
   while curr_stimulus_onset - sampling_times(onset) > parameters_for_cur_stimulus.sampling_period_in_ms
      
      onset = onset + 1;
      
   end
   
   cur_cell_matrix (iTrial,:) = cur_cell_data(onset + parameters_for_cur_stimulus.num_sample_before_onset:...
      onset + parameters_for_cur_stimulus.num_sample_after_onset, 1)';
   
end
raster_data = cur_cell_matrix;
end

% generate raster_site_info

function raster_site_info = generate_raster_site_info(bos, stimulus, parameters_for_cur_stimulus, cur_new_cell_id)

raster_site_info.timing_info = parameters_for_cur_stimulus;

raster_site_info.container_id = bos.sSessionInfo.experiment_container_id;

raster_site_info.new_cell_id = cur_new_cell_id;

raster_site_info.session_id = bos.sSessionInfo.id;

raster_site_info.session_type = char(bos.sSessionInfo.stimulus_name);

raster_site_info.targeted_structure = bos.sSessionInfo.targeted_structure;

raster_site_info.imaging_depth = bos.sSessionInfo.imaging_depth;

raster_site_info.stimulus_type = stimulus;

raster_site_info.cre_line = char(bos.sSessionInfo.cre_line);

raster_site_info.eye_tracking_avail = ~bos.sSessionInfo.fail_eye_tracking;

raster_site_info = orderfields(raster_site_info);


end

% provide parameters that help build the raster data such as window
% frames, sampling frequency, etc.

function parameters_for_cur_stimulus = fetch_stimulus_based_parameters(stimulus)

% set parameters for raster_data

stimulus_type = {'static_gratings';'drifting_gratings';'locally_sparse_noise_4deg';...
   'locally_sparse_noise_8deg';'natural_scenes';'natural_movie_one';'natural_movie_two';'natural_movie_three'};

sampling_period_in_ms = repelem(33, length(stimulus_type)).';  % 30 Hz two-photon movie

% this piece of information is not computed but simply stored in site_info
stimulus_duration_in_ms = [250; 3000; 250; 250; 250; 33; 33; 33] ; % stimuli are shown every 250 ms

duration_in_ms_before_stimulus_onset = [-250; -250; -250; -250; -250; -250; -250; -250]; % window starts 250 ms before stimulus onset

duration_in_ms_after_stimulus_onset = [750; 2750; 750; 750; 750; 750; 750; 750]; % window ends 750 ms after stimulus onset

num_sample_before_onset = NaN * ones(length(stimulus_type),1); % number of sampling points before the onset of stimulus

for iStimulus_type = 1: length(stimulus_type)
   % total of sampling time points taken before stimulus onset
   num_sample_before_onset(iStimulus_type) = round(duration_in_ms_before_stimulus_onset(iStimulus_type)/sampling_period_in_ms(iStimulus_type));
   
end

stimulus_onset_sampling_index = 1 - num_sample_before_onset;

num_sample_after_onset = NaN * ones(length(stimulus_type),1);

for iStimulus_type = 1: length(stimulus_type)
   % total of sampling time points taken after stimulus onset
   num_sample_after_onset(iStimulus_type) = round(duration_in_ms_after_stimulus_onset(iStimulus_type)/sampling_period_in_ms(iStimulus_type));
   
end

parameters_for_all_stimuli = table (sampling_period_in_ms, stimulus_duration_in_ms, duration_in_ms_before_stimulus_onset, duration_in_ms_after_stimulus_onset, num_sample_before_onset ...
   , num_sample_after_onset,stimulus_onset_sampling_index ,'RowNames', stimulus_type);

parameters_for_cur_stimulus = table2struct(parameters_for_all_stimuli(stimulus,:));

end

% genereate raster_labels

function raster_labels = generate_raster_labels(bos, stimulus)

% - Ensure the data is cached, and obtain the local filename
bos.EnsureCached();
nwb_name = bos.local_nwb_file_location;

switch stimulus
   case {'drifting_gratings', 'static_gratings'}
      variables = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/features'));      
      
      % labels is a matrix of k dimensions of variables by n dimensions of trials
      labels = h5read(nwb_name,strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
      
      % In the case of drifting_gratings, there is this thrid variable called
      % blank sweep with two levels 1 and 0, which is redundant and discarded
      % here.
      
      if strcmp(stimulus,'drifting_gratings') == 1
         
         variables = variables(1:2,:);
         
         labels = labels(1:2,:);
         
      end
      
      %     There were blank sweeps (i.e. mean luminance gray instead of grating)
      %     presented roughly once every 25 gratings,
      %     which have NaN for all three variables.
      %     We are converting the levels matrix into levels cellarray, where numbers are converted to string
      %     and NaNs are replaced with "blank"
      
      parsed_labels = cell (size(labels, 1),size(labels, 2));
      
      for iVariable = 1:size(labels, 1)
         
         for iTrial = 1:size(labels, 2)
            
            curr_label = labels(iVariable, iTrial);
            
            if isnan(curr_label)
               
               parsed_labels{iVariable}{iTrial} = 'blank';
               
            else
               parsed_labels{iVariable}{iTrial} = num2str(curr_label);
               
            end
         end
      end
      
      variables = cellstr(char(variables));
      
      combined_variable_name = ['combined' sprintf('_%s', variables{:})];
      raster_labels.(combined_variable_name) = {'combined'};
      
      for iVariable = 1:size(variables,1)
         raster_labels.(char(strcat('stimulus_', variables(iVariable)))) = parsed_labels{iVariable};
         raster_labels.(combined_variable_name) = strcat(raster_labels.(combined_variable_name), {'_'}, parsed_labels{iVariable});
      end
      
   case {'locally_sparse_noise_4deg','locally_sparse_noise_8deg' }
      
      % so in session C where there is only 4deg, 4deg is simply named as
      % locally_sparse_noise
      
      %         this doesn't work in older version of MATLAB
      %         if  string(bos.sSessionInfo.stimulus_name) == 'three_session_C2'
      if isequal(bos.sSessionInfo.stimulus_name, 'three_session_C2')
         stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/timestamps'));
         example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
      else
         stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/locally_sparse_noise_stimulus/timestamps'));
         example_labels = h5read(nwb_name, strcat('/stimulus/presentation/locally_sparse_noise_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
      end
      
      pixel_variables = cell(size(example_labels,1), size(example_labels,2));
      for iRow = 1 : size(example_labels,1)
         for iCol = 1: size(example_labels,2)
            
            pixel_variables{iRow, iCol} = ['row_' num2str(iRow,'%02d') '_col_' num2str(iCol,'%02d')];
            
            
         end
      end
      
      flattened_pixel_variables = reshape(pixel_variables, [size(example_labels,1) * size(example_labels,2),1]);
      
      % m pixels by n trials
      final_labels = NaN * ones(length(flattened_pixel_variables), length(stimulus_onset_times));
      
      for iTrial = 1: length(stimulus_onset_times)
         if isequal(bos.sSessionInfo.stimulus_name, 'three_session_C2')
            
            iLabels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,iTrial], [Inf, Inf, 1])';
         else
            iLabels = h5read(nwb_name, strcat('/stimulus/presentation/locally_sparse_noise_stimulus/indexed_timeseries/data'), [1,1,iTrial], [Inf, Inf, 1])';
         end
         iflattend_labels = reshape(iLabels, [length(flattened_pixel_variables),1]);
         final_labels(:, iTrial) = iflattend_labels;
      end
      for iVariable  =  1: length(flattened_pixel_variables)
         raster_labels.(char(flattened_pixel_variables(iVariable, 1))) = final_labels(iVariable,:);
      end
      
      
      
      
   case 'natural_scenes'
      % the structure of this
      % section is
      %         1) parses 5950 frame_indexs including blank
      %         2) dealing with id_variables
      %             a) makes 119 id_labels
      %             b) maps 119 id_labels to 5950 frames refering to parsed_frame_indexs
      %             c) maps id_labels to id_variable
      
%       example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';

      % this part parses 5950 frame_indexs including blank
      % frame_indexs range from -1 to 117
      frame_indices = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
      parsed_frame_indices = nan(length(frame_indices), 1);
      
      % parse index of blank from -1 to 119, and increment the rest (cuz
      % MATLAB starts at 1 not 0)
      % parsed_frame_indexs range from 1 t0 119
      for iFrame = 1 : length(frame_indices)
         if frame_indices(iFrame, 1)~= -1
            parsed_frame_indices(iFrame, 1) = frame_indices(iFrame, 1) + 1;
         else
            parsed_frame_indices(iFrame, 1) = 119;
         end
      end
      % this part makes 119 id_labels
      % image_indexs ranges from 1 to 118
      %         image_indexs = 1 : length(categories(categorical(frame_indexs)))-1;
      image_id_labels = cell(1, length(categories(categorical(frame_indices)))-1);
      % zero-pad
      for iImage_index = 1 : length(categories(categorical(frame_indices)))-1
         image_id_labels(iImage_index) = cellstr(['Image', num2str(iImage_index,'%03d')]);
      end
      %         image_id_labels = strcat('No_', cellstr(num2str(image_indexs')));
      %         ['image', num2str(image_indexs')];
      all_id_labels = [image_id_labels,cellstr('blank')];
      
      % this part maps 119 id_labels to 5950 frams refering to
      % parsed_frame_indexs
      
      id_labels_for_all_frames = cell(1, length(frame_indices));
      for iFrame = 1 : length(frame_indices)
         
         id_labels_for_all_frames(1, iFrame) = all_id_labels(1, parsed_frame_indices(iFrame));
         
      end
      
      % this part maps id_labels to id_variable
      
      raster_labels.id = id_labels_for_all_frames;
      
   case {'natural_movie_one','natural_movie_two', 'natural_movie_three'}
%       example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
      frame_indices = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
      
      %     this session is much simpler than natural scenes one, cuz clip is
      %     repeated in a row without randomization
      %  here we illlustrate the procedure for clip 1 and 2, both of
      %  which have 300 frames, clip 3 has 3600 frames.
      %     % frame_indexs range from 0 to 899
      
      % this part makes 900 id_labels
      % image_indexs ranges from 1 to 900
      % I am thinking merging three clips into one raster file, which is why
      % clip number is included in the label
      image_indices = 1 : length(categories(categorical(frame_indices)));
      switch stimulus
         case 'natural_movie_one'
            image_id_labels = strcat('clip_1_frame_', cellstr(num2str(image_indices', '%03d')));
         case 'natural_movie_two'
            image_id_labels = strcat('clip_2_frame_', cellstr(num2str(image_indices', '%03d')));
            
         case 'natural_movie_three'
            image_id_labels = strcat('clip_3_frame_', cellstr(num2str(image_indices', '%04d')));
      end
      
      
      % repeat id_labels as a whole for 10 times
      id_labels_for_all_frames = repmat(image_id_labels, 10, 1);
      
      % this part maps id_labels to id_variable
      
      raster_labels.id = id_labels_for_all_frames';
end

end





