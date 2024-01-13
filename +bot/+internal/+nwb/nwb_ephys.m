%% nwb_ephys - CLASS Encapsulate an NWB EPhys file

classdef nwb_ephys < handle
   properties (SetAccess = private)
      strFile string;                            % Path to the NWB file
      
      filter_out_of_brain_units logical;  % Flag indicating whether units outside of the brain should be filtered out
      filter_by_validity logical;         % Flag indicating whether invalid units should be filtered out
      amplitude_cutoff_maximum double;    % Maxmim amplitude to accept when filtering units
      presence_ratio_minimum double;      % Minimum presence ratio to accept when filtering units
      isi_violations_maximum double;      % Maximum ISI violation to accept when filtering units
      
      probe_lfp_paths;                    % List of paths to sidecar NWB files for probe data
      additional_unit_metrics;
      external_channel_columns;
   end
   
   methods
      function self = nwb_ephys(strFile, probe_lfp_paths, additional_unit_metrics, ...
            external_channel_columns, filter_out_of_brain_units, filter_by_validity, ...
            amplitude_cutoff_maximum, presence_ratio_minimum, isi_violations_maximum)
         
         % - Verify arguments
         arguments
            strFile string = "";
            probe_lfp_paths = [];
            additional_unit_metrics = [];
            external_channel_columns = [];
            filter_out_of_brain_units logical = true;
            filter_by_validity logical = true;
            amplitude_cutoff_maximum = 0.1;
            presence_ratio_minimum = 0.95;
            isi_violations_maximum = 0.5;
         end
         
         % - Handle no-argument calling
         if nargin == 0
            return;
         end
         
         try
            % - Attempt to access the file
            if ~strncmp(strFile, 's3', 2) % Skip for remote file as this is an expensive read operation.
                h5info(strFile);
            end
         catch
            error('BOT:AccessNotPossible', 'Cannot access NWB file [%s]', strFile);
         end
         
         % - Record file location
         self.strFile = strFile;
         
         self.filter_out_of_brain_units = filter_out_of_brain_units;
         self.filter_by_validity = filter_by_validity;
         self.amplitude_cutoff_maximum = amplitude_cutoff_maximum;
         self.presence_ratio_minimum = presence_ratio_minimum;
         self.isi_violations_maximum = isi_violations_maximum;
         
         self.probe_lfp_paths = probe_lfp_paths;
         
         self.additional_unit_metrics = additional_unit_metrics;
         self.external_channel_columns = external_channel_columns;
      end
      
      function test(self)
         % A minimal test to make sure that this API's NWB file exists and is
         % readable. Ecephys NWB files use the required session identifier field
         % to store the session id, so this is guaranteed to be present for any
         % uncorrupted NWB file.
         %
         % Of course, this does not ensure that the file as a whole is correct.
         self.fetch_ecephys_session_id();
      end
      
      function time = fetch_session_start_time(self)
         % - Read the session start time from the NWB file
         t = h5read(self.strFile, '/session_start_time');
         time = datetime(t,'TimeZone','UTC','Format','yyyy-MM-dd''T''HH:mm:ssXXXXX');
      end
      
      function all_epochs_table = build_epochs_table(self)
         % build_epochs_table — Build and return the high-level epochs table from the NWB file
         
         % - Get a list of all epochs in the NWB file
         strRoot = '/intervals';
         sEpochsInfo = h5info(self.strFile, strRoot);
         all_epoch_names = string({sEpochsInfo.Groups.Name});

         % If there is a dataset names trials (visual behavior), lets
         % ignore it.
         all_epoch_names = setdiff(all_epoch_names, '/intervals/trials', 'stable');

         % - Read each epoch as a table
         cstrIgnoreKeys = {'tags', 'timeseries', 'tags_index', 'timeseries_index'};
         cell_epoch_tables = {};
         cell_stimulus_conditions = {};
         for epoch_name = all_epoch_names
            cell_epoch_tables{end+1} = bot.internal.nwb.table_from_datasets(self.strFile, ...
               epoch_name, cstrIgnoreKeys);
            
            % - Identify unique stimulus conditions
            params_only = removevars_ifpresent(cell_epoch_tables{end}, ["start_time", "stop_time", "duration", "stimulus_block", "stimulus_presentation_id", "id"]);
            [cell_stimulus_conditions{end+1}, ~, stimulus_condition_id] = unique(params_only, 'rows', 'stable');
            cell_epoch_tables{end}.stimulus_block_condition_id = stimulus_condition_id-1;
         end
         
         % - Remove the "invalid times" table, if present
         invalid_times_table = ismember(all_epoch_names, '/intervals/invalid_times');
         invalid_times = cell_epoch_tables(invalid_times_table);
         cell_epoch_tables = cell_epoch_tables(~invalid_times_table);
         all_epoch_names = all_epoch_names(~invalid_times_table);
         
         % - Merge the tables
         all_epochs_table = sortrows(bot.internal.merge_tables(cell_epoch_tables{:}), 'start_time');
         
         % - Rename columns
         all_epochs_table = rename_variables(all_epochs_table, 'id', 'stimulus_block_id');
         
         % - Add an id column
         all_epochs_table.id = [0:size(all_epochs_table, 1)-1]';
      end

      function presentation_names = fetch_stimulus_presentation_names(self)
         % - Get a list of all epochs in the NWB file
         strRoot = '/intervals';
         sEpochsInfo = h5info(self.strFile, strRoot);
         presentation_names = string({sEpochsInfo.Groups.Name});
         
         presentation_names = replace(presentation_names, '/intervals/', '');
         presentation_names = replace(presentation_names, '_presentations', '');
         presentation_names = replace(presentation_names, 'invalid_times', 'invalid_presentation');
         presentation_names = transpose(presentation_names);

         % Skip trials (field introduced in Visual Behavior):
         presentation_names = setdiff(presentation_names, 'trials', 'stable');
      end

      function num_stimulus_presentations = fetch_num_stimulus_presentations(self)
         % fetch_num_stimulus_presentations - Return the number of stimulus presentations from the NWB file

         strRoot = '/intervals';
         datasetInfo = h5info(self.strFile, strRoot);
         %all_epoch_names = string({datasetInfo.Groups.Name});
         
         % Each datasetGroup represents stimulus presentations from 1 out of 9
         % categories.
         datasetGroups = [datasetInfo.Groups];
         groupNames = {datasetGroups.Name};
         
         keep = ~strcmp( groupNames, '/intervals/invalid_times');
        
         datasetStructArray = arrayfun(@(a) [a.Datasets], datasetGroups(keep), 'UniformOutput', 0);
         %datasetNameArray = cellfun(@(c) {c.Name}, datasetStructArray, 'UniformOutput', 0);
         
          % Note: All datasets within a group has the same lenght / number of samples
         datasetLengths = cellfun(@(c) c(1).Dataspace.Size, datasetStructArray, 'UniformOutput', 1);
         num_stimulus_presentations = sum(datasetLengths);
      end
      
      function stimulus_presentations = fetch_stimulus_presentations(self)
         % fetch_stimulus_presentations - Return the stimulus table from the NWB file
         
         % - Read epochs from the cached NWB file
         stimulus_presentations = self.build_epochs_table();
         
         % - Rename 'id' columns
         stimulus_presentations = rename_variables(stimulus_presentations, ...
            'id', 'stimulus_presentation_id');
         
         % - Filter out colour triplets to a "color_triplet" variable
         if ismember('color', stimulus_presentations.Properties.VariableNames)
            % - Find rows with color triplets
            strTripletRegexp = '\[(-{0,1}\d*\.\d*,\s*)*(-{0,1}\d*\.\d*)\]';
            stimulus_presentations.color = string(stimulus_presentations.color);
            vbMatches = ~cellfun(@isempty, regexp(stimulus_presentations.color, strTripletRegexp));
            
            % - Pull out those color triplets
            color_triplet = stimulus_presentations.color;
            color_triplet(~vbMatches) = {''};
            stimulus_presentations.color(vbMatches) = {''};
            
            % - Add as a new column
            stimulus_presentations = addvars(stimulus_presentations, color_triplet);
            
            % - Convert color column to numeric
            color = nan(numel(stimulus_presentations.color), 1);
            vbNonEmpty = stimulus_presentations.color ~= "";
            color(vbNonEmpty) = str2double(stimulus_presentations.color(vbNonEmpty));
            
            % - Replace color column
            stimulus_presentations = removevars(stimulus_presentations, 'color');
            stimulus_presentations = addvars(stimulus_presentations, color);
         end
      end 
      
      function trial_data = fetch_trials_data(self)
        
          trial_data = bot.internal.nwb.reader.vb.read_trials_timetable(self.strFile);
          return

          % Todo: Remove:
          trial_data = bot.internal.nwb.table_from_datasets_new(self.strFile, ...
               '/intervals/trials', {});

          % Process some of the columns for better representation
          trial_data.aborted = strcmp( trial_data.aborted, 'TRUE' );
          trial_data.auto_rewarded = strcmp( trial_data.auto_rewarded, 'TRUE' );
          trial_data.catch = strcmp( trial_data.catch, 'TRUE' );
          trial_data.correct_reject = strcmp( trial_data.correct_reject, 'TRUE' );
          trial_data.false_alarm = strcmp( trial_data.false_alarm, 'TRUE' );
          trial_data.go = strcmp( trial_data.go, 'TRUE' );
          trial_data.hit = strcmp( trial_data.hit, 'TRUE' );
          trial_data.is_change = strcmp( trial_data.is_change, 'TRUE' );
          trial_data.miss = strcmp( trial_data.miss, 'TRUE' );

          trial_data.start_time = seconds(trial_data.start_time);
          trial_data.stop_time = seconds(trial_data.stop_time);

          % Specify column order
          column_order = {...
              'id', ...
              'start_time', ...
              'stop_time', ...
              'initial_image_name', ...
              'change_image_name', ...
              'is_change', ...
              'change_time_no_display_delay', ...
              'go', ...
              'catch', ...
              'lick_times', ...
              'response_time', ...
              'reward_time', ...
              'reward_volume', ...
              'hit', ...
              'false_alarm', ...
              'miss', ...
              'correct_reject', ...
              'aborted', ...
              'auto_rewarded', ...
              'change_frame', ...
              'trial_length' ...
              };

          trial_data = trial_data(:, column_order);
      end

      function probes = fetch_probes(self)
         % - Retrieve the electrode groups (probes) from the NWB file
         sElectrodes = h5info(self.strFile, '/general/extracellular_ephys');
         cstrElectrodePaths = {sElectrodes.Groups.Name}';
         
         % - Remove the channel grouping
         cstrElectrodePaths = cstrElectrodePaths(~contains(cstrElectrodePaths, 'electrodes'));
         
         % - Get the IDs from the paths
         vnIDs = cellfun(@(c)sscanf(c, '/general/extracellular_ephys/%s'), cstrElectrodePaths);
         
         % - Read the attributes for each probe
         for nIndex = numel(cstrElectrodePaths):-1:1
            s = bot.internal.nwb.struct_from_attributes(self.strFile, cstrElectrodePaths{nIndex});
            probes(nIndex) = struct(...
               'id', vnIDs(nIndex), ...
               'description', s.description, ...
               'location', s.location, ...
               'sampling_rate', s.sampling_rate, ...
               'lfp_sampling_rate', s.lfp_sampling_rate, ...
               'has_lfp_data', str2num(string(lower(s.has_lfp_data)))); %#ok<ST2NM>
         end
      end
      
      function channels = fetch_channels(self)
         % - Retrieve the electrodes from the NWB file
         channels = bot.internal.nwb.table_from_datasets(self.strFile, '/general/extracellular_ephys/electrodes', 'group');
         
         % - Rename columns
         channels = rename_variables(channels, ...
            "manual_structure_id", "ephys_structure_id", ...
            "manual_structure_acronym", "ephys_structure_acronym", ...
            "location", "ephys_structure_acronym");

         % - Convert columns to reasonable formats
         if ismember('ephys_structure_id', channels.Properties.VariableNames)
            channels = convertvars(channels, 'ephys_structure_id', 'double');
         end
         
         if ~isempty(self.external_channel_columns)
            error('BOT:NotImplemented', 'This method is not implemented');
         %         if self.external_channel_columns is not None:
         %             external_channel_columns = self.external_channel_columns()
         %             channels = clobbering_merge(channels, external_channel_columns, left_index=true, right_index=true)
         end
         
         % - Filter channels by valid data, if requested
         channels.valid_data = cellfun(@str2num, lower(channels.valid_data));
         
         if self.filter_by_validity
            channels = channels(channels.valid_data, :);
         end
      end
      
      function mean_waveforms = fetch_mean_waveforms(self)
         units_table = self.fetch_full_units_table();
         mean_waveforms = units_table(:, {'id', 'waveform_mean'});
         mean_waveforms.Properties.VariableNames(1) = "unit_id";
      end
      
      function spike_times = fetch_spike_times(self)
         units_table = self.fetch_full_units_table();
         spike_times = units_table(:, {'id', 'spike_times'});
         spike_times.Properties.VariableNames(1) = "unit_id";
      end
      
      function spike_amplitudes = fetch_spike_amplitudes(self)
         units_table = self.fetch_full_units_table();
         spike_amplitudes = units_table(:, {'id', 'spike_amplitudes'});
         spike_amplitudes.Properties.VariableNames(1) = "unit_id";
      end
      
      function units = fetch_units(self)
         units = self.fetch_full_units_table();
         
         % - Remove variables
         to_drop = {'spike_times', 'spike_amplitudes', 'waveform_mean'};
         units = removevars(units, to_drop{:});

         % - Include additional metrics
         if ~isempty(self.additional_unit_metrics)
            error('BOT:NotImplemented', 'This method is not implemented');
            merge(units, self.additional_unit_metrics());
         end
      end
      
      function running_speed = fetch_running_speed(self, include_rotation)
         arguments
            self;
            include_rotation logical = false;
         end
         
         % - Identify where in the NWB file the data is located
         strEpochsKey = '/processing/running/running_speed';
         strEpochsKey2 = '/processing/running/running_speed_end_times';
         
         % - Read from the cached NWB file, return as a table
         running_speed_raw = bot.internal.nwb.table_from_datasets(self.strFile, strEpochsKey);         
         running_speed_end = bot.internal.nwb.table_from_datasets(self.strFile, strEpochsKey2);
         
         % - Construct return table
         start_time = running_speed_raw.timestamps;
         end_time = running_speed_end.timestamps;
         velocity = running_speed_raw.data;
         running_speed = table(start_time, end_time, velocity);
         
         if include_rotation
            error('BOT:NotImplemented', 'This method is not implemented');
         end
      end
      
      function running_speed = fetch_running_speed_visual_behavior(self)
         arguments
            self;
         end

         nwbDatasetPath = '/processing/running/speed';
         running_speed = bot.internal.nwb.table_from_datasets(self.strFile, nwbDatasetPath);         
         timestamps = seconds(running_speed.timestamps);
         speed = running_speed.data;
         running_speed = timetable(timestamps, speed);
         %running_speed = timetable(seconds(running_speed.timestamps), running_speed.data, 'VariableNames',{'RunningSpeed'});
      end

      function raw_running_data = fetch_raw_running_data(self)
         % - Read from the cached NWB file, return as a table
         rotation_series = bot.internal.nwb.table_from_datasets(self.strFile, '/acquisition/raw_running_wheel_rotation');
         signal_voltage_series = bot.internal.nwb.table_from_datasets(self.strFile, '/acquisition/running_wheel_signal_voltage');
         supply_voltage_series = bot.internal.nwb.table_from_datasets(self.strFile, '/acquisition/running_wheel_supply_voltage');
         
         % - Return the data as a table
         raw_running_data = table(rotation_series.timestamps, rotation_series.data, signal_voltage_series.data, supply_voltage_series.data, ...
            'VariableNames', {'frame_time', 'net_rotation', 'signal_voltage', 'supply_voltage'});
      end
      
      function rig_metadata = fetch_rig_metadata(self)
         if ~bot.internal.nwb.has_path(self.strFile, '/processing/eye_tracking_rig_metadata')
            error('BOT:DataNotPresent', 'This session has no rig geometry data.');
         end
         
         % As of december 2023, this field does not appear to exist in any
         % nwb ephys file:
         %rig_metadata.rig_geometry_data = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/eye_tracking_rig_metadata/rig_geometry_data');
         rig_metadata.rig_equipment = h5readatt(self.strFile, '/processing/eye_tracking_rig_metadata/eye_tracking_rig_metadata', 'equipment');
      end
      
      function eye_tracking_data = fetch_pupil_data(self, suppress_pupil_data)
         arguments
            self;
            suppress_pupil_data logical = true;
         end
         
         if ~bot.internal.nwb.has_path(self.strFile, '/processing/eye_tracking') || ...
            ~bot.internal.nwb.has_path(self.strFile, '/processing/raw_gaze_mapping') || ...
            ~bot.internal.nwb.has_path(self.strFile, '/processing/filtered_gaze_mapping')
            error('BOT:DataNotPresent', 'This session has no pupil data.');
         end
         
         raw_eye_area_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/raw_gaze_mapping/eye_area');
         raw_pupil_area_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/raw_gaze_mapping/pupil_area');
         raw_screen_coordinates_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/raw_gaze_mapping/screen_coordinates');
         raw_screen_coordinates_spherical_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/raw_gaze_mapping/screen_coordinates_spherical');
         
         filtered_eye_area_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/filtered_gaze_mapping/eye_area');
         filtered_pupil_area_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/filtered_gaze_mapping/pupil_area');
         filtered_screen_coordinates_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/filtered_gaze_mapping/screen_coordinates');
         filtered_screen_coordinates_spherical_ts = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/filtered_gaze_mapping/screen_coordinates_spherical');
         
         cr_ellipse_fits = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/eye_tracking/cr_ellipse_fits');
         eye_ellipse_fits = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/eye_tracking/eye_ellipse_fits');
         pupil_ellipse_fits = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/eye_tracking/pupil_ellipse_fits');
         
         cVariableNames = ["timestamps", ...
            "corneal_reflection_center_x", "corneal_reflection_center_y", ...
            "corneal_reflection_height", "corneal_reflection_width", ...
            "corneal_reflection_phi", ...
            "pupil_center_x", "pupil_center_y", ...
            "pupil_height", "pupil_width", "pupil_phi", ...
            "eye_center_x", "eye_center_y", ...
            "eye_height", "eye_width", "eye_phi"];

         eye_tracking_data = table(raw_eye_area_ts.timestamps, ...
            cr_ellipse_fits.center_x, ...
            cr_ellipse_fits.center_y, ...
            cr_ellipse_fits.height, ...
            cr_ellipse_fits.width, ...
            cr_ellipse_fits.phi, ...
            pupil_ellipse_fits.center_x, ...
            pupil_ellipse_fits.center_y, ...
            pupil_ellipse_fits.height, ...
            pupil_ellipse_fits.width, ...
            pupil_ellipse_fits.phi, ...
            eye_ellipse_fits.center_x, ...
            eye_ellipse_fits.center_y, ...
            eye_ellipse_fits.height, ...
            eye_ellipse_fits.width, ...
            eye_ellipse_fits.phi, 'VariableNames', cVariableNames);
            
         
         if ~suppress_pupil_data
            eye_tracking_data.raw_eye_area = raw_eye_area_ts.data;
            eye_tracking_data.raw_pupil_area = raw_pupil_area_ts.data;
            eye_tracking_data.raw_screen_coordinates_cm = raw_screen_coordinates_ts.data;
            eye_tracking_data.raw_screen_coordinates_spherical_deg = raw_screen_coordinates_spherical_ts.data;
            
            eye_tracking_data.filtered_eye_area = filtered_eye_area_ts.data;
            eye_tracking_data.filtered_pupil_area = filtered_pupil_area_ts.data;
            eye_tracking_data.filtered_screen_coordinates_cm = filtered_screen_coordinates_ts.data;
            eye_tracking_data.filtered_screen_coordinates_spherical_deg = filtered_screen_coordinates_spherical_ts.data;
         end
      end
      
      function pupil_data = fetch_pupil_data_visual_behavior(self)
         pupil_data = bot.internal.nwb.reader.vb.read_eyetracking_timetable(self.strFile);
      end 
      
      function lick_data = fetch_lick_data_visual_behavior(self)
         lick_data = bot.internal.nwb.reader.vb.read_lick_timetable(self.strFile);
      end

      function rewards_data = fetch_rewards_visual_behavior(self)
         rewards_data = bot.internal.nwb.reader.vb.read_rewards_timetable(self.strFile);
      end
      
      function id = fetch_ecephys_session_id(self)
         % - Read the identifier from the NWB file
         id = h5read(self.strFile, '/identifier');
         id = uint32(str2double(id));
      end
      
      function tos = fetch_optogenetic_stimulation(self)
         % - Read table from NWB file
         tos = bot.internal.nwb.table_from_datasets(self.strFile, '/processing/optotagging/optogenetic_stimulation', ...
            {'tags', 'tags_index', 'timeseries', 'timeseries_index'});
         
         variable_order = {'start_time', 'id', 'condition', 'level', 'stop_time', 'stimulus_name', 'duration'};
         tos = tos(:, variable_order);

         tos.start_time = seconds(tos.start_time);
         tos.stop_time = seconds(tos.stop_time);
         tos.duration = seconds(tos.duration);

         tt = table2timetable(tos);
        
         %variable_order = {'id', 'condition', 'level', 'stop_time', 'stimulus_name', 'duration'};
         %tos = tt(:, variable_order);

         et = eventtable(tt);
         et.Properties.EventEndsVariable = 'stop_time';
         et.Properties.EventLabelsVariable = 'condition';
         tos = et;
      end
      
      function units = fetch_full_units_table(self)
         % - Read base units table
         
         units = bot.internal.nwb.reader.readDynamicTable(self.strFile, '/units', ...
            {'spike_amplitudes', 'spike_amplitudes_index', ...
            'waveform_mean', 'waveform_mean_index',  ...
            'spike_times', 'spike_times_index'});
        
         % Todo: These can be read with the function above instead of
         % reading them individually like here:

         % - Read additional wrapped data entries
         units.spike_amplitudes = bot.internal.nwb.deindex_table_from_datasets(self.strFile, ...
            '/units/spike_amplitudes', '/units/spike_amplitudes_index');

         units.waveform_mean = bot.internal.nwb.deindex_table_from_datasets(self.strFile, ...
            '/units/waveform_mean', '/units/waveform_mean_index');

         units.spike_times = bot.internal.nwb.deindex_table_from_datasets(self.strFile, ...
            '/units/spike_times', '/units/spike_times_index');


         % - Filter units
         if self.filter_by_validity || self.filter_out_of_brain_units
            channels = self.fetch_channels();
            
            if self.filter_out_of_brain_units
               if ismember(channels.Properties.VariableNames, 'ephys_structure_id')
                  channels = channels(~isnan(channels.ephys_structure_id), :);
               elseif ismember(channels.Properties.VariableNames, 'ephys_structure_acronym')
                  channels = channels(~cellfun(@isempty, channels.ephys_structure_acronym), :);
               end
               
            end
            
            vbSelectUnits = ismember(units.peak_channel_id, channels.id);
            units = units(vbSelectUnits, :);
         end
         
         if self.filter_by_validity
            vbSelectUnits = units.quality == "good";
            units = units(vbSelectUnits, :);
            units = removevars(units, 'quality');
         end
         
         units = units(units.amplitude_cutoff <= self.amplitude_cutoff_maximum, :);
         units = units(units.presence_ratio >= self.presence_ratio_minimum, :);
         units = units(units.isi_violations <= self.isi_violations_maximum, :);
         
         % - Remove invalid spikes and sort
         units = remove_invalid_spikes_from_table(units);
      end
      
      function metadata = fetch_nwb_metadata(self)
         if ~bot.internal.nwb.has_path(self.strFile, '/general/metadata')
            error('BOT:DataNotPresent', 'This NWB file has no metadata.');
         end
         
         metadata = bot.internal.nwb.struct_from_attributes(self.strFile, '/general/metadata');
      end
      
      function invalid_times = fetch_invalid_times(self)
         if self.has_invalid_times()
            invalid_times = bot.internal.nwb.table_from_datasets(self.strFile, '/intervals/invalid_times', {'tags', 'tags_index'});
            invalid_times.tags = bot.internal.nwb.deindex_table_from_datasets(self.strFile, ...
                '/intervals/invalid_times/tags', '/intervals/invalid_times/tags_index');
         else
            invalid_times = [];
         end
      end

      function tf = has_invalid_times(self)
      %has_invalid_times Check if '/intervals/invalid_times' is present in nwb file  
         datasetInfo = h5info(self.strFile, '/intervals');

         datasetGroups = [datasetInfo.Groups];
         groupNames = {datasetGroups.Name};
         
         tf = any( strcmp( groupNames, '/intervals/invalid_times') );
      end

      function im = fetch_image(self, name, module, image_api)
         error('BOT:NotImplemented', 'This method is not implemented');
         %         if image_api is None:
         %             image_api = ImageApi
         %
         %         nwb_img = self.nwbfile.modules[module].fetch_data_interface('images')[name]
         %         data = nwb_img.data
         %         resolution = nwb_img.resolution  # px/cm
         %         spacing = [resolution * 10, resolution * 10]
         %
         %         return ImageApi.serialize(data, spacing, 'mm')
         
      end
   end
