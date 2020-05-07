%% CLASS bot.ephyssession - Encapsulate and provide data access to an EPhys session dataset from the Allen Brain Observatory



classdef ephyssession < bot.internal.ephysitem & bot.internal.session_base
   %% Properties
   properties (SetAccess = private)
      tUnits;                          % A Table of all units in this session
      tProbes;                         % A Table of all probes in this session
      tChannels;                       % A Table of all channels in this session
      
      inter_presentation_intervals;    % The elapsed time between each immediately sequential pair of stimulus presentations. This is a dataframe with a two-level multiindex (levels are 'from_presentation_id' and 'to_presentation_id'). It has a single column, 'interval', which reports the elapsed time between the two presentations in seconds on the experiment's master clock
      running_speed;                   % [Tx2] array of running speeds, where each row is [timestamp running_speed]
      mean_waveforms;                  % Maps integer unit ids to xarray.DataArrays containing mean spike waveforms for that unit
      stimulus_conditions;             % Each row is a unique permutation (within this session) of stimulus parameters presented during this experiment. Columns are as stimulus presentations, sans start_time, end_time, stimulus_block, and duration
      optogenetic_stimulation_epochs;  %
      session_start_time;              %
      spike_amplitudes;                %
      invalid_times;                   %
      
      num_units;                    % Number of units (putative neurons) recorded in this session
      num_probes;                   % Number of probes recorded in this session
      num_channels;                 % Number of channels recorded in this session
      
      num_stimulus_presentations;   % Number of stimulus presentations in this session
      stimulus_names;               % Names of stimuli presented in this session
      structure_acronyms;           % EPhys structures recorded across all channels in this session
      structurewise_unit_counts;    % Numbers of units (putative neurons) recorded in each of the EPhys structures recorded in this session
      
      rig_geometry_data;            % Metadata about the geometry of the rig used in this session
      rig_equipment_name;           % Metadata: name of the rig used in this session
      specimen_name;                % Metadata: name of the animal used in this session
      age_in_days;                  % Metadata: age of the animal used in this session, in days
      sex;                          % Metadata: sex of the animal used in this session
      full_genotype;                % Metadata: genotype of the animal used in this session
      session_type;                 % Metadata: string describing the type of session (group of stimuli used)
   end
   
   %% Private properties
   properties (Hidden = true, Access = public, Transient = true)
      sPropertyCache;               % Structure for cached property access methods
      
      spike_times;                  % Maps integer unit ids to arrays of spike times (float) for those units
      metadata;                     % Metadata: structure containing metadata about this experimental session
      rig_metadata;                 % Metadata: structure containing metadata about the rig used in this experimental session
      stimulus_presentations;       % Table whose rows are stimulus presentations and whose columns are presentation characteristics. A stimulus presentation is the smallest unit of distinct stimulus presentation and lasts for (usually) 1 60hz frame. Since not all parameters are relevant to all stimuli, this table contains many 'null' values
      
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
   end
   
   
   %% Constructor
   methods
      function bsObj = ephyssession(nID, oManifest)
         % bot.ephyssession - CONSTRUCTOR Construct an object containing an experimental session from an Allen Brain Observatory dataset
         %
         % Usage: bsObj = bot.ophyssession(nSessionID)
         %        vbsObj = bot.ophyssession(vnSessionIDs)
         %        bsObj = bot.ophyssession(tSessionRow)
         if nargin == 0
            return;
         end
         
         % - Handle a vector of session IDs
         if numel(nID) > 1
            for nIndex = numel(nID):-1:1
               bsObj(nID) = bot.ephyssession(nID(nIndex));
            end
            return;
         end
         
         % - Assign metadata
         bsObj = bsObj.check_and_assign_metadata(nID, oManifest.tEPhysSessions, 'session');
         
         % - Ensure that we were given an EPhys session
         if bsObj.sMetadata.BOT_session_type ~= "EPhys"
            error('BOT:Usage', '`bot.ephyssession` objects may only refer to EPhys experimental sessions.');
         end
         
         % - Assign associated table rows
         bsObj.tProbes = oManifest.tEPhysProbes(oManifest.tEPhysProbes.ephys_session_id == nID, :);
         bsObj.tChannels = oManifest.tEPhysChannels(oManifest.tEPhysChannels.ephys_session_id == nID, :);
         bsObj.tUnits = oManifest.tEPhysUnits(oManifest.tEPhysUnits.ephys_session_id == nID, :);
      end
   end
   
   %% Getters for public properties requiring cached data access
   methods
      
      function inter_presentation_intervals = get.inter_presentation_intervals(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      
      function mean_waveforms = get.mean_waveforms(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %            units_table = self._get_full_units_table()
         %            return units_table['waveform_mean'].to_dict()
         
      end
      
      
      function stimulus_conditions = get.stimulus_conditions(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function spike_times = get.spike_times(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %         units_table = self._get_full_units_table()
         %         return units_table['spike_times'].to_dict()
         
      end
      
      function optogenetic_stimulation_epochs = get.optogenetic_stimulation_epochs(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function session_start_time = get.session_start_time(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function spike_amplitudes = get.spike_amplitudes(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %         units_table = self._get_full_units_table()
         %         return units_table["spike_amplitudes"].to_dict()
         
      end
      
      function invalid_times = get.invalid_times(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
   
   %% Derived public properties
   methods
      function num_units = get.num_units(oSession)
         num_units = size(oSession.tUnits, 1);
      end
      
      function num_probes = get.num_probes(oSession)
         num_probes = size(oSession.tProbes, 1);
      end
      
      function num_channels = get.num_channels(oSession)
         num_channels = size(oSession.tChannels, 1);
      end
      
      function num_stimulus_presentations = get.num_stimulus_presentations(oSession)
         num_stimulus_presentations = size(oSession.stimulus_presentations, 1);
      end
      
      function stimulus_names = get.stimulus_names(oSession)
         stimulus_names = unique(oSession.stimulus_presentations.stimulus_name);
      end
      
      function structure_acronyms = get.structure_acronyms(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function structurewise_unit_counts = get.structurewise_unit_counts(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
   
   %% Metadata public property getters
   methods
      function metadata = get.metadata(oSession)
         strNWBKey = '/general/metadata';
         metadata = bot.nwb.struct_from_attributes(oSession.EnsureCached(), strNWBKey);
      end
      
      function rig_geometry_data = get.rig_geometry_data(oSession)
         strNWBKey = '/processing/eye_tracking';
         if ~bot.nwb.has_path(oSession.EnsureCached(), strNWBKey)
            error('BOT:DataNotPresent', 'This session has no rig geometry data.');
         end
         
         eye_tracking = bot.nwb.table_from_datasets(oSession.EnsureCached(), strNWBKey);
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function rig_equipment_name = get.rig_equipment_name(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function specimen_name = get.specimen_name(oSession)
         specimen_name = oSession.metadata.specimen_name;
      end
      
      function age_in_days = get.age_in_days(oSession)
         age_in_days = oSession.metadata.age_in_days;
      end
      
      function sex = get.sex(oSession)
         sex = oSession.sMetadata.sex;
      end
      
      function full_genotype = get.full_genotype(oSession)
         full_genotype = oSession.metadata.full_genotype;
      end
      
      function session_type = get.session_type(oSession)
         session_type = oSession.metadata.stimulus_name;
      end
   end
   
   %% Public methods
   methods
      function csd = get_current_source_density(oSession, probe_id)
         % """ Obtain current source density (CSD) of trial-averaged response to a flash stimuli for this probe.
         % See allensdk.brain_observatory.ecephys.current_source_density for details of CSD calculation.
         %
         % CSD is computed with a 1D method (second spatial derivative) without prior spatial smoothing
         % User should apply spatial smoothing of their choice (e.g., Gaussian filter) to the computed CSD
         %
         %
         % Parameters
         % ----------
         % probe_id : int
         %    identify the probe whose CSD data ought to be loaded
         %
         % Returns
         % -------
         % xr.DataArray :
         %    dimensions are channel (id) and time (seconds, relative to stimulus onset). Values are current source
         % density assessed on that channel at that time (V/m^2)
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function lfp = get_lfp(oSession, probe_id, mask_invalid_intervals)
         % ''' Load an xarray DataArray with LFP data from channels on a single probe
         %
         % Parameters
         % ----------
         % probe_id : int
         %    identify the probe whose LFP data ought to be loaded
         % mask_invalid_intervals : bool
         %    if True (default) will mask data in the invalid intervals with np.nan
         % Returns
         % -------
         % xr.DataArray :
         %    dimensions are channel (id) and time (seconds). Values are sampled LFP data.
         %
         % Notes
         % -----
         % Unlike many other data access methods on this class. This one does not cache the loaded data in memory due to
         % the large size of the LFP data.
         
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %     def get_lfp(self, probe_id: int) -> xr.DataArray:
         %         lfp_file = self._probe_nwbfile(probe_id)
         %         lfp = lfp_file.get_acquisition(f'probe_{probe_id}_lfp')
         %         series = lfp.get_electrical_series(f'probe_{probe_id}_lfp_data')
         %
         %         electrodes = lfp_file.electrodes.to_dataframe()
         %
         %         data = series.data[:]
         %         timestamps = series.timestamps[:]
         %
         %         return xr.DataArray(
         %             name="LFP",
         %             data=data,
         %             dims=['time', 'channel'],
         %             coords=[timestamps, electrodes.index.values]
         %         )
      end
      
      function raw_running_data = get_raw_running_data(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');

         %     def get_raw_running_data(self):
         %         rotation_series = self.nwbfile.get_acquisition("raw_running_wheel_rotation")
         %         signal_voltage_series = self.nwbfile.get_acquisition("running_wheel_signal_voltage")
         %         supply_voltage_series = self.nwbfile.get_acquisition("running_wheel_supply_voltage")
         % 
         %         return pd.DataFrame({
         %             "frame_time": rotation_series.timestamps[:],
         %             "net_rotation": rotation_series.data[:],
         %             "signal_voltage": signal_voltage_series.data[:],
         %             "supply_voltage": supply_voltage_series.data[:]
         %         })
      end
      
      function inter_presentation_intervals = get_inter_presentation_intervals_for_stimulus(oSession, stimulus_names)
         % ''' Get a subset of this session's inter-presentation intervals, filtered by stimulus name.
         %
         % Parameters
         % ----------
         % stimulus_names : array-like of str
         %    The names of stimuli to include in the output.
         %
         % Returns
         % -------
         % pd.DataFrame :
         %    inter-presentation intervals, filtered to the requested stimulus names.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function presentations = get_stimulus_table(oSession, stimulus_names, include_detailed_parameters, include_unused_parameters)
         % '''Get a subset of stimulus presentations by name, with irrelevant parameters filtered off
         %
         % Parameters
         % ----------
         % stimulus_names : array-like of str
         %    The names of stimuli to include in the output.
         %
         % Returns
         % -------
         % pd.DataFrame :
         %    Rows are filtered presentations, columns are the relevant subset of stimulus parameters
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function epochs = get_stimulus_epochs(oSession, duration_thresholds)
         % """ Reports continuous periods of time during which a single kind of stimulus was presented
         %
         % Parameters
         % ---------
         % duration_thresholds : dict, optional
         %    keys are stimulus names, values are floating point durations in seconds. All epochs with
         %        - a given stimulus name
         %        - a duration shorter than the associated threshold
         %    will be removed from the results
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function invalid_times = get_invalid_times(oSession)
         % """ Report invalid time intervals with tags describing the scope of invalid data
         %
         % The tags format: [scope,scope_id,label]
         %
         % scope:
         %    'EcephysSession': data is invalid across session
         %    'EcephysProbe': data is invalid for a single probe
         % label:
         %    'all_probes': gain fluctuations on the Neuropixels probe result in missed spikes and LFP saturation events
         %    'stimulus' : very long frames (>3x the normal frame length) make any stimulus-locked analysis invalid
         %    'probe#': probe # stopped sending data during this interval (spikes and LFP samples will be missing)
         %    'optotagging': missing optotagging data
         %
         % Returns
         % -------
         % pd.DataFrame :
         %    Rows are invalid intervals, columns are 'start_time' (s), 'stop_time' (s), 'tags'
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function pupil_data = get_pupil_data(oSession, suppress_pupil_data)
         % """Return a dataframe with eye tracking data
         %
         % Parameters
         % ----------
         % suppress_pupil_data : bool, optional
         %    Whether or not to suppress eye gaze mapping data in output
         %    dataframe, by default True.
         %
         % Returns
         % -------
         % pd.DataFrame
         %    Contains columns for eye, pupil and cr ellipse fits:
         %        *_center_x
         %        *_center_y
         %        *_height
         %        *_width
         %        *_phi
         %    May also contain raw/filtered columns for gaze mapping if
         %    suppress_pupil_data is set to False:
         %        *_eye_area
         %        *_pupil_area
         %        *_screen_coordinates_x_cm
         %        *_screen_coordinates_y_cm
         %        *_screen_coordinates_spherical_x_deg
         %        *_screen_coorindates_spherical_y_deg
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function spike_counts = presentationwise_spike_counts(oSession, ...
            bin_edges, stimulus_presentation_ids, unit_ids, binarize, ...
            dtype, large_bin_size_threshold, time_domain_callback)
         % ''' Build an array of spike counts surrounding stimulus onset per unit and stimulus frame.
         %
         % Parameters
         % ---------
         % bin_edges : numpy.ndarray
         %    Spikes will be counted into the bins defined by these edges. Values are in seconds, relative
         %    to stimulus onset.
         % stimulus_presentation_ids : array-like
         %    Filter to these stimulus presentations
         % unit_ids : array-like
         %    Filter to these units
         % binarize : bool, optional
         %    If true, all counts greater than 0 will be treated as 1. This results in lower storage overhead,
         %    but is only reasonable if bin sizes are fine (<= 1 millisecond).
         % large_bin_size_threshold : float, optional
         %    If binarize is True and the largest bin width is greater than this value, a warning will be emitted.
         % time_domain_callback : callable, optional
         %    The time domain is a numpy array whose values are trial-aligned bin
         %    edges (each row is aligned to a different trial). This optional function will be
         %    applied to the time domain before counting spikes.
         %
         % Returns
         % -------
         % xarray.DataArray :
         %    Data array whose dimensions are stimulus presentation, unit,
         %    and time bin and whose values are spike counts.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function spike_times = presentationwise_spike_times(oSession, stimulus_presentation_ids, unit_ids)
         %   ''' Produce a table associating spike times with units and stimulus presentations
         %
         %   Parameters
         %   ----------
         %   stimulus_presentation_ids : array-like
         %       Filter to these stimulus presentations
         %   unit_ids : array-like
         %       Filter to these units
         %
         %   Returns
         %   -------
         %   pandas.DataFrame :
         %   Index is
         %       spike_time : float
         %           On the session's master clock.
         %   Columns are
         %       stimulus_presentation_id : int
         %           The stimulus presentation on which this spike occurred.
         %       unit_id : int
         %           The unit that emitted this spike.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function spike_stats = conditionwise_spike_statistics(oSession, stimulus_presentation_ids, unit_ids, use_rates)
         % """ Produce summary statistics for each distinct stimulus condition
         %
         % Parameters
         % ----------
         % stimulus_presentation_ids : array-like
         %    identifies stimulus presentations from which spikes will be considered
         % unit_ids : array-like
         %    identifies units whose spikes will be considered
         % use_rates : bool, optional
         %    If True, use firing rates. If False, use spike counts.
         %
         % Returns
         % -------
         % pd.DataFrame :
         %    Rows are indexed by unit id and stimulus condition id. Values are summary statistics describing spikes
         %    emitted by a specific unit across presentations within a specific condition.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function get_parameter_values_for_stimulus(oSession, stimulus_name, drop_nulls)
         % """ For each stimulus parameter, report the unique values taken on by that
         % parameter while a named stimulus was presented.
         %
         % Parameters
         % ----------
         % stimulus_name : str
         %    filter to presentations of this stimulus
         %
         % Returns
         % -------
         % dict :
         %    maps parameters (column names) to their unique values.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function get_stimulus_parameter_values(oSession, stimulus_presentation_ids, drop_nulls)
         % ''' For each stimulus parameter, report the unique values taken on by that
         % parameter throughout the course of the  session.
         %
         % Parameters
         % ----------
         % stimulus_presentation_ids : array-like, optional
         %    If provided, only parameter values from these stimulus presentations will be considered.
         %
         % Returns
         % -------
         % dict :
         %    maps parameters (column names) to their unique values.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function channel_structure_intervals(oSession, channel_ids)
         % """ find on a list of channels the intervals of channels inserted into particular structures
         %
         % Parameters
         % ----------
         % channel_ids : list
         %    A list of channel ids
         % structure_id_key : str
         %    use this column for numerically identifying structures
         % structure_label_key : str
         %    use this column for human-readable structure identification
         %
         % Returns
         % -------
         % labels : np.ndarray
         %    for each detected interval, the label associated with that interval
         % intervals : np.ndarray
         %    one element longer than labels. Start and end indices for intervals.
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
   
   %% Private low-level data getter methods
   methods
      function strNWBURL = GetNWBURL(bos)
         % GetNWBURL - METHOD Get the cloud URL for the NWB dtaa file corresponding to this session
         %
         % Usage: strNWBURL = GetNWBURL(bos)
         
         % - Get well known files
         vs_well_known_files = bos.sMetadata.well_known_files;
         
         % - Find (first) NWB file
         vsTypes = [vs_well_known_files.well_known_file_type];
         cstrTypeNames = {vsTypes.name};
         nNWBFile = find(cellfun(@(c)strcmp(c, 'EcephysNwb'), cstrTypeNames), 1, 'first');
         
         % - Build URL
         strNWBURL = [bos.bocCache.strABOBaseUrl vs_well_known_files(nNWBFile).download_link];
      end
      
      function tChannels = get_channels(oSession)
         %     def get_channels(self) -> pd.DataFrame:
         %         channels = self.nwbfile.electrodes.to_dataframe()
         %         channels.drop(columns='group', inplace=True)
         %
         %         # Rename columns for clarity
         %         channels.rename(
         %             columns={"manual_structure_id": "ecephys_structure_id",
         %                      "manual_structure_acronym": "ecephys_structure_acronym"},
         %             inplace=True)
         %
         %         # these are stored as string in nwb 2, which is not ideal
         %         # float is also not ideal, but we have nans indicating out-of-brain structures
         %         channels["ecephys_structure_id"] = [
         %             float(chid) if chid != ""
         %             else np.nan
         %             for chid in channels["ecephys_structure_id"]
         %         ]
         %         channels["ecephys_structure_acronym"] = [
         %             ch_acr if ch_acr not in set(["None", ""])
         %             else np.nan
         %             for ch_acr in channels["ecephys_structure_acronym"]
         %         ]
         %
         %         if self.external_channel_columns is not None:
         %             external_channel_columns = self.external_channel_columns()
         %             channels = clobbering_merge(channels, external_channel_columns, left_index=True, right_index=True)
         %
         %         if self.filter_by_validity:
         %             channels = channels[channels["valid_data"]]
         %             channels = channels.drop(columns=["valid_data"])
         %
         %         return channels
      end
      
      function get_full_units_table()
         %         units = self.nwbfile.units.to_dataframe()
         %         units.index = units.index.astype(int)
         %
         %         if self.filter_by_validity or self.filter_out_of_brain_units:
         %             channels = self.get_channels()
         %
         %             if self.filter_out_of_brain_units:
         %                 channels = channels[~(channels["ecephys_structure_id"].isna())]
         %
         %             channel_ids = set(channels.index.values.tolist())
         %             units = units[units["peak_channel_id"].isin(channel_ids)]
         %
         %         if self.filter_by_validity:
         %             units = units[units["quality"] == "good"]
         %             units.drop(columns=["quality"], inplace=True)
         %
         %         units = units[units["amplitude_cutoff"] <= self.amplitude_cutoff_maximum]
         %         units = units[units["presence_ratio"] >= self.presence_ratio_minimum]
         %         units = units[units["isi_violations"] <= self.isi_violations_maximum]
         %
         %         units = remove_invalid_spikes_from_units(units)
         %         return units
         %
      end
   end
   
   %% Private methods
   methods (Access = private)
      function list_stimulus_templates(oSession)
         ecephys_product_id = 714914585;
         fprintf("criteria=model::WellKnownFile,rma::criteria,well_known_file_type[name$eq\'Stimulus\']attachable_type$eq\'Product\'][attachable_id$eq%d]", ecephys_product_id)
      end
      
      function valid_time_points = get_valid_time_points(oSession, time_points, invalid_time_intevals)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function invalid_times = filter_invalid_times_by_tags(oSession, tags)
         % """
         % Parameters
         % ----------
         % invalid_times: pd.DataFrame
         %    of invalid times
         % tags: list
         %    of tags
         %
         % Returns
         % -------
         % pd.DataFrame of invalid times having tags
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function stimulus_presentations = mask_invalid_stimulus_presentations(oSession, stimulus_presentations)
         % """Mask invalid stimulus presentations
         %
         % Find stimulus presentations overlapping with invalid times
         % Mask stimulus names with "invalid_presentation", keep "start_time" and "stop_time", mask remaining data with np.nan
         %
         % Parameters
         % ----------
         % stimulus_presentations : pd.DataFrame
         %    table including all stimulus presentations
         %
         % Returns
         % -------
         % pd.DataFrame :
         %     table with masked invalid presentations
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function output_spike_times = build_spike_times(oSession, spike_times)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function stimulus_presentations = build_stimulus_presentations(oSession, stimulus_presentations, nonapplicable)
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %         stimulus_presentations.index.name = 'stimulus_presentation_id'
         %         stimulus_presentations = stimulus_presentations.drop(columns=['stimulus_index'])
         %
         %         # TODO: putting these here for now; after SWDB 2019, will rerun stimulus table module for all sessions
         %         # and can remove these
         %         stimulus_presentations = naming_utilities.collapse_columns(stimulus_presentations)
         %         stimulus_presentations = naming_utilities.standardize_movie_numbers(stimulus_presentations)
         %         stimulus_presentations = naming_utilities.add_number_to_shuffled_movie(stimulus_presentations)
         %         stimulus_presentations = naming_utilities.map_stimulus_names(
         %             stimulus_presentations, default_stimulus_renames
         %         )
         %         stimulus_presentations = naming_utilities.map_column_names(stimulus_presentations, default_column_renames)
         %
         %         # pandas groupby ops ignore nans, so we need a new "nonapplicable" value that pandas does not recognize as null ...
         %         stimulus_presentations.replace("", nonapplicable, inplace=True)
         %         stimulus_presentations.fillna(nonapplicable, inplace=True)
         %
         %         stimulus_presentations['duration'] = stimulus_presentations['stop_time'] - stimulus_presentations['start_time']
         %
         %         # TODO: database these
         %         stimulus_conditions = {}
         %         presentation_conditions = []
         %         cid_counter = -1
         %
         %         # TODO: Can we have parameters on what columns to omit? If stimulus_block or duration is left in it can affect
         %         #   how conditionwise_spike_statistics counts spikes
         %         params_only = stimulus_presentations.drop(columns=["start_time", "stop_time", "duration", "stimulus_block"])
         %         for row in params_only.itertuples(index=False):
         %
         %             if row in stimulus_conditions:
         %                 cid = stimulus_conditions[row]
         %             else:
         %                 cid_counter += 1
         %                 stimulus_conditions[row] = cid_counter
         %                 cid = cid_counter
         %
         %             presentation_conditions.append(cid)
         %
         %         cond_ids = []
         %         cond_vals = []
         %
         %         for cv, ci in stimulus_conditions.items():
         %             cond_ids.append(ci)
         %             cond_vals.append(cv)
         %
         %         self._stimulus_conditions = pd.DataFrame(cond_vals, index=pd.Index(data=cond_ids, name="stimulus_condition_id"))
         %         stimulus_presentations["stimulus_condition_id"] = presentation_conditions
         %
         %         return stimulus_presentations
      end
      
      function units_table = get_units(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
         %         units = self._get_full_units_table()
         %
         %         to_drop = set(["spike_times", "spike_amplitudes", "waveform_mean"]) & set(units.columns)
         %         units.drop(columns=list(to_drop), inplace=True)
         %
         %         if self.additional_unit_metrics is not None:
         %             additional_metrics = self.additional_unit_metrics()
         %             units = pd.merge(units, additional_metrics, left_index=True, right_index=True)
         %
         %         return units
      end
      
      function units_table = build_units_table(oSession, units_table)
         error('BOT:NotImplemented', 'This method is not implemented');
         
         %     def _build_units_table(self, units_table):
         %         channels = self.channels.copy()
         %         probes = self.probes.copy()
         %
         %         self._unmerged_units = units_table.copy()
         %         table = pd.merge(units_table, channels, left_on='peak_channel_id', right_index=True, suffixes=['_unit', '_channel'])
         %         table = pd.merge(table, probes, left_on='probe_id', right_index=True, suffixes=['_unit', '_probe'])
         %
         %         table.index.name = 'unit_id'
         %         table = table.rename(columns={
         %             'description': 'probe_description',
         %             'local_index_channel': 'channel_local_index',
         %             'PT_ratio': 'waveform_PT_ratio',
         %             'amplitude': 'waveform_amplitude',
         %             'duration': 'waveform_duration',
         %             'halfwidth': 'waveform_halfwidth',
         %             'recovery_slope': 'waveform_recovery_slope',
         %             'repolarization_slope': 'waveform_repolarization_slope',
         %             'spread': 'waveform_spread',
         %             'velocity_above': 'waveform_velocity_above',
         %             'velocity_below': 'waveform_velocity_below',
         %             'sampling_rate': 'probe_sampling_rate',
         %             'lfp_sampling_rate': 'probe_lfp_sampling_rate',
         %             'has_lfp_data': 'probe_has_lfp_data',
         %             'l_ratio': 'L_ratio',
         %             'pref_images_multi_ns': 'pref_image_multi_ns',
         %         })
         %
         %         return table.sort_values(by=['probe_description', 'probe_vertical_position', 'probe_horizontal_position'])
      end
      
      function output_waveforms = build_nwb1_waveforms(oSession, mean_waveforms)
         %         # _build_mean_waveforms() assumes every unit has the same number of waveforms and that a unit-waveform exists
         %         # for all channels. This is not true for NWB 1 files where each unit has ONE waveform on ONE channel
         
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function output_waveforms = build_mean_waveforms(oSession, mean_waveforms)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function intervals = build_inter_presentation_intervals(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function df = filter_owned_df(oSession, key, ids, copy)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function warn_invalid_spike_intervals(oSession)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
   
   %% Static class methods
   methods(Static)
      function presentations = remove_detailed_stimulus_parameters(cls, presentations)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      
      function from_nwb_path(cls, path, nwb_version, api_kwargs)
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
end

%% Helper functions

function build_spike_histogram(time_domain, spike_times, unit_ids, dtype, binarize)
end

function build_time_window_domain(bin_edges, offsets, callback)
end


function removed_unused_stimulus_presentation_columns(stimulus_presentations)
end


function nan_intervals(array, nan_like)
%     """ find interval bounds (bounding consecutive identical values) in an array, which may contain nans
%
%     Parameters
%     -----------
%     array : np.ndarray
%
%     Returns
%     -------
%     np.ndarray :
%         start and end indices of detected intervals (one longer than the number of intervals)
end

function is_distinct_from(left, right)
end

function array_intervals(array)
%     """ find interval bounds (bounding consecutive identical values) in an array
%
%     Parameters
%     -----------
%     array : np.ndarray
%
%     Returns
%     -------
%     np.ndarray :
%         start and end indices of detected intervals (one longer than the number of intervals)
end

function coerce_scalar(value, message, warn)
end

function extract_summary_count_statistics(index, group)
end

function extract_summary_rate_statistics(index, group)
end

function overlap(a, b)
%     """Check if the two intervals overlap
%
%     Parameters
%     ----------
%     a : tuple
%         start, stop times
%     b : tuple
%         start, stop times
%     Returns
%     -------
%     bool : True if overlap, otherwise False
end


