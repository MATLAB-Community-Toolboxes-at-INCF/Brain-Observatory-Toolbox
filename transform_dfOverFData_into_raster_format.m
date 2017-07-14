function transform_dfOverFData_into_raster_format(nwb_name, stimuli)

% import data and metadata from nwbfile of a single session

dfOverF_data = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/data');

sample_times = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/timestamps');

stimuli_onset_times = h5read(nwb_name, strcat('/stimulus/presentation/', stimuli, '_stimulus/timestamps'));

experiment_container_id = h5read(nwb_name,'/general/experiment_container_id');

session_id = h5read(nwb_name,'/general/session_id');

session_type = h5read(nwb_name,'/general/session_type');

% fetching some parameters that define the raster data such as window
% frames, sampling frequency, etc.

para_raster = fetch_parameters_for_making_raster_data(stimuli);

% generate raster_labels, apply to every cell in the same session


variables = h5read(nwb_name, strcat('/stimulus/presentation/', stimuli, '_stimulus/features'));

labels = h5read(nwb_name,strcat('/stimulus/presentation/', stimuli, '_stimulus/data'));


if strcmp(stimuli,'drifting_gratings') == 1
    
    variables = variables(1:2,:);
    
    labels = labels(1:2,:);
    
end

    %There were blank sweeps (i.e. mean luminance gray instead of grating) presented roughly once every 25 gratings.
    %which were labeled for all three variables as NaN, which shall be
    %replaced with "blank"
    
parsed_labels = cell (size(labels, 1),size(labels, 2));
    
for iVariableType = 1:size(labels, 1)  
    
    for iLabel = 1:size(labels, 2)
   
        curr_label = labels(iVariableType, iLabel);

        if isnan(curr_label)
            
            parsed_labels{iVariableType}{iLabel} = 'blank';
            
        else
            
            parsed_labels{iVariableType}{iLabel} = num2str(curr_label);
            
        end
        
    end
end  

variables = cellstr(char(string(variables)));

for iVariableType = 1:size(variables,1)
    
    raster_labels.(char(strcat("stimulus_", variables(iVariableType)))) = parsed_labels{iVariableType}; 
    
end    

% create directory

directory_name = char(strcat("raster_", experiment_container_id,'_', stimuli)) ;

mkdir(directory_name);

% put raster files in the directory

for i = 1:size(dfOverF_data,2)
    
    file_name = strcat("cell", num2str(i), ".mat");
    
    raster_data = generate_raster_data(i, dfOverF_data, para_raster, sample_times, stimuli_onset_times);
    
    raster_site_info = generate_raster_site_info(i, experiment_container_id, para_raster,session_id,session_type);
    
    save(char(strcat(directory_name, "/", file_name)), 'raster_data', 'raster_labels', 'raster_site_info');

end

end


%  generate raster_data

function raster_data = generate_raster_data(i, dfOverF_data, para_raster, sample_times, stimuli_onset_times)
    
    cell_data = dfOverF_data (:,i);
    
% preallocation of cell_matrix: a trial by time matrix of dfOVerF of a
% single cell

    cell_matrix = NaN * ones(size(stimuli_onset_times,1), para_raster.align_after - para_raster.align_before +1);

    align = 1;

    for m = 1:size(stimuli_onset_times,1)  %6000

        curr_stimulus_onset = stimuli_onset_times(m);

        while curr_stimulus_onset - sample_times(align) > para_raster.sample_interval

            align = align + 1;

        end

        cell_matrix (m,:) = cell_data(align + para_raster.align_before: align + para_raster.align_after, 1).';
   
    end
    raster_data = cell_matrix;
end

% generate raster_site_info

function raster_site_info = generate_raster_site_info(i, experiment_container_id, para_raster,session_id,session_type)

raster_site_info = para_raster;

raster_site_info.experiment_container_id = experiment_container_id;

raster_site_info.cell_id = i;

raster_site_info.session_id = session_id;

raster_site_info.session_type = session_type;

raster_site_info = orderfields(raster_site_info);

end








