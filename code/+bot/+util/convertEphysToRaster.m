
function convertEphysToRaster(ephysSession, stimulusSetName, ...
    baselinePeriodLength, stimulusPeriodLength, unitsToUse, saveDirectoryBaseName)

% convertEphysToRaster - FUNCTION Converts data to NDT "raster format" 
%
% Usage: convertEphysToRaster(ephysSession, stimulusSetName, ...
%    baselinePeriodLength, stimulusPeriodLength <, unitsToUse, saveDirectoryBaseName>) 
%
% This function converts unit spiking data for a particular 
% stimulus set into "raster format" that is used by the Neural Decoding Toolbox (NDT)
%
%
% The arguments to this function are:
%
% ephysSession: A session object from a single session that contains the data to be converted
%
% stimulusSetName: The name of the stimulus set that will be converted to
% raster format.
%
% baselinePeriodLength: the amount of time to include before each stimulus presentation onset
%
% stimulusPeriodLength: the amount of time to include after each stimulus presentation onset
%
% unitsToUse: An table of units from which spiking data is extracted. If
% this is not set or is empty all units will be converted to raster format.
%
% saveDirectoryBaseName: The name of a directory where the raster data
% files are saved. If this is not set it will save the files in a directory
% that is off the current directory. 


    allStimulusSetNames = {'drifting_gratings', 'flashes', 'gabors', 'natural_movie_one', ...
        'natural_movie_three', 'natural_scenes', 'spontaneous', 'static_gratings'};
    
    % error checking that a proper stimulusSetName was given
    if ~any(strcmp(allStimulusSetNames, stimulusSetName))
        error(strjoin(['The argument stimulusSetName must be set to one of the following values: ' allStimulusSetNames]))
    end

    
    if (nargin < 5 || isempty(unitsToUse))
        unitsToUse = ephysSession.units;
        disp(['Converting all ' num2str(height(unitsToUse)) ' recorded units which can take a while. To convert only a subset of units set the "unitsToUse" argument'])
    end
    
    
    % if saveDirectoryName has not been specified, save files to current
    % directory
    if nargin < 6
        saveDirectoryBaseName = pwd;
    end
    
    saveDirectoryName = fullfile(saveDirectoryBaseName, ['session_' num2str(ephysSession.id)], stimulusSetName, '');
    if ~exist(saveDirectoryName)
        mkdir(saveDirectoryName)
    end
        
    
    
    % get the presentation IDs for all stimuli in the given stimulus set
    allStimulusPresentations = ephysSession.stimulus_presentations;
    stimulusInfoTable = allStimulusPresentations(allStimulusPresentations.stimulus_name == stimulusSetName, :);
    stimulusPresentationIds = stimulusInfoTable.stimulus_presentation_id;
  
    
    
    % loop through all units
    for iUnit = 1:height(unitsToUse)
        
        
        % print a message the the data is being binned (and add a dot for each file that has been binned
        curr_unit_string = [' Converting unit: ' num2str(iUnit) ' of ' num2str(height(unitsToUse))];
        if iUnit == 1
            disp(curr_unit_string); 
        else
            fprintf([repmat(8,1,unit_str_len) curr_unit_string]);         
        end
        unit_str_len = length(curr_unit_string);

        
        
        
        % create a unit object corresponding to the current index
        currUnit = bot.getUnits(unitsToUse(iUnit, :));
        
        % get a table of spike times for the current unit when shown the
        % stimulus presentation IDs
        spikeTimes = ephysSession.getPresentationwiseSpikeTimes(stimulusPresentationIds, currUnit.id);
    
        % create an array of spiking times from the first column of the
        % spike_times table
        % multiply the times by 1000 to convert to milliseconds and eliminate decimals 
        spikeTimesArray = round(1000 * table2array(spikeTimes(:, 1)));
        
        % get the full array of stimulus presentation start times
        stimPresentationTimesArray = round(1000 * table2array(stimulusInfoTable(:, "start_time")));
    
        % shift up the stimulus presentation times by the value
        % of baselinePeriodLength + 1
        % provides a buffer on the low end and prevents 0 from being a possible
        % index in the later spikes1d array
        spikeTimesArray = spikeTimesArray + baselinePeriodLength + 1;
        stimPresentationTimesArray = stimPresentationTimesArray + baselinePeriodLength + 1;
        
        % find the time of the last spike/presentation - whichever one is larger 
        if length(spikeTimesArray) == 0    % if there are no spikes...
            endTime = stimPresentationTimesArray(length(stimPresentationTimesArray));
        else
            endTime = max(stimPresentationTimesArray(length(stimPresentationTimesArray)), ...
                spikeTimesArray(length(spikeTimesArray)));
        end
            
        % create a 1D array that will have value 1 at each spike time
        spikes1d = zeros(1, endTime + baselinePeriodLength + stimulusPeriodLength);
        
        % populate the spikes1d array
        spikes1d(spikeTimesArray) = 1;

        
        
        % create and fill the raster_data matrix
        % each row will be a different stimulus presentation
 
        % pre-allocate memory to speed things up
        raster_data = NaN * ones(length(stimPresentationTimesArray), baselinePeriodLength + stimulusPeriodLength);
        
        for iPresentation = 1:length(stimPresentationTimesArray)
            currPresentTime = stimPresentationTimesArray(iPresentation);
            raster_data(iPresentation, :) = spikes1d( (currPresentTime - baselinePeriodLength + 1) : currPresentTime  + stimulusPeriodLength);
        end
        
                
        
        % create the raster_labels struct
        % different stimulus sets have different relevant labels
                   
        if strcmp(stimulusSetName, 'natural_scenes')
            raster_labels.natural_scene_stimulus_id = stimulusInfoTable.frame;
        end
        
        
        if (strcmp(stimulusSetName, 'static_gratings') || strcmp(stimulusSetName,'drifting_gratings'))
            raster_labels.contrast = stimulusInfoTable.contrast;
            raster_labels.orientation = stimulusInfoTable.orientation;
            raster_labels.phase = extractRasterLabels('phase', stimulusInfoTable);  % stimulusInfoTable.phase; 
            raster_labels.size = extractRasterLabels('size', stimulusInfoTable);
            raster_labels.spatial_frequency = extractRasterLabels('spatial_frequency', stimulusInfoTable);  % stimulusInfoTable.spatial_frequency;   
            
            if (strcmp(stimulusSetName, 'drifting_gratings'))
                raster_labels.temporal_frequency = stimulusInfoTable.temporal_frequency; 
            end
            
        end
        

        if (strcmp(stimulusSetName, 'gabors') || strcmp(stimulusSetName, 'flashes'))
            raster_labels.contrast = stimulusInfoTable.contrast;
            raster_labels.orientation = stimulusInfoTable.orientation;
            raster_labels.phase = extractRasterLabels('phase', stimulusInfoTable);  % stimulusInfoTable.phase; 
            raster_labels.size = extractRasterLabels('size', stimulusInfoTable);
            raster_labels.spatial_frequency = extractRasterLabels('spatial_frequency', stimulusInfoTable);  % stimulusInfoTable.spatial_frequency; 
            raster_labels.temporal_frequency = extractRasterLabels('temporal_frequency', stimulusInfoTable);  % stimulusInfoTable.temporal_frequency; 
            raster_labels.x_position = stimulusInfoTable.x_position;
            raster_labels.y_position = stimulusInfoTable.y_position;
        end
        
        
        
        if (strcmp(stimulusSetName, 'natural_movie_one') || strcmp(stimulusSetName, 'natural_movie_three')) 
            raster_labels.contrast = stimulusInfoTable.contrast;
            raster_labels.size = extractRasterLabels('size', stimulusInfoTable);
            raster_labels.stimulus_frame_id = stimulusInfoTable.frame;
        end

        
        
       % no specific labels for "spontaneous" but will save trial numbers

      
        
        % additional trial info - not really labels but useful to have:
        % info on the trial number for this stimulus set, overall trial
        % number for the full session, and stimulus block (perhaps should be in raster_site_info?)
        raster_labels.trial_number = stimulusInfoTable.stimulus_block_id + 1;
        raster_labels.session_trial_number = stimulusInfoTable.stimulus_presentation_id + 1;
        raster_labels.stimulus_block =  stimulusInfoTable.stimulus_block;
        
        
        % should anything be done with this variables? 
        %    stimulus_condition_id   stimulus_block_condition_id  
        


       % create the raster_site_info struct
   
       % saving all unit fields as site info (apart from the structures
       % specimen and well_known_files) might be overkill but best to err 
       % on the side of perserving too much information.
       stimulus_info_names = unitsToUse.Properties.VariableNames;
       for iInfo = 1:(length(stimulus_info_names) - 2)
           
           eval(['raster_site_info.' stimulus_info_names{iInfo} ' = table2array(unitsToUse(iUnit, "' stimulus_info_names{iInfo} '"));']);
           curr_site_info_is_a_string = eval(['isstring(raster_site_info.' stimulus_info_names{iInfo} ');']);
           curr_site_info_is_a_datetime = eval(['isdatetime(raster_site_info.' stimulus_info_names{iInfo} ');']);
           curr_site_info_is_a_categorical = eval(['iscategorical(raster_site_info.' stimulus_info_names{iInfo} ');']);

           % convert to chars which works better with the NDT
           if (curr_site_info_is_a_string || curr_site_info_is_a_datetime || curr_site_info_is_a_categorical)
               eval(['raster_site_info.' stimulus_info_names{iInfo} ' = char(raster_site_info.' stimulus_info_names{iInfo} ');']);
           end
           
       end
        
       % add the stimulus onset time to the raster_site_info
       raster_site_info.alignment_event_time = baselinePeriodLength + 1;
        
        
       % save the raster data for each unit
       saveRasterFormatFileName = fullfile(saveDirectoryName, [num2str(raster_site_info.id) '.mat']);
       save(saveRasterFormatFileName, 'raster_data', 'raster_labels', 'raster_site_info');
        
       
    end
end





% A private helper function to get extract the raster labels
function raster_labels = extractRasterLabels(identifierID, stimulusInfoTable)
        strIDTable = convertvars(stimulusInfoTable(:, identifierID), identifierID, "string");
        charIDTable = convertvars(strIDTable, identifierID, "char");
        raster_labels = table2cell(charIDTable);
end
    
