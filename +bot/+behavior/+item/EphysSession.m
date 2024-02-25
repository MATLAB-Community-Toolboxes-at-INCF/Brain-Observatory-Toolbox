%
% Represent direct, linked, and derived data for a Visual Behavior Neuropixels dataset [1] experimental session.
%
% [1] Copyright 2019 Allen Institute for Brain Science. Visual Behavior Neuropixels dataset. Available from: https://portal.brain-map.org/explore/circuits/visual-behavior-neuropixels

% Note: This is adapted (with very minor changes) from the VisualCoding 
% EphysSession class to work with the VisualBehavior dataset.

classdef EphysSession < bot.item.Session
    
    
    %% PROPERTIES
    
    % Info Item Values
    properties (Dependent)
        structure_acronyms             % EPhys structures recorded across all channels in this session
    end
    
    % Linked Items
    properties (SetAccess = private)
        units                          % A Table of all units in this session
        probes                         % A Table of all probes in this session
        channels                       % A Table of all channels in this session
    end
    
    % Linked Item Values
    properties (SetAccess = private)
        channel_structure_intervals    % Table of channel intervals crossing a particular brain structure for this session
        structurewise_unit_counts      % Numbers of units (putative neurons) recorded in each of the EPhys structures recorded in this session
    end
    
    % Linked File Values (SessNWB file)
    properties (Dependent, Transient)  % Transient used here as "tag" for linked file properties
        
        % Physiology data
        mean_waveforms                 % Table mapping unit ids to matrices containing mean spike waveforms for that unit
        spike_amplitudes               % Table of extracted spike amplitudes for all units
        spike_times                    % Maps integer unit ids to arrays of spike times (float) for those units
        
        % Behavior data
        running_speed                  % [Tx2] array of running speeds, where each row is [timestamp running_speed]
        pupil_data                     % Table of pupil data captured via eye tracking during session
        %pupil_data_detailed           % Table of pupil data captured via eye tracking during session, including detailed gaze tracking information
        licks                          % Table of lick data
        rewards                        % Table of rewards

        % Metadata
        inter_presentation_intervals   % The elapsed time between each immediately sequential pair of stimulus presentations. This is a dataframe with a two-level multiindex (levels are 'from_presentation_id' and 'to_presentation_id'). It has a single column, 'interval', which reports the elapsed time between the two presentations in seconds on the experiment's master clock
        session_start_time             % Timestamp of start of session
        invalid_times                  % Table indicating invalid recording times
        
        trials
        stimulus_presentations         % Table whose rows are stimulus presentations and whose columns are presentation characteristics. A stimulus presentation is the smallest unit of distinct stimulus presentation and lasts for (usually) 1 60hz frame. Since not all parameters are relevant to all stimuli, this table contains many 'null' values
        stimulus_conditions            % Table indicating unique stimulus presentations presented in this experiment
        num_stimulus_presentations     % Number of stimulus presentations in this session % TODO: consider property revival if there is a way to get at size without full stimulus_presentations access
        stimulus_names                 % Names of stimuli presented in this session
        stimulus_epochs                % Table of stimulus presentation epochs
        optotagging_table % Table of optogenetic stimulation epochs for this experimental session (if present)
        
        rig_metadata                   % Metadata about rig used for this session (e.g. rig name, rig geometry)
    end

    % Linked File Values (StimTemplatesGroup files)
    properties (Dependent, Transient)  % Transient used here as "tag" for linked file properties
        stimulus_templates             % Stimulus template table
    end
    
    %%  PROPERTIES - HIDDEN
    
    properties (Hidden = true, Access = public, Transient = true)
        warn_multiple_probes = false
        nwb_metadata  % TODO: consider to generalize this in the Session object superclass
        
        
        NON_STIMULUS_PARAMETERS = [
            "start_time", ...
            "stop_time", ...
            "duration", ...
            "stimulus_block", ...
            "stimulus_condition_id"]
        
        DETAILED_STIMULUS_PARAMETERS = [
            "colorSpace", ...
            "flipHoriz", ...
            "flipVert", ...
            "depth", ...
            "interpolate", ...
            "mask", ...
            "opacity", ...
            "rgbPedestal", ...
            "tex", ...
            "texRes", ...
            "units", ...
            "rgb", ...
            "signalDots", ...
            "noiseDots", ...
            "fieldSize", ...
            "fieldShape", ...
            "fieldPos", ...
            "nDots", ...
            "dotSize", ...
            "dotLife", ...
            "color_triplet"]
        
        FIRST_STIMULUS_PARAMETERS = [
            "stimulus_presentation_id" ...
            "stimulus_condition_id" ...
            "stimulus_block_id" ...
            "stimulus_block_condition_id" ...
            "stimulus_name" ...
            "start_time" ...
            "stop_time"]
    end
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        DATASET_TYPE = bot.item.internal.enum.DatasetType("Ephys")
    end
    
    properties (Hidden)
        CORE_PROPERTIES = zlclInitDirectProps()
        LINKED_ITEM_PROPERTIES = ["probes", "channels", "units"]
    end
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.LinkedFilesItem)
    properties (Hidden, SetAccess = protected)
        LINKED_FILE_PROP_BINDINGS = zlclInitLinkedFilePropBindings
    end
    
    properties (Hidden, Dependent, Access=protected)
        nwbLocal
    end
    
    properties (Hidden, Access=private)
        nwbLocal_
    end

    properties (Access = public)
        % Todo: make dependent on dataset the session belongs to:
        FileResource = bot.internal.fileresource.visualbehavior.VBEphysS3Bucket.instance()
    end
    
    
    %% PROPERTY ACCESS METHODS
    
    % VISIBLE PROPERTIES - from Item info
    methods
        function trial_data = get.trials(self)
            trial_data = self.fetch_cached('trial_data', @self.zprpReadTrialsTable);
        end

        function inter_presentation_intervals = get.inter_presentation_intervals(self)
            inter_presentation_intervals = self.fetch_cached('inter_presentation_intervals', @self.zprpBuildInterPresentationIntervals);
        end
        
        function num_stimulus_presentations = get.num_stimulus_presentations(self)
            num_stimulus_presentations = self.fetch_cached('num_stimulus_presentations', ...
                @()self.nwbLocal.fetch_num_stimulus_presentations());
        end
        
        function stimulus_names = get.stimulus_names(self)
            stimulus_names = self.fetch_cached('stimulus_names', ...
                @()self.nwbLocal.fetch_stimulus_presentation_names());
        end
        
        function structure_acronyms = get.structure_acronyms(self)
            info_field_name = 'structure_acronyms';
            structure_acronyms = strip(split(self.info.(info_field_name),";"))';
        end
        
        function structurewise_unit_counts = get.structurewise_unit_counts(self)
            %all_acronyms = self.units.ephys_structure_acronym;
            all_acronyms = self.units.structure_acronym;
            [ephys_structure_acronym, ~, structurewise_unit_ids] = unique(all_acronyms);
            count = accumarray(structurewise_unit_ids, 1);
            
            structurewise_unit_counts = table(ephys_structure_acronym, count);
            structurewise_unit_counts = sortrows(structurewise_unit_counts, 2, 'descend');
        end
        
        function pupilData = get.pupil_data(self)
            n = self.nwbLocal;
            pupilData = self.fetch_cached('pupil_data', @()n.fetch_pupil_data_visual_behavior); % suppress detailed gaze tracking info
        end
        
        % function pupilData = get.pupil_data_detailed(self)
        %     n = self.nwbLocal;
        %     pupilData = self.fetch_cached('pupil_data_detailed', @()n.fetch_pupil_data(false)); % include (don't suppress) detailed gaze tracking info
        % end

        function lickData = get.licks(self)
            n = self.nwbLocal;
            lickData = self.fetch_cached('licks', @()n.fetch_lick_data_visual_behavior);
        end

        function rewardData = get.rewards(self)
            n = self.nwbLocal;
            rewardData = self.fetch_cached('rewards', @()n.fetch_rewards_visual_behavior);
        end

        function tbl = get.channel_structure_intervals(self)
            
            %structure_id_key = "ephys_structure_id";
            %structure_label_key = "ephys_structure_acronym";
            structure_label_key = "structure_acronym";

            channel_ids = self.channels.id;
            
            select_channels = ismember(self.channels.id, channel_ids);
            channels_selected = self.channels(select_channels, :);
            
            unique_probes = unique(self.channels.ephys_probe_id);
            if numel(unique_probes) > 1
                self.raise_MultipleProbes_warning()
            end
            
            tbl = table;
            tbl.intervals = zlclDiffIntervals(channels_selected.(structure_label_key))';
            tbl.labels = channels_selected.(structure_label_key)(tbl.intervals);
        end
       
        function raise_MultipleProbes_warning(self)
            self.warn_multiple_probes = true;
            warning('BOT:MultipleProbes', "Calculating structure boundaries across channels from multiple probes.")
        end

    end
    
    % VISIBLE PROPERTIES - from Primary File (NWB)
    methods
        
        function optotagging_table = get.optotagging_table(self)
            n = self.nwbLocal;
            try
                optotagging_table = self.fetch_cached('optotagging_table', @n.fetch_optogenetic_stimulation);
            catch
                optotagging_table = [];
            end
        end
        
        function session_start_time = get.session_start_time(self)
            n = self.nwbLocal;
            session_start_time = self.fetch_cached('session_start_time', @n.fetch_session_start_time);
        end
        
        function spike_amplitudes = get.spike_amplitudes(self)
            spike_amplitudes = self.fetch_cached('spike_amplitudes', @self.fetch_spike_amplitudes);
        end
                
        function spike_times = get.spike_times(self)
            if ~self.in_cache('checked_spike_times')
                self.warn_invalid_spike_intervals();
                self.property_cache.checked_spike_times = true;
            end
            
            spike_times = self.fetch_cached('spike_times', @self.fetch_spike_times);
            
            % CONSIDER FOR REMOVAL - currently build_spike_times appears a no-op, but should explore if it has a use case
            %             if ~self.in_cache('spike_times')
            %                 self.property_cache.spike_times = self.build_spike_times(self.nwbLocal.fetch_spike_times());
            %             end
            %
            %             spike_times = self.property_cache.spike_times;
        end
        
        function invalid_times = get.invalid_times(self)
            n = self.nwbLocal;
            invalid_times = self.fetch_cached('invalid_times', @n.fetch_invalid_times);
        end
        
        function running_speed = get.running_speed(self)
            n = self.nwbLocal;
            running_speed = self.fetch_cached('running_speed', @n.fetch_running_speed_visual_behavior);
        end
        
        function rig_metadata = get.rig_metadata(self)
            n = self.nwbLocal;
            rig_metadata = self.fetch_cached('rig_metadata', @n.fetch_rig_metadata);
        end
        
        function mean_waveforms = get.mean_waveforms(self)
            mean_waveforms = self.fetch_cached('mean_waveforms', @self.fetch_mean_waveforms);
        end
        
        function stimulus_conditions = get.stimulus_conditions(self)
            stimulus_conditions = self.fetch_cached('stimulus_conditions',@self.zprpGetStimulusConditions);
        end
        
        function stimulus_presentations = get.stimulus_presentations(self)
            stimulus_presentations = self.fetch_cached('stimulus_presentations',@self.zprpGetStimulusPresentations);
        end
    end
    
    % VISIBLE PROPERTIES - Auxiliary File (NWB)
    methods
        function stimulus_table = get.stimulus_templates(self)
            stimulus_table = self.fetch_cached('stimulus_templates', @self.zprpGetStimulusTemplates);
        end
        
        function epochs = get.stimulus_epochs(self)
            epochs = self.fetch_cached('stimulus_epochs', @self.getStimulusEpochsByDuration);
        end
        
    end
    
    % HIDDEN PROPERTIES - Primary File (NWB)
    methods
        
        function nwb = get.nwbLocal(obj)
            
            % Reset linked file if remote file is set and preference to
            % download remote file:
            if strncmp( obj.linkedFiles{"SessNWB","LocalFile"}, 's3', 2) && ~obj.prefersToReadRemoteFile()
               obj.resetLinkedFile("SessNWB")
               obj.nwbLocal_ = [];
            end

            if isempty(obj.nwbLocal_)                
                if ismissing( obj.linkedFiles{"SessNWB","LocalFile"} )
                    obj.downloadLinkedFile("SessNWB");
                end
                obj.nwbLocal_ = bot.internal.nwb.nwb_ephys(obj.linkedFiles{"SessNWB","LocalFile"});
            end
            nwb = obj.nwbLocal_;
        end
        
        function metadata = get.nwb_metadata(self)
            n = self.nwbLocal;
            metadata = self.fetch_cached('metadata', @n.fetch_nwb_metadata);
        end
        
    end
    
    % PROPERTY ACCESS HELPERS
    methods (Access=private)
        
        function stimulus_presentations = zprpGetStimulusPresentations(self)
            % - Generate and cache stimulus presentations table
            self.zprpCacheStimulusPresentations();
            
            % - Clean and return stimulus presentations table
            stimulus_presentations = self.remove_detailed_stimulus_parameters(self.property_cache.stimulus_presentations_raw);

            stimulus_presentations.active = strcmp(stimulus_presentations.active, 'TRUE');
            stimulus_presentations.is_sham_change = strcmp(stimulus_presentations.is_sham_change, 'TRUE');
        end
        
        function stimulus_conditions = zprpGetStimulusConditions(self)
            self.zprpCacheStimulusPresentations();
            stimulus_conditions = self.property_cache.stimulus_conditions_raw;
        end
        
        
        function stimulus_table = zprpGetStimulusTemplates(self)
            
            stimulus_table = self.linkedFileRespTables.("StimTemplatesGroup");
            
            % - Convert table variables to sensible types
            stimulus_table.attachable_id = int64(stimulus_table.attachable_id);
            stimulus_table.attachable_type = string(stimulus_table.attachable_type);
            stimulus_table.download_link = string(stimulus_table.download_link);
            stimulus_table.id = int64(stimulus_table.id);
            stimulus_table.path = string(stimulus_table.path);
            stimulus_table.well_known_file_type_id = int64(stimulus_table.well_known_file_type_id);
            
            % - Loop over stimulus templates
            scene_number = nan(size(stimulus_table, 1), 1);
            movie_number = nan(size(stimulus_table, 1), 1);
            for row_ind = 1:size(stimulus_table, 1)
                row = stimulus_table(row_ind, :);
                
                if contains(row.path, 'natural_movie_')
                    [~, str_movie_number, ~] = fileparts(row.path);
                    movie_number(row_ind) = sscanf(str_movie_number, 'natural_movie_%d');
                    scene_number(row_ind) = nan;
                    
                elseif contains(row.path, '.tiff')
                    [~, scene_number(row_ind), ~] = fileparts(row.path);
                    movie_number(row_ind) = nan;
                end
            end
            
            stimulus_table.scene_number = scene_number;
            stimulus_table.movie_number = movie_number;
        end
        
        function zprpCacheStimulusPresentations(self)
            if ~self.in_cache('stimulus_presentations_raw') || ~self.in_cache('stimulus_conditions_raw')
                % - Read stimulus presentations from NWB file
                stimulus_presentations_raw = self.nwbLocal.fetch_stimulus_presentations();

                % - Build stimulus presentations tables
                [stimulus_presentations_raw, stimulus_conditions_raw] = self.build_stimulus_presentations(stimulus_presentations_raw);
                
                % - Mask invalid presentations
                stimulus_presentations_raw = self.mask_invalid_stimulus_presentations(stimulus_presentations_raw);
                
                % Order ID and time variables leftmost in stimulus tables
                stimulus_presentations_raw = movevars(stimulus_presentations_raw, self.FIRST_STIMULUS_PARAMETERS, 'Before', 1);
                
                condFirstStimParams = self.FIRST_STIMULUS_PARAMETERS(ismember(self.FIRST_STIMULUS_PARAMETERS, string(stimulus_conditions_raw.Properties.VariableNames)));
                stimulus_conditions_raw = movevars(stimulus_conditions_raw, condFirstStimParams, 'Before', 1);
                
                % - Make a timetable
                stimulus_presentations_tt = table2timetable(stimulus_presentations_raw, "RowTimes", seconds(stimulus_presentations_raw.start_time));
                stimulus_presentations_tt.duration = stimulus_presentations_tt.stop_time - stimulus_presentations_tt.start_time;

                % - Insert into cache
                self.property_cache.stimulus_presentations_raw = stimulus_presentations_tt;
                self.property_cache.stimulus_conditions_raw = stimulus_conditions_raw;
            end
        end
        
        function intervals = zprpBuildInterPresentationIntervals(self)
            self.zprpCacheStimulusPresentations();
            from_presentation_id = self.property_cache.stimulus_presentations_raw.stimulus_presentation_id(1:end-1);
            to_presentation_id = self.property_cache.stimulus_presentations_raw.stimulus_presentation_id(2:end);
            interval = self.property_cache.stimulus_presentations_raw.start_time(2:end) - self.property_cache.stimulus_presentations_raw.stop_time(1:end-1);
            
            intervals = table(from_presentation_id, to_presentation_id, interval);
        end

        function trials_data = zprpReadTrialsTable(self)
         
            trials_data = self.nwbLocal.fetch_trials_data();



        end
        
    end
    
    
    %% CONSTRUCTOR
    
    methods
        function obj = EphysSession(itemIDSpec)
            
            % Superclass construction
            obj = obj@bot.item.Session(itemIDSpec);
            
            % Only process attributes if we are constructing a scalar object
            if obj.isItemIDSpecScalar( itemIDSpec )

                % Reassign manifest:
                obj.manifest = bot.internal.metadata.VisualBehaviorEphysManifest.instance();

                % - Assign associated table rows
                obj.probes = obj.manifest.Probes(obj.manifest.Probes.ephys_session_id == obj.id, :);
                obj.channels = obj.manifest.Channels(obj.manifest.Channels.ephys_session_id == obj.id, :);
                obj.units = obj.manifest.Units(obj.manifest.Units.ephys_session_id == obj.id, :);
                
                % Identify property display groups
                obj.ITEM_INFO_VALUE_PROPERTIES = "structure_acronyms";
                obj.LINKED_ITEM_VALUE_PROPERTIES = ["channel_structure_intervals" "structurewise_unit_counts"];
                obj.CORE_PROPERTIES = setdiff(obj.CORE_PROPERTIES,[obj.ITEM_INFO_VALUE_PROPERTIES obj.LINKED_ITEM_VALUE_PROPERTIES]); % remove from introspection-derived property list
                
                % Superclass initialization (bot.item.internal.abstract.LinkedFilesItem)
                obj.initSession();
                
                obj.LINKED_FILE_AUTO_DOWNLOAD.StimTemplatesGroup = false;
                ecephys_product_id = 714914585;
                obj.fetchLinkedFileInfo("StimTemplatesGroup", sprintf("rma::criteria,well_known_file_type[name$eq\'Stimulus\'][attachable_type$eq\'Product\'][attachable_id$eq%d]", ecephys_product_id),true);
                
                obj.initLinkedFiles();
                
                % Local prop initializations
                if ~ismissing( obj.linkedFiles{"SessNWB","LocalFile"} )
                    obj.nwbLocal_ = bot.internal.nwb.nwb_ephys(obj.linkedFiles{"SessNWB","LocalFile"});
                end
            end
        end
    end

    % INITIALIZER
    methods (Access=protected)
        function initSession(obj)
            % Superclass initialization (bot.item.internal.abstract.LinkedFilesItem)
            obj.LINKED_FILE_AUTO_DOWNLOAD = struct("SessNWB", ...
                bot.internal.Preferences.getPreferenceValue('AutoDownloadNwb'));

            url = obj.getS3Filepath("SessNWB");
            uriObj = matlab.net.URI(url);

            fileInfo.path = fullfile(uriObj.Path{:});
            fileInfo.download_link = url;
            
            obj.insertLinkedFileInfo("SessNWB", fileInfo);
        end
    end
    
    %% METHODS - VISIBLE
    
    methods
        
        function epochs = getStimulusEpochsByDuration(self, duration_thresholds)
            % Reports continuous periods of time during which a single kind of stimulus was presented
            
            arguments
                self;
                duration_thresholds = struct('spontaneous_activity', 90); % Optional structure specifying minimum duration (seconds) required for specified stimulus_names to be reported as an epoch
            end
            
            presentations = self.stimulus_presentations;
            diff_indices = zlclDiffIntervals(presentations.stimulus_block);
            
            epochs.start_time = presentations.start_time(diff_indices(1:end-1));
            epochs.stop_time = presentations.stop_time(diff_indices(2:end)-1);
            epochs.stimulus_name = presentations.stimulus_name(diff_indices(1:end-1));
            epochs.stimulus_block = presentations.stimulus_block(diff_indices(1:end-1));
            
            epochs = struct2table(epochs);
            epochs.duration = epochs.stop_time - epochs.start_time;
            
            for strField = fieldnames(duration_thresholds)
                select_epochs = epochs.stimulus_name ~= strField{1};
                select_epochs = select_epochs | epochs.duration >= duration_thresholds.(strField{1});
                epochs = epochs(select_epochs, :);
            end
            
            epochs = epochs(:, ["start_time", "stop_time", "duration", "stimulus_name", "stimulus_block"]);
            epochs = table2timetable(epochs, "RowTimes", seconds(epochs.start_time));
        end
        
        function [tiled_data, time_base] = getPresentationwiseSpikeCounts(self, ...
                bin_edges, stimulus_presentation_ids, unit_ids, binarize, ...
                large_bin_size_threshold, time_domain_callback)
            % Build array of spike counts surrounding stimulus onset per unit and stimulus frame
            
            arguments
                self;
                bin_edges;  % Spikes will be counted into the bins defined by these edges. Values are in seconds, relative to stimulus onset
                stimulus_presentation_ids; % Filter to these stimulus presentations
                unit_ids;  % Filter to these units
                binarize logical = false; % If true, all counts greater than 0 will be treated as 1. This results in lower storage overhead, but is only reasonable if bin sizes are fine (<= 1 millisecond).
                large_bin_size_threshold = 0.001;  % If binarize is True and the largest bin width is greater than this value, a warning will be emitted.
                time_domain_callback function_handle = @(x)x; % Optional Callback function applied to the time domain before counting spikes. Returns numeric array whose values are trial-aligned bin edges (each row is aligned to a different trial).
            end
            
            % - Filter stimulus_presentations table
            stimulus_presentations = self.stimulus_presentations; %#ok<PROPLC>
            select_stimuli = ismember(stimulus_presentations.stimulus_presentation_id, stimulus_presentation_ids); %#ok<PROPLC>
            stimulus_presentations = stimulus_presentations(select_stimuli, :); %#ok<PROPLC>
            
            % - Filter units table
            select_units = ismember(self.units.id, unit_ids);
            units_selected = self.units(select_units, :);
            
            largest_bin_size = max(diff(bin_edges));
            
            if binarize && largest_bin_size > large_bin_size_threshold
                warning('BOT:BinarizeLargeBin', ...
                    ['You''ve elected to binarize spike counts, but your maximum bin width is {largest_bin_size:2.5f} seconds. \n', ...
                    'Binarizing spike counts with such a large bin width can cause significant loss of accuracy! ', ...
                    'Please consider only binarizing spike counts when your bins are <= %.2f seconds wide.'], large_bin_size_threshold);
            end
            
            domain = zlclBuildTimeWindowWomain(bin_edges, stimulus_presentations.start_time, time_domain_callback); %#ok<PROPLC>
            
            out_of_order = diff(domain) < 0;
            if any(out_of_order)
                rows, cols = find(out_of_order);
                error('BOT:OutOfOrder', 'The time domain specified contains out-of-order bin edges at indices\n%s', sprintf("[%d %d]\n", rows, cols));
            end
            
            ends = domain(end, :);
            starts = domain(1, :);
            time_diffs = starts(2:end) - ends(1:end-1);
            overlapping = find(time_diffs < 0, 1);
            
            if ~isempty(overlapping)
                warning('BOT:OverlappingIntervals', ['You''ve specified some overlapping time intervals between neighboring rows. \n%s\n', ...
                    'with a maximum overlap of %.2f seconds.']);%, sprintf('[%d %d]\n', [overlapping; overlapping+1]), abs(min(time_diffs)));
            end
            
            % - Build a histogram of spikes
            tiled_data = zlclBuildSpikeHistogram(domain, self.spike_times, units_selected.id, binarize);
            
            % - Generate a time base for `tiled_data`
            time_base = bin_edges(1:end-1) + diff(bin_edges) / 2;
        end
        
        function spikes_with_onset = getPresentationwiseSpikeTimes(self, stimulus_presentation_ids, unit_ids)
            % Produce a table associating spike times with units and stimulus presentations
            
            arguments
                self;
                stimulus_presentation_ids = [];   % Filter to these stimulus presentations
                unit_ids = [];  % Filter to these units
            end
            
            % - Filter stimulus_presentations table
            stimulus_presentations = self.stimulus_presentations; %#ok<PROPLC>
            
            if ~isempty(stimulus_presentation_ids)
                select_stimuli = ismember(stimulus_presentations.stimulus_presentation_id, stimulus_presentation_ids); %#ok<PROPLC>
                stimulus_presentations = stimulus_presentations(select_stimuli, :); %#ok<PROPLC>
            end
            
            % - Filter units table
            if ~isempty(unit_ids)
                select_units = ismember(self.units.id, unit_ids);
                units_selected = self.units(select_units, :);
            else
                units_selected = self.units;
            end
            
            presentation_times = zeros(size(stimulus_presentations, 1) * 2, 1); %#ok<PROPLC>
            presentation_times(1:2:end) = stimulus_presentations.start_time; %#ok<PROPLC>
            presentation_times(2:2:end) = stimulus_presentations.stop_time; %#ok<PROPLC>
            all_presentation_ids = stimulus_presentations.stimulus_presentation_id; %#ok<PROPLC>
            
            presentation_ids = [];
            unit_ids = [];
            spike_times = []; %#ok<PROPLC>
            
            for unit_index = 1:numel(units_selected.id)
                unit_id = units_selected.id(unit_index);
                
                % - Extract the spike times for this unit
                select_stimuli = self.spike_times.unit_id == unit_id;
                data = self.spike_times(select_stimuli, :).spike_times{1};
                
                % - Find the locations of the presentation times in the spike data
                indices = zlclSearchSorted(presentation_times, data) - 2;
                
                index_valid = mod(indices, 2) == 0;
                p_indices = floor(indices / 2);
                p_indices(p_indices == -1) = numel(all_presentation_ids)-1;
                p_indices = p_indices + 1;
                presentations = all_presentation_ids(p_indices);
                
                [presentations, order] = sort(presentations);
                index_valid = index_valid(order);
                data = data(order);
                
                changes = find([1; diff(presentations); 1]);
                for change_index = 1:numel(changes)-1
                    ii = changes(change_index);
                    jj = changes(change_index+1)-1;
                    
                    values = data(ii:jj);
                    values = values(index_valid(ii:jj));
                    
                    if isempty(values)
                        continue
                    end
                    
                    unit_ids = [unit_ids; zeros(numel(values), 1, 'like', unit_id) + unit_id]; %#ok<AGROW>
                    presentation_ids = [presentation_ids; zeros(numel(values), 1, 'like', presentations) + presentations(ii)]; %#ok<AGROW>
                    spike_times = [spike_times; values]; %#ok<AGROW,PROPLC>
                end
            end
            
            % - Handle the case when no spikes occurred
            if isempty(spike_times) %#ok<PROPLC>
                spikes_with_onset = table(  'Size',[0 4], ...
                    'VariableTypes', ["double" "double" "uint32" "double"],...
                    'VariableNames', ...
                    {'spike_times', 'stimulus_presentation', ...
                    'unit_id', 'time_since_stimulus_presentation_onset'});
                return;
            end
            
            stimulus_presentation_id = presentation_ids;
            unit_id = unit_ids;
            
            spike_df = table(spike_times, stimulus_presentation_id, unit_id); %#ok<PROPLC>
            
            % - Filter stimulus_presentations table
            onset_times = self.stimulus_presentations;
            select_stimuli = ismember(onset_times.stimulus_presentation_id, all_presentation_ids);
            onset_times = onset_times(select_stimuli, {'stimulus_presentation_id', 'start_time'});
            
            spikes_with_onset = join(spike_df, onset_times, 'Keys', 'stimulus_presentation_id');
            spikes_with_onset.time_since_stimulus_presentation_onset = spikes_with_onset.spike_times - spikes_with_onset.start_time;
            
            spikes_with_onset = sortrows(spikes_with_onset, 'spike_times');
            spikes_with_onset = removevars(spikes_with_onset, 'start_time');
        end
        
        function summary = getConditionwiseSpikeStatistics(self, stimulus_presentation_ids, unit_ids, use_rates)
            % Produce summary statistics for each distinct stimulus condition
            
            arguments
                self;
                stimulus_presentation_ids {mustBeNumeric} = [];  % identifies stimulus presentations from which spikes will be considered
                unit_ids {mustBeNumeric} = []; % identifies units whose spikes will be considered
                use_rates logical = false; % If True, use firing rates. If False, use spike counts.
            end
            
            if isempty(stimulus_presentation_ids)
                stimulus_presentation_ids = self.stimulus_presentations.stimulus_presentation_id;
            end
            
            select_presentations = ismember(self.stimulus_presentations.stimulus_presentation_id, stimulus_presentation_ids);
            presentations = self.stimulus_presentations(select_presentations, {'stimulus_presentation_id', 'stimulus_condition_id', 'start_time' 'stop_time'});
            
            spikes = self.getPresentationwiseSpikeTimes(stimulus_presentation_ids, unit_ids);
            
            if isempty(unit_ids)
                unit_ids = unique(spikes.unit_id, 'stable');
            end
            
            % Initialize presentation-wise spike counts table 
            [stimulus_presentation_id, unit_id] = ndgrid(stimulus_presentation_ids, unit_ids);
            stimulus_presentation_id = stimulus_presentation_id(:);
            unit_id = unit_id(:);
            spike_count = zeros(size(stimulus_presentation_id));
            spike_counts = table(stimulus_presentation_id, unit_id, spike_count);
            
            % Fill in presentation-wise spike counts table
            if ~isempty(spikes)
                %[found_spike_counts, ~, u_indices] = unique(spikes(:, {'stimulus_presentation_id', 'unit_id'}), 'rows');
                %found_spike_counts.spike_count = accumarray(u_indices, 1);
                
                found_spike_counts = groupsummary(spikes,["stimulus_presentation_id" "unit_id"]);
                
                for row = 1:height(found_spike_counts)
                    % - Fill in spike counts
                    spike_count_row = (spike_counts.stimulus_presentation_id == found_spike_counts.stimulus_presentation_id(row)) & ...
                        (spike_counts.unit_id == found_spike_counts.unit_id(row));
                    spike_counts(spike_count_row, 'spike_count') = found_spike_counts(row, "GroupCount");
                end
            end
                
            % Add stimulus condition & duration variables
            for row = 1:size(spike_counts, 1)
                stimulus_row = presentations.stimulus_presentation_id == spike_counts.stimulus_presentation_id(row);
                spike_counts.stimulus_condition_id(row) = presentations.stimulus_condition_id(stimulus_row);
                spike_counts.duration(row) = presentations.stop_time(stimulus_row) - presentations.start_time(stimulus_row);
            end
            
            
            if use_rates % TODO: update rate case to use groupsummary
                spike_counts.spike_rate = spike_counts.spike_count / spike_counts.duration;
                spike_counts = removevars(spike_counts, 'spike_count');
                extractor = @zlclExtractSummaryRateStatistics;
            else
                spike_counts = removevars(spike_counts, 'duration');
                %extractor = @zlclExtractSummaryCountStatistics;
            end
            
            summary = groupsummary(spike_counts,["stimulus_condition_id" "unit_id"],["nnz" "mean" "std"],"spike_count");
          
            summary.spike_count = round(summary.GroupCount .* summary.mean_spike_count);
            
            summary = movevars(summary,"spike_count",'After',"unit_id");
            summary = movevars(summary,"GroupCount",'After',"spike_count");

            summary = renamevars(summary,"GroupCount","stimulus_presentation_count");
            
        end
        
        function conditions = getConditionsByStimulusName(self, stimulus_name, drop_nulls)
            % For each stimulus parameter, report the unique values taken on by that parameter while a named stimulus was presented.
            
            arguments
                self;
                stimulus_name char; % a stimulus_name (from the available stimulus_names) for which conditions will be retrieved
                drop_nulls logical = true; % drop null-valued presentations
            end
            
            presentation_ids = self.fetch_stimulus_table(stimulus_name).stimulus_presentation_id;
            conditions = self.zprvGetConditionByPresentationID(presentation_ids, drop_nulls);
            conditions.stimulus_name = stimulus_name;
        end
    end
    
    
    %% METHODS - HIDDEN
    
    % Implemented, but needs work
    methods (Hidden)
        
        % TODO: Investigate intended/actual behavior here. Returns successfully, but there appear to be no intervals, as it loo(every stimulus_presentation_id is
        function inter_presentation_intervals = fetch_inter_presentation_intervals_for_stimulus(self, stimulus_names)
            self.zprpCacheStimulusPresentations();
            
            select_stimuli = ismember(self.property_cache.stimulus_presentations_raw.stimulus_name, stimulus_names);
            filtered_presentations = self.property_cache.stimulus_presentations_raw(select_stimuli, :);
            filtered_ids = filtered_presentations.stimulus_presentation_id;
            
            
            select_intervals = ismember(self.inter_presentation_intervals.from_presentation_id, filtered_ids) & ...
                ismember(self.inter_presentation_intervals.to_presentation_id, filtered_ids);
            
            inter_presentation_intervals = self.inter_presentation_intervals(select_intervals, :);
        end
        
    end
    
    %     % currently not fully implemented
    %     methods (Hidden)
    %
    %         function fetch_natural_movie_template(self, number) %#ok<INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %
    %             well_known_files = self.stimulus_templates(self.stimulus_templates.movie_number == number, :); %#ok<UNRCH>
    %
    %             if size(well_known_files, 1) ~= 1
    %                 error('BOT:NotFound', ...
    %                     'Expected exactly one natural movie template with number %d, found %d.', number, size(well_known_files, 1));
    %             end
    %
    %             download_url = self.bot_cache.strABOBaseUrl + well_known_files.download_link;
    %             local_filename = self.bot_cache.CacheFile(download_url, well_known_files.path);
    %         end
    %
    %         function fetch_natural_scene_template(self, number) %#ok<INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %
    %
    %         function valid_time_points = fetch_valid_time_points(self, time_points, invalid_time_intevals) %#ok<STOUT,INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %
    %         function units_table = build_units_table(self, units_table) %#ok<INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %
    %         function output_waveforms = build_nwb1_waveforms(self, mean_waveforms) %#ok<STOUT,INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %
    %         function output_waveforms = build_mean_waveforms(self, mean_waveforms) %#ok<STOUT,INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %     end
    
    % Clearly intended as Hidden
    methods (Hidden)
        
        
        function parameters = zprvGetConditionByPresentationID(self, stimulus_presentation_ids, drop_nulls)
            % For each stimulus parameter, report the unique values taken on by that parameter throughout the course of the  session
            arguments
                self;
                stimulus_presentation_ids {mustBeNumeric} = [];
                drop_nulls logical = true;
            end
            
            % - Filter stimulus_presentations table
            stimulus_presentations = self.stimulus_presentations; %#ok<PROPLC>
            
            if ~isempty(stimulus_presentation_ids)
                select_stimuli = ismember(stimulus_presentations.stimulus_presentation_id, stimulus_presentation_ids); %#ok<PROPLC>
                stimulus_presentations = stimulus_presentations(select_stimuli, :); %#ok<PROPLC>
            end
            
            % - Determine variables to remove, and remove them
            vars_to_remove = intersect(stimulus_presentations.Properties.VariableNames, ['stimulus_name' 'stimulus_presentation_id' self.NON_STIMULUS_PARAMETERS]); %#ok<PROPLC> 
            stimulus_presentations = removevars(stimulus_presentations, vars_to_remove); %#ok<PROPLC>
            stimulus_presentations = zlclRemoveUnusedStimulusPresentationColumns(stimulus_presentations); %#ok<PROPLC>
            
            parameters = struct();
            
            for colname = stimulus_presentations.Properties.VariableNames %#ok<PROPLC>
                uniques = unique(stimulus_presentations.(colname{1})); %#ok<PROPLC>
                
                is_null = arrayfun(@(s)isequal(s, "null"), uniques);
                is_null = is_null | arrayfun(@(s)isequal(s, ""), uniques);
                if isnumeric(uniques)
                    is_null = is_null | isnan(uniques);
                end
                
                non_null = uniques(~is_null);
                
                if ~drop_nulls && any(is_null)
                    non_null = [non_null; nan]; %#ok<AGROW>
                end
                
                parameters.(colname{1}) = non_null;
            end
        end
        
        function presentations = fetch_stimulus_table(self, stimulus_names, include_detailed_parameters, include_unused_parameters)
            % Get a subset of stimulus presentations by name, with irrelevant parameters filtered off
            
            arguments
                self;
                stimulus_names = self.stimulus_names; % Names of stimuli to include in the output.
                include_detailed_parameters logical = false;
                include_unused_parameters logical = false;
            end
            
            
            self.zprpCacheStimulusPresentations();
            
            select_stimuli = ismember(self.property_cache.stimulus_presentations_raw.stimulus_name, stimulus_names);
            presentations = self.property_cache.stimulus_presentations_raw(select_stimuli, :);
            
            if ~include_detailed_parameters
                presentations = self.remove_detailed_stimulus_parameters(presentations);
            end
            
            if ~include_unused_parameters
                presentations = zlclRemoveUnusedStimulusPresentationColumns(presentations);
            end
        end
        
        function invalid_times = filter_invalid_times_by_tags(self, tags)
            arguments
                self;
                tags string;
            end
            
            invalid_times = self.invalid_times;
            
            if isequal(invalid_times, bot.item.internal.enum.OnDemandState.Unavailable)
                invalid_times = [];
            elseif  ~isempty(invalid_times)
                mask = cellfun(@(c)any(ismember(string(c), string(tags))), invalid_times.tags);
                invalid_times = invalid_times(mask, :);
            end
        end
        
        function stimulus_presentations = mask_invalid_stimulus_presentations(self, stimulus_presentations)
            
            arguments
                self;
                stimulus_presentations table;
            end
            
            fail_tags = "stimulus";
            invalid_times_filt = self.filter_invalid_times_by_tags(fail_tags);
            
            is_numeric = table2array(varfun(@isnumeric, stimulus_presentations(1, :)));
            
            % - Replace data on invalidated rows with nan or ""
            if ~isempty(invalid_times_filt)
                invalid_epochs = [invalid_times_filt.start_time, invalid_times_filt.stop_time];
            else
                % not all session have invalid times / epochs
                invalid_epochs = [];
            end
            
            stimulus_epochs_ = [stimulus_presentations.start_time, stimulus_presentations.stop_time];

            is_invalid_epoch = false( size(stimulus_epochs_, 1), 1);

            for i = 1:size(invalid_epochs, 1)
                is_overlapping = zlclHasOverlap(stimulus_epochs_, invalid_epochs(i,:));
                is_invalid_epoch(is_overlapping) = true;
            end

            varNames = stimulus_presentations.Properties.VariableNames;
            replace = ~contains(varNames, {'start_time', 'stop_time', 'stimulus_presentation_id'});

            % Update table rows:
            stimulus_presentations_new = stimulus_presentations;
            stimulus_presentations_new(is_invalid_epoch, is_numeric & replace) = {nan};
            stimulus_presentations_new(is_invalid_epoch, ~is_numeric & replace) = {""}; %#ok<STRSCALR>

            stimulus_presentations_new(is_invalid_epoch, 'stimulus_name') = {"invalid_presentation"}; %#ok<STRSCALR> 
            stimulus_presentations = stimulus_presentations_new;
        end
        
        % CONSIDER FOR DEPRECATION - Currently unused, not sure if this extra filtering has a use case
        function output_spike_times = build_spike_times(self, spike_times_raw)
            % - Filter spike times by unit ID
            retained_units = self.units.id;
            select = ismember(uint64(spike_times_raw.unit_id), uint64(retained_units));
            output_spike_times = spike_times_raw(select, :);
        end
        
        
        
        function [stimulus_presentations, stimulus_conditions] = build_stimulus_presentations(~, stimulus_presentations)
            stimulus_presentations = removevars(stimulus_presentations, {'stimulus_index'});
            
            % - Fill in missing values for numeric variables
            stimulus_presentations_filled = fillmissing(stimulus_presentations, 'constant', inf, 'DataVariables', @isnumeric);
            
            % - Identify unique stimulus conditions
            params_only = zlclRemoveVarsIfPresent(stimulus_presentations_filled, ["start_time", "stop_time", "stimulus_block", "stimulus_presentation_id", "stimulus_block_id", "id", "stimulus_condition_id"]);
            [stimulus_conditions, stimulus_condition_id_unique, stimulus_condition_id] = unique(params_only, 'rows', 'stable');
            stimulus_presentations.stimulus_condition_id = stimulus_condition_id - 1;
            stimulus_conditions.stimulus_condition_id = stimulus_condition_id_unique - 1;
        end
        
        function units_table = fetch_units_table_from_nwb(self)
            % - Build the units table from the session NWB file
            % - Allen SDK ecephys_session.units
            units_table = self.build_units_table(self.nwbLocal.fetch_units());
        end

        function spike_amplitudes = fetch_spike_amplitudes(self)
            n = self.nwbLocal;
            units_table = self.fetch_cached('units_table', @n.fetch_full_units_table);
            spike_amplitudes = units_table(:, {'id', 'spike_amplitudes'});
            spike_amplitudes.Properties.VariableNames(1) = "unit_id";
        end

        function spike_times = fetch_spike_times(self)
            n = self.nwbLocal;
            units_table = self.fetch_cached('units_table', @n.fetch_full_units_table);
            spike_times = units_table(:, {'id', 'spike_times'});
            spike_times.Properties.VariableNames(1) = "unit_id";
        end

        function mean_waveforms = fetch_mean_waveforms(self)
            n = self.nwbLocal;
            units_table = self.fetch_cached('units_table', @n.fetch_full_units_table);
            mean_waveforms = units_table(:, {'id', 'waveform_mean'});
            mean_waveforms.Properties.VariableNames(1) = "unit_id";
        end
        
        function df = filter_owned_df(self, key, ids)
            arguments
                self;
                key;
                ids = [];
            end
            
            df = self.(key);
            
            if isempty(ids)
                return;
            end
            
            %          ids = coerce_scalar(ids);
            
            df = df(ids, :);
            
            if isempty(df)
                warning('BOT:Empty', 'Filtering to an empty set of %s!', key);
            end
        end
        
        function warn_invalid_spike_intervals(self)
            fail_tags = string(self.probes.name);
            fail_tags(end+1) = "all_probes";
            
            if ~isempty(self.filter_invalid_times_by_tags(fail_tags))
                warning('BOT:InvalidIntervals', ['Session includes invalid time intervals that could be accessed with the attribute `invalid_times`.\n', ...
                    'Spikes within these intervals are invalid and may need to be excluded from the analysis.'])
            end
        end
        
        function presentations = remove_detailed_stimulus_parameters(self, presentations)
            matching_vars = ismember(self.DETAILED_STIMULUS_PARAMETERS, presentations.Properties.VariableNames);
            presentations = removevars(presentations, self.DETAILED_STIMULUS_PARAMETERS(matching_vars));
        end
    end
    
    methods (Hidden, Access = protected)
        function displayScalarObject(self)
            % - Turn off warnings
            warning('off', 'BOT:MultipleProbes');

            % - Display object
            displayScalarObject@bot.item.Session(self);

            % - Turn warnings on again
            warning('on', 'BOT:MultipleProbes');
        end

        function s = getFooter(self)
            if self.warn_multiple_probes
                s = 'Warning: Structure boundaries were calculated across channels from multiple probes.';
            else
                s = '';
            end
        end
    end

    methods (Access = protected) % Subclasses may override
        function datasetName = resolveDatasetName(~, ~)
            datasetName = bot.item.internal.enum.Dataset.VisualBehavior;
        end

        function tableRow = findManifestTableRow(obj, itemId)
            % Ensure ID is correct type
            itemId = uint32(round(itemId));
            
            tableRow = bot.listSessions(obj.DATASET, obj.DATASET_TYPE, ...
                "Id", itemId, "IncludeBehaviorOnly", true);
        end
    end
    
    % MARK FOR DELETION - potential use case indeterminate
    %     %% HIDDEN INTERFACE - Static Methods
    %     methods(Static, Hidden)
    %         function from_nwb_path(cls, path, nwb_version, api_kwargs) %#ok<INUSD>
    %             error('BOT:NotImplemented', 'This method is not implemented');
    %         end
    %     end
    
end

%% LOCAL FUNCTIONS - Helpers

function tiled_data = zlclBuildSpikeHistogram(time_domain, spike_times, unit_ids, binarize, dtype)
arguments
    time_domain;
    spike_times;
    unit_ids;
    binarize logical = false;
    dtype char = '';
end

if isempty(dtype)
    if binarize
        dtype = 'logical';
    else
        dtype = 'uint16';
    end
end

% - Preallocate tiled data
slice_size = [size(time_domain, 1) - 1, size(time_domain, 2)];
tiled_data = zeros([slice_size numel(unit_ids)], dtype);

starts = time_domain(1:end-1, :);
ends = time_domain(2:end, :);

for unit_index = 1:numel(unit_ids)
    unit_id = unit_ids(unit_index);
    data = spike_times(spike_times.unit_id == unit_id, :).spike_times{1};
    
    counts = zlclFindSpikeCounts(data, starts(:), ends(:));

% %     start_positions = zlclSearchSorted(data, starts(:));
% %     end_positions = zlclSearchSorted(data, ends(:), true);
% % 
% %     counts = end_positions - start_positions;

    if binarize
        tiled_data(:, :, unit_index) = counts > 0;
    else
        tiled_data(:, :, unit_index) = reshape(counts, slice_size);
    end
end

end

function indices = zlclSearchSorted(sorted_array, values, right_side)
arguments
    sorted_array;
    values;
    right_side = false;
end

    function insert_idx = find_right(v)
        insert_idx = find(sorted_array <= v, 1, 'last') + 1;
        if isempty(insert_idx)
            insert_idx = numel(sorted_array) + 1;
        end
    end

    function insert_idx = find_left(v)
        %insert_idx = find(sorted_array > v, 1, 'first');
        %insert_idx = builtin('ismembc2', false, sorted_array > v) + 1;
        %[found, insert_idx] = builtin('_ismemberhelper', true, sorted_array > v);
        [found, insert_idx] = matlab.internal.math.ismemberhelper(true, sorted_array > v);
        if ~found % isempty(insert_idx)
            insert_idx = numel(sorted_array) + 1;
        end
    end

% - Select left or right side lambda
if right_side
    fhFind = @find_right;
else
    fhFind = @find_left;
end

% - Find insertion locations
indices = arrayfun(fhFind, values);
end


function spikeCounts = zlclFindSpikeCounts(spikeTimes, tBinStart, tBinEnd)
%zlclFindSpikeCounts Find spike counts in a set of time bins/intervals

% Note: This function works with irregular time bins, so e.g histcounts is not
% suitable.

    % Does the same as zlclSearchSorted, but dynamically adjust search
    % regions (i.e no need to search from beginning every time, and also no 
    % need to search from end every time.)

    % The main improvement to performance comes from assuming we only need to 
    % search in a local window

    spikeCounts = zeros(size(tBinStart));
    
    % Sort bins in order to use a moving window
    [sortedTBinStart, sortedStartIdx] = sort(tBinStart);
    
    numSpikeTimes = numel(spikeTimes);

    searchStartIndex = find(spikeTimes > min(tBinStart), 1, 'first');
    
    deltaT = tBinEnd(1)-tBinStart(1);
    minSpikeInterval = min(diff(spikeTimes, 1,1));
    
    windowLengthFindFirst = 10; % Selected from observation. Is updated below if needed. 
    windowLengthFindLast = ceil( deltaT / minSpikeInterval);

    for iBin = 1:numel(tBinStart)
        binStart = sortedTBinStart(iBin);
        binEnd = tBinEnd(sortedStartIdx(iBin));
        
        searchEndIndex = min( [numSpikeTimes, searchStartIndex+windowLengthFindFirst] );
        searchWindow = searchStartIndex:searchEndIndex;
        
        %iStartIdx = find(spikeTimes(searchStartIndex:end) > binStart, 1, 'first') + searchStartIndex - 1;
        [found, iStartIdx] = matlab.internal.math.ismemberhelper(true, spikeTimes(searchWindow) > binStart);

        if ~found
            % This might occur when there is a big jump between two time intervals.
            searchWindow = searchStartIndex:numSpikeTimes; % Expand search window
            [found, iStartIdx] = matlab.internal.math.ismemberhelper(true, spikeTimes(searchWindow) > binStart);
        end

        iStartIdx = iStartIdx + searchStartIndex - 1;

        if ~found 
            iStartIdx = numel(spikeTimes) + 1;
        else
            searchStartIndex = iStartIdx;
        end

        lastSearchIndex = min([iStartIdx+windowLengthFindLast, numel(spikeTimes)]);
        iEndIdx = find(spikeTimes(iStartIdx-1:lastSearchIndex) <= binEnd, 1, 'last') + iStartIdx - 1;
        
%         lastSearchIndex = min([iStartIdx+windowLengthFindLast, numel(spikeTimes)]);
%         [found, foundIdx] = matlab.internal.math.ismemberhelper(true, spikeTimes(iStartIdx-1:lastSearchIndex) <= binEnd);
%         
%         iEndIdx = foundIdx + iStartIdx - 1;

        if isempty(iEndIdx)
            iEndIdx = numel(spikeTimes) + 1;
        end

        spikeCounts(sortedStartIdx(iBin)) = iEndIdx - iStartIdx;

        % Adjust window size
        if spikeCounts(sortedStartIdx(iBin)) > windowLengthFindFirst
            windowLengthFindFirst = spikeCounts(sortedStartIdx(iBin));
        end
    end
end


%zlclBuildTimeWindowDomain
function domain = zlclBuildTimeWindowWomain(bin_edges, offsets, callback)
arguments
    bin_edges;
    offsets;
    callback function_handle = @(x)x;
end

[domain, offsets] = ndgrid(bin_edges(:), offsets(:));
domain = callback(domain + offsets);
end


function stimulus_presentations = zlclRemoveUnusedStimulusPresentationColumns(stimulus_presentations)
is_string_col = varfun(@isstring, stimulus_presentations(1, :), 'OutputFormat', 'uniform');

is_empty_col = varfun(@(c)all(isempty(c)), stimulus_presentations, 'OutputFormat', 'uniform');
is_empty_col(~is_string_col) = is_empty_col(~is_string_col) | varfun(@(c)all(isnan(c)), stimulus_presentations(:, ~is_string_col), 'OutputFormat', 'uniform');
is_empty_col = is_empty_col | varfun(@(c)all(isequal(c, 'null')), stimulus_presentations, 'OutputFormat', 'uniform');

stimulus_presentations = stimulus_presentations(:, ~is_empty_col);
end


function intervals = zlclDiffIntervals(array)

intervals = [];


if iscategorical(array)
    nilFcn = @isundefined;
elseif isnumeric(array)
    nilFcn = @isnan;
else
    assert(false);
end

current = -1;
for nIndex = 1:numel(array)
    item = array(nIndex);
    if znstIsDistinctFrom(item, current, nilFcn)
        intervals(end+1) = nIndex; %#ok<AGROW>
    end
    current = item;
end

intervals(end+1) = numel(array);
intervals = unique(intervals);

    function is_distinct = znstIsDistinctFrom(left, right, nilFcn)
        if nilFcn(left) && nilFcn(right)
            is_distinct = false;
        else
            is_distinct = ~isequal(left, right);
        end
    end

end

% function coerce_scalar(value, message, warn)
% error('BOT:NotImplemented', 'This function is not implemented.');
% end

function t = zlclExtractSummaryCountStatistics(index, group)
% - Extract statistics
stimulus_condition_id = index.stimulus_condition_id;
unit_id = index.unit_id;
spike_count = sum(group.spike_count);
stimulus_presentation_count = size(group, 1);
spike_mean = mean(group.spike_count);
spike_std = std(group.spike_count);
spike_sem = spike_std/sqrt(numel(group.spike_count));

% - Construct a table
t = table(stimulus_condition_id, unit_id, spike_count, ...
    stimulus_presentation_count, spike_mean, spike_std, spike_sem);
end


function t = zlclExtractSummaryRateStatistics(index, group)
% - Extract statistics
stimulus_condition_id = index.stimulus_condition_id;
unit_id = index.unit_id;
stimulus_presentation_count = size(group, 1);
spike_mean = mean(group.spike_rate);
spike_std = std(group.spike_rate);
spike_sem = spike_std/sqrt(numel(group.spike_rate));

% - Construct a table
t = table(stimulus_condition_id, unit_id, ...
    stimulus_presentation_count, spike_mean, spike_std, spike_sem);
end

function is_overlap = zlclHasOverlap(a, b)
%     """Check if the two intervals overlap
%
%     Parameters
%     ----------
%     a : matrix (n, 2)
%         start, stop times
%     b : matrix (n, 2)
%         start, stop times
%     Returns
%     -------
%     bool : logical (n, 1) - True if overlap, otherwise False
    is_overlap = max(a(:,1), b(:,1) ) <= min(a(:,2), b(:,2) );
end

function source_table = zlclRemoveVarsIfPresent(source_table, variables)
vbHasVariable = ismember(variables, source_table.Properties.VariableNames);

if any(vbHasVariable)
    source_table = removevars(source_table, variables(vbHasVariable));
end


end

%% LOCAL FUNCTIONS - Initializers

function propNames = zlclInitIndirectFileProps()
mc = meta.class.fromName(mfilename('class'));
propNames = string({findobj(mc.PropertyList,'GetAccess','public','-and','Dependent',1,'-and','Transient',1).Name});
end

function propNames = zlclInitDirectProps()
mc = meta.class.fromName(mfilename('class'));
props_ = findobj(mc.PropertyList,'GetAccess','public','-and','Dependent',1,'-and','Transient',0);

props = [];
for ii = 1:length(props_)
    if isequal(props_(ii).DefiningClass.Name,mfilename('class'))
        props = [props props_(ii)]; %#ok<AGROW>
    end
end

propNames = string({props.Name});

end

function s = zlclInitLinkedFilePropBindings()

s = struct();

% identify properties associated to stimulus templates group of linked files
s.StimTemplatesGroup = "stimulus_templates";

% remainder of file-linked properties (Dependent, Transient) are associated to session NWB linked file
mc = meta.class.fromName(mfilename('class'));
propNames = string({findobj(mc.PropertyList,'GetAccess','public','-and','Dependent',1,'-and','Transient',1).Name});

s.SessNWB = setdiff(propNames,s.StimTemplatesGroup);

end