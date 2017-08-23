function convert_fluorescenece_trace_into_raster_format(fluorescence_trace_type,session_id,...
    stimulus, raster_dir_name, nwb_dir_name, varargin)
tic

want_pixel_labels = varargin;

addpath(genpath(nwb_dir_name))

nwb_name = [num2str(session_id) '.nwb'];

manifests = get_manifests_info_from_api();

boc = brain_observatory_cache(manifests);

boc.filter_sessions_by_session_id(session_id);



% get all fluorescenece_trace from nwb

raw = h5read(nwb_name,'/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/data');

neuropil = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/neuropil_traces');

demixed = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1_demixed_signal/data');

contamination_ratio = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/r');

contamination_ratio_matrix = contamination_ratio .* eye (size(contamination_ratio,1));

neuropil_matrix = neuropil * contamination_ratio_matrix;

neuropil_corrected = demixed - neuropil_matrix;

DfOverF = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/data');

all_f_traces = struct('raw', raw, 'demixed', demixed, 'neuropil_correted', neuropil_corrected, 'DfOverF', DfOverF);

fluorescenece_trace = all_f_traces.(fluorescence_trace_type);

% get other info from nwb

sampling_times = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/timestamps');

stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/timestamps'));

new_cell_specimen_ids = h5read(nwb_name, '/processing/brain_observatory_pipeline/ImageSegmentation/cell_specimen_ids');

% create a head directory 'ratser/' that store all ratser formats

if ~exist(raster_dir_name,'dir')
    mkdir(raster_dir_name);
end

% under the head directory 'raster/', create a directory for one stimulus
% type

stimulus_dir_name = [raster_dir_name  stimulus '/'];
if ~exist(stimulus_dir_name, 'dir')
    mkdir(stimulus_dir_name);
end

% under the head directory 'raster/', create a current direcotry that store
% all raster formats returned from the current analysis

current_raster_dir_name = [stimulus,'_', num2str(session_id) ,'/'];
current_raster_dir_name_full  = [stimulus_dir_name current_raster_dir_name];

if ~exist(current_raster_dir_name_full ,'dir')
    mkdir(current_raster_dir_name_full );
    
    
    % fetching some parameters (hardcoded inside the function) that help build the raster data such as window
    % frames, sampling frequency, etc.
    
    parameters_for_cur_stimulus = fetch_stimulus_based_parameters(stimulus);
    
    % generate raster_labels, which applys to all cells in the same session
    
    raster_labels = generate_raster_labels (nwb_name, stimulus, want_pixel_labels);
    
    % create raster files
    
    for iCell = 1:size(fluorescenece_trace,2)
        
        cur_new_cell_id = new_cell_specimen_ids(iCell);
        
        cur_raster_file_name = [num2str(cur_new_cell_id), '.mat'];
        % raster_data is a matrix of k dimensions of trials by n dimensions of
        % time
        raster_data = generate_raster_data(iCell, fluorescenece_trace, parameters_for_cur_stimulus, sampling_times, stimulus_onset_times);
        
        raster_site_info = generate_raster_site_info(boc, stimulus, parameters_for_cur_stimulus,cur_new_cell_id);
        
        
        save([current_raster_dir_name_full , cur_raster_file_name], 'raster_data', 'raster_labels', 'raster_site_info', '-v7.3');
        
    end
    
    fprintf ( [num2str(size(fluorescenece_trace,2)) ' cells converted into raster formats.'])
    disp(' ')
    fprintf ([' There are ' num2str(length(dir(current_raster_dir_name_full))-2) ' raster files in folder ' current_raster_dir_name_full])
    disp(' ')
    toc
else
    fprintf([current_raster_dir_name_full ' already exists'])
end

end % end of convert_fluorescenece_trace_into_raster_format


%  generate raster_data

function raster_data = generate_raster_data(i, fluorescenece_trace, parameters_for_cur_stimulus, sampling_times, stimulus_onset_times)

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

function raster_site_info = generate_raster_site_info(boc, stimulus, parameters_for_cur_stimulus,cur_new_cell_id)

raster_site_info.timing_info = parameters_for_cur_stimulus;

raster_site_info.container_id = boc.container_id;

raster_site_info.new_cell_id = cur_new_cell_id;

raster_site_info.session_id = boc.session_id;

raster_site_info.session_type = char(boc.session_type);

raster_site_info.targeted_structure = boc.targeted_structure;

