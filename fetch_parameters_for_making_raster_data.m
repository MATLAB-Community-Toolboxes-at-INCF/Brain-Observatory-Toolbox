function para_raster = fetch_parameters_for_making_raster_data(stimuli)

% set parameters for raster_data

stimuli_type = {'static_gratings';'drifting_gratings'};

sample_interval = repelem(0.033, length(stimuli_type)).';  % 30 Hz two-photon movie

stimuli_interval = [0.25; 3] ; % stimuli are shown every 250 ms

starts = [-0.25; -0.25]; % window starts 250 ms before stimulus onset

ends = [0.75; 2.50]; % window ends 75o ms after stimulus onset

align_before = NaN * ones(length(stimuli_type),1); % number of sampling points before the onset of stimuli

for iStimulus_type = 1: length(stimuli_type)
    
    align_before(iStimulus_type) = round(starts(iStimulus_type)/sample_interval(iStimulus_type)); % num of sampling points taekn before stimulus onset

end

align_after = NaN * ones(length(stimuli_type),1);

for iStimulus_type = 1: length(stimuli_type)

    align_after(iStimulus_type) = round(ends(iStimulus_type)/sample_interval(iStimulus_type)) - 1; % num of sampling points taekn after stimulus onset

end

para_raster_total = table (sample_interval, stimuli_interval, starts, ends, align_before ...
    , align_after ,'RowNames', stimuli_type);

para_raster = table2struct(para_raster_total(stimuli,:));

end