end

function tRename = rename_variables(tRename, varargin)
   % rename_variables - FUNCTION Rename variables in a table
   %
   % Usage: tRename = rename_variables(tRename, 'var_source_A', 'var_dest_A', 'var_source_B', 'var_dest_B', ...)
   %
   % Source variables will be renamed (if found) to destination variable
   % names.

   % - Loop over pairs of source/dest names
   for nVar = 1:2:numel(varargin)
      % - Find variables matching the source name
      vbVarIndex = tRename.Properties.VariableNames == string(varargin{nVar});

      if any(vbVarIndex)
         % - Rename this variable to the destination name
         tRename.Properties.VariableNames(vbVarIndex) = string(varargin{nVar + 1});
      end
   end
end
  
function units = remove_invalid_spikes_from_table(units, times_key, amps_key)
%remove_invalid_spikes_from_table Remove data for spikes with invalid spike times   

   arguments
      units table;
      times_key char = 'spike_times';
      amps_key char = 'spike_amplitudes';
   end

   selected_unit_data = units{:, {times_key, amps_key}};
   
   num_units = size(selected_unit_data, 1);
   for i = 1:num_units % Loop through each unit
      
      % - Extract spike times and amplitudes for current unit
      i_spike_times = selected_unit_data{i, 1};
      i_amplitudes = selected_unit_data{i, 2};
      
      % - Select valid times
      valid = i_spike_times > 0;
      i_spike_times = i_spike_times(valid);
      i_amplitudes = i_amplitudes(valid);
      
      % - Sort spike times
      [i_sorted_spike_times, order] = sort(i_spike_times);
      
      selected_unit_data(i,:) = {i_sorted_spike_times, i_amplitudes(order)};
   end
   units{:, {times_key, amps_key}} = selected_unit_data;
end

function source_table = removevars_ifpresent(source_table, variables)
   vbHasVariable = ismember(variables, source_table.Properties.VariableNames);
   
   if any(vbHasVariable)
      source_table = removevars(source_table, variables(vbHasVariable));
   end
end