raster_site_info.imaging_depth = boc.imaging_depth;

raster_site_info.stimulus_type = stimulus;

raster_site_info.cre_line = char(boc.cre_line);

raster_site_info.eye_tracking_avail = boc.eye_tracking_avail;

raster_site_info = orderfields(raster_site_info);


end

% provide parameters that help build the raster data such as window
% frames, sampling frequency, etc.

function parameters_for_cur_stimulus = fetch_stimulus_based_parameters(stimulus)

% set parameters for raster_data

stimulus_type = {'static_gratings';'drifting_gratings';'locally_sparse_noise';...
    'natural_scenes';'natural_movie_one';'natural_movie_two';'natural_movie_three'};

sampling_period_in_ms = repelem(33, length(stimulus_type)).';  % 30 Hz two-photon movie

stimulus_duration_in_ms = [250; 3000; 250; 250; 250; 250; 250] ; % stimuli are shown every 250 ms

duration_in_ms_before_stimulus_onset = [-250; -250; -250; -250; -250; -250; -250]; % window starts 250 ms before stimulus onset

duration_in_ms_after_stimulus_onset = [750; 2750; 750; 750; 750; 750; 750]; % window ends 750 ms after stimulus onset

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

function raster_labels = generate_raster_labels (nwb_name, stimulus, want_pixel_labels)

switch stimulus
    case {'drifting_gratings','static_gratings'}
        pixel_variables = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/features'));
        
        
        % labels is a matrix of k dimensions of variables by n dimensions of trials
        labels = h5read(nwb_name,strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
        
        % In the case of drifting_gratings, there is this thrid variable called
        % blank sweep with two levels 1 and 0, which is redundant and discarded
        % here.
        
        if strcmp(stimulus,'drifting_gratings') == 1
            
            pixel_variables = pixel_variables(1:2,:);
            
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
        
        pixel_variables = cellstr(char(string(pixel_variables)));
        
        combined_variable_name = 'combined';
        
        
        for iVariable = 1:size(pixel_variables,1)
            
            combined_variable_name = [combined_variable_name '_' char(pixel_variables{iVariable})];
            
        end
        
        raster_labels.(combined_variable_name) = {'combined'};
        
        for iVariable = 1:size(pixel_variables,1)
            
            raster_labels.(char(strcat('stimulus_', pixel_variables(iVariable)))) = parsed_labels{iVariable};
            raster_labels.(combined_variable_name) = strcat(raster_labels.(combined_variable_name), {'_'}, parsed_labels{iVariable});
            
        end
        
    case {'locally_sparse_noise'}
        
        stimulus_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/timestamps'));
        example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
        pixel_variables = cell(size(example_labels,1), size(example_labels,2));
        for iRow = 1 : size(example_labels,1)
            for iCol = 1: size(example_labels,2)
                if iRow < 10
                    if iCol < 10
                        pixel_variables{iRow, iCol} = ['row_' num2str(iRow,'%02d') '_col_' num2str(iCol,'%02d')];
                        
                    else
                        pixel_variables{iRow, iCol} = ['row_' num2str(iRow,'%02d') '_col_' num2str(iCol)];
                        
                    end
                elseif iCol < 10
                    pixel_variables{iRow, iCol} = ['row_' num2str(iRow) '_col_' num2str(iCol,'%02d')];
                else
                    pixel_variables{iRow, iCol} = ['row_' num2str(iRow) '_col_' num2str(iCol)];
                    
                end
            end
        end

        flattened_pixel_variables = reshape(pixel_variables, [size(example_labels,1) * size(example_labels,2),1]);
        % m pixels by n trials
        final_labels = NaN * ones(length(flattened_pixel_variables), length(stimulus_onset_times));
        
        for iTrial = 1: length(stimulus_onset_times)
            
            iLabels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,iTrial], [Inf, Inf, 1])';
            
            iflattend_labels = reshape(iLabels, [length(flattened_pixel_variables),1]);
            final_labels(:, iTrial) = iflattend_labels;
        end
        for iVariable  =  1: length(flattened_pixel_variables)
            raster_labels.(char(flattened_pixel_variables(iVariable, 1))) = final_labels(iVariable,:);
        end
        
        
        % we are having a hard time storing billions of pixel labels for natural scenes and natural movies,
        % for now, pixel_labels are not
        %     incorporated by default unless want_pixel_labels is set to 1
        
    case 'natural_scenes'
        % we get lots of labels for natural_scenes, the structure of this
        % section is
        %         1) parses 5950 frame_indexs including blank
        %         2) dealing with id_variables
        %             a) makes 119 id_labels
        %             b) maps 119 id_labels to 5950 frames refering to parsed_frame_indexs
        %             c) maps id_labels to id_variable
        %         3) dealing with pixiel_variables
        %             a) makes 1174*918 pixel_variables
        %             b) makes (1174*918)*119 pixel_labels
        %             c) maps (1174*918)*119 labels to 5950 frames refering to parsed_frame_indexs
        %             d) maps pixel_labels to pixel_variables
        
        
        
        
        example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
        
        
        
        % this part parses 5950 frame_indexs including blank
        % frame_indexs range from -1 to 117
        frame_indexs = h5read(nwb_name,strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
        parsed_frame_indexs = NaN * ones(length(frame_indexs),1);
        
        % parse index of blank from -1 to 119, and increment the rest (cuz
        % matlab starts at 1 not 0)
        % parsed_frame_indexs range from 1 t0 119
        for iFrame = 1 : length(frame_indexs)
            if frame_indexs(iFrame, 1)~= -1
                parsed_frame_indexs(iFrame, 1) = frame_indexs(iFrame, 1) + 1;
            else
                parsed_frame_indexs(iFrame, 1) = 119;
            end
        end
        % this part makes 119 id_labels
        % image_indexs ranges from 1 to 118
%         image_indexs = 1 : length(categories(categorical(frame_indexs)))-1;
        image_id_labels = cell(1, length(categories(categorical(frame_indexs)))-1);
        for iImage_index = 1 : length(categories(categorical(frame_indexs)))-1
            if iImage_index < 10
                image_id_labels(iImage_index) = cellstr(['Image', num2str(iImage_index,'%03d')]);
            elseif iImage_index < 100
                image_id_labels(iImage_index) = cellstr(['Image', num2str(iImage_index,'%03d')]);
            else
                image_id_labels(iImage_index) = cellstr(['Image', num2str(iImage_index)]);
            end
        end
%         image_id_labels = strcat('No_', cellstr(num2str(image_indexs')));
%         ['image', num2str(image_indexs')];
        all_id_labels = [image_id_labels,cellstr('blank')];
        
        % this part maps 119 id_labels to 5950 frams refering to
        % parsed_frame_indexs
        
        id_labels_for_all_frames = cell(1, length(frame_indexs));
        for iFrame = 1 : length(frame_indexs)
            
            id_labels_for_all_frames(1,iFrame) = all_id_labels(1,parsed_frame_indexs(iFrame));
            
        end
        
        % this part maps id_labels to id_variable
        
        raster_labels.id = id_labels_for_all_frames;
        
%         if cell2mat(want_pixel_labels) == 1
%             
%             
%             % this part makes 1174*918 pixel_variables
%             % it makes life easier to make variables before making labels
%             pixel_variables = cell(size(example_labels,1), size(example_labels,2));
%             for iRow = 1 : size(example_labels,1)
%                 for iCol = 1: size(example_labels,2)
%                     %variables(iRow, iCol) = {['row_' num2str(iRow) '_col_' num2str(iCol)]};
%                     pixel_variables{iRow, iCol} = ['row_' num2str(iRow) '_col_' num2str(iCol)];
%                 end
%             end
%             flattened_pixel_variables = reshape(pixel_variables, [size(example_labels,1) * size(example_labels,2),1])';
%             
%             
%             % this part makes (1174*918)*119 pixel_labels
%             
%             % m pixels by 118 images
%             image_pixel_labels = NaN * ones(length(flattened_pixel_variables), length(image_indexs));
%             
%             for iImage = 1 : length(image_indexs)
%                 iLabels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,iImage], [Inf, Inf, 1]);
%                 
%                 iflattend_labels = reshape(iLabels, [length(flattened_pixel_variables),1]);
%                 image_pixel_labels(:, iImage) = iflattend_labels;
%             end
%             % the determination of pixel value of blank to be 127 is inspired from
%             % locally sparse nosie where grey is 127
%             blank_pixel_labels = repelem(127,length(flattened_pixel_variables), 1);
%             all_pixel_labels = [image_pixel_labels, blank_pixel_labels];
%             
%             
%             % this part maps (1174*918)*119 labels to 5950 frames refering to
%             % parsed_frame_indexs
%             
%             % m pixels (around 1 million) by 5950 trials
%             % this function may crash matlab
%             pixel_labels_for_all_trials = NaN * ones(length(flattened_pixel_variables),length(frame_indexs));
%             
%             for iFrame = 1 : length(frame_indexs)
%                 
%                 pixel_labels_for_all_trials(:,iFrame) = all_pixel_labels(:, parsed_frame_indexs(iFrame));
%                 
%             end
%             
%             
%             % this part maps pixel_labels to pixel_variables
%             for iVariable  =  1: length(flattened_pixel_variables)
%                 raster_labels.(char(flattened_pixel_variables(iVariable, 1))) = pixel_labels_for_all_trials(iVariable,:);
%             end
%             
%             fprintf('made 6 billion labels')
%             
%         end
    case {'natural_movie_one','natural_movie_two', 'natural_movie_three'}
        example_labels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,1], [Inf, Inf, 1])';
        frame_indexs = h5read(nwb_name,strcat('/stimulus/presentation/', stimulus, '_stimulus/data'));
        
        %     this session is much simpler than natural scenes one, cuz clip is
        %     repeated in a row without randomization
        
        %     % frame_indexs range from 0 to 899
        
        % this part makes 900 id_labels
        % image_indexs ranges from 1 to 900
        % I am thinking merging three clips into one raster file, which is why
        % clip number is included in the label
        image_indexs = 1 : length(categories(categorical(frame_indexs)));
        switch stimulus
            case 'natural_movie_one'
                image_id_labels = strcat('clip_1_No_', cellstr(num2str(image_indexs')));
            case 'natural_movie_two'
                image_id_labels = strcat('clip_2_No_', cellstr(num2str(image_indexs')));
                
            case 'natural_movie_three'
                image_id_labels = strcat('clip_3_No_', cellstr(num2str(image_indexs')));
        end
        
        
        % repeat id_labels for 10 times
        id_labels_for_all_frames = repelem(image_id_labels, 10);
        
        % this part maps id_labels to id_variable
        
        raster_labels.id = id_labels_for_all_frames';
        
        
%         if cell2mat(want_pixel_labels) == 1
%             
%             
%             % this part makes 304 * 608  pixel_variables
%             pixel_variables = cell(size(example_labels,1), size(example_labels,2));
%             for iRow = 1 : size(example_labels,1)
%                 for iCol = 1: size(example_labels,2)
%                     %variables(iRow, iCol) = {['row_' num2str(iRow) '_col_' num2str(iCol)]};
%                     pixel_variables{iRow, iCol} = ['row_' num2str(iRow) '_col_' num2str(iCol)];
%                 end
%             end
%             flattened_pixel_variables = reshape(pixel_variables, [size(example_labels,1) * size(example_labels,2),1]);
%             
%             % add clip info to variables
%             switch stimulus
%                 case 'natural_movie_one'
%                     flattened_pixel_variables_final = strcat('clip_1_',flattened_pixel_variables);
%                 case 'natural_movie_two'
%                     flattened_pixel_variables_final = strcat('clip_2_',flattened_pixel_variables);
%                     
%                 case 'natural_movie_three'
%                     flattened_pixel_variables_final = strcat('clip_3_',flattened_pixel_variables);
%             end
%             
%             
%             % this part makes (304 * 608)* 900 pixel_labels
%             
%             % m pixels by 900 images
%             image_pixel_labels = NaN * ones(length(flattened_pixel_variables), length(image_indexs));
%             
%             for iImage = 1 : length(image_indexs)
%                 iLabels = h5read(nwb_name, strcat('/stimulus/presentation/', stimulus, '_stimulus/indexed_timeseries/data'), [1,1,iImage], [Inf, Inf, 1])';
%                 
%                 iflattend_labels = reshape(iLabels, [length(flattened_pixel_variables),1]);
%                 image_pixel_labels(:, iImage) = iflattend_labels;
%             end
%             
%             % repeat pixel_labels for 10 times
%             pixel_labels_for_all_frames = repmat(image_pixel_labels, 10);
%             %
%             
%             % this part maps pixel_labels to pixel_variables
%             for iVariable  =  1: length(flattened_pixel_variables)
%                 raster_labels.(char(flattened_pixel_variables_final(iVariable, 1))) = pixel_labels_for_all_frames(iVariable,:);
%             end
%             
%             fprintf('made 10 billion labels')
%             
%         end
        
end
end






