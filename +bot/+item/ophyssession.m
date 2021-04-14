%% bot.item.ophyssession - CLASS Represent an experimental container from the Allen Brain Observatory
%
% This is the main interface to access data from an Allen Brain Observatory
% experimental session. Use the `bot.cache` or `bot.sessionfilter` classes to
% identify an experimental session of interest. Then use `bot.session` to access
% data associated with that session id.
%
% Construction:
% >> bos = bot.session(id);
% >> bos = bot.internal.opyssession(id);
%
% Get session metadata:
% >> bos.nwb_metadata
% ans =
%                         age: '73 days'
%                         sex: 'female'
%               imaging_depth: '375 microns'
%          targeted_structure: 'VISl'
%         ophys_experiment_id: 511458874
%     experiment_container_id: 511511089
%        ...
%
% Find cells analysed in this session:
% >> vnAllCellIDs = bos.cell_specimen_ids;
%
% Maximum intensity projection:
% >> imagesc(bos.max_projection);
%
% Obtain fluorescence traces:
% >> [vtTimestamps, mfTraces] = bos.fetch_fluorescence_traces();
% >> [vtTimestamps, mfTraces] = bos.fetch_dff_traces();
% >> [vtTimestamps, mfTraces] = bos.fetch_demixed_traces();
% >> [vtTimestamps, mfTraces] = bos.fetch_corrected_fluorescence_traces();
% >> [vtTimestamps, mfTraces] = bos.fetch_neuropil_traces();
%
% Get ROIs:
% >> sROIStructure = bos.roi_mask;
% >> tbROIMask = bos.fetch_roi_mask_array();
%
% Obtain behavioural data:
% >> [vtTimestamps, vfPupilLocation] = bos.fetch_pupil_location();
% >> [vtTimestamps, vfPupilAreas] = bos.fetch_pupil_size();
% >> [vtTimestamps, vfRunningSpeed] = fetch_running_speed();
%
% Obtain stimulus information:
% >> bos.stimulus_epoch_table
% ans =
%          stimulus          start_frame    end_frame
%     ___________________    ___________    _________
%     'static_gratings'        745           15191
%     'natural_scenes'       16095           30542
%        ...
%
% >> bos.fetch_stimulus(vnFrameNumbers)
% ans =
%     frame    start_frame    end_frame    repeat        stimulus         ...
%     _____    ___________    _________    ______    _________________    ...
%     0        797            804          NaN       'static_gratings'    ...
%        ...
%
% See method documentation for further information.
%
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits


classdef ophyssession < bot.item.abstract.Session
   
   %% PROPERTIES - USER 
   
   % Direct Item Values
   properties (SetAccess = private)
      session_type;                 % Type of experimental session (i.e. set of stimuli)
   end
   
   % Linked File Values 
   properties (Dependent, Transient)
      nwb_metadata;                 % Metadata extracted from NWB data file
      cell_specimen_ids;            % Vector of cell specimen IDs recorded in this session
      fluorescence_timestamps;      % Vector of fluorescence timestamps corresponding to imaging frames
      fluorescence_traces;          % TxN matrix of fluorescence samples, with each row `t` contianing the data for the timestamp in the corresponding entry of `.fluorescence_timestamps`. Each column `n` contains the fluorescence data for a single cell specimen.
      fluorescence_traces_demixed;  % TxN matrix of fluorescence samples, with each row `t` contianing the data for the timestamp in the corresponding entry of `.fluorescence_timestamps`. Each column `n` contains the demixed fluorescence data for a single cell specimen.
      neuropil_r;                   % vector of neuropil correction factors for each analysed cell
      neuropil_traces;              % TxN matrix of neuropil fluorescence samples, with each row `t` contianing the data for the timestamp in the corresponding entry of `.fluorescence_timestamps`. Each column `n` contains the neuropil response for a single cell specimen.
      fluorescence_traces_dff;      % TxN matrix of fluorescence samples, with each row `t` contianing the data for the timestamp in the corresponding entry of `.fluorescence_timestamps`. Each column `n` contains the delta F/F0 fluorescence data for a single cell specimen.
      spontaneous_activity_stimulus_table;   % Stimulus table describing spontaneous activity epochs
      max_projection;               % Image contianing the maximum-intensity projection of the fluorescence stack obtained in this session
      stimulus_epoch_table;         % table containing information about all stimulus epochs in this experiment session
      stimulus_list;                % Cell array of strings, indicating which individual stimulus sets were presented in this session
      pupil_location;               % Tx2 matrix, where each row contains the tracked location of the mouse pupil. Spherical coordinates [`altitude` `azimuth`] are returned in degrees for each row. (0,0) is the center of the monitor
      pupil_size;                   % Tx1 vector, each element containing the instantaneous estimated pupil area in pixels
      roi_ids;                      % Vector of all ROI IDs analysed in this experiment session
      roi_mask;                     % Structure as returned from `bwconncomp`, defining a set of ROIs.[XxYxC] boolean tensor. Each C slice corresponds to a single imaged ROI, and indicates which pixels in the stack contain that ROI
      roi_mask_array;               % [XxYxC] boolean tensor. Each C slice corresponds to a single imaged ROI, and indicates which pixels in the stack contain that ROI
      running_speed;                % Timetable containing instantaneous running speeds for timestamps aligned to fluorescence frames
      motion_correction;            % Table containing x/y motion correction information applied in this experimental session
      
      % Derived Properties
      corrected_fluorescence_traces;% TxN matrix of fluorescence samples, with each row `t` contianing the data for the timestamp in the corresponding entry of `.fluorescence_timestamps`. Each column `n` contains the corrected fluorescence data for a single cell specimen.
   end
   
   
   %% PROPERTIES - HIDDEN 
   
   
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.Session)
   properties (Constant, Hidden)
       NWB_WELL_KNOWN_FILE_PREFIX = "NWBOphys";
   end
   
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)
   properties (Access = protected)
       CORE_PROPERTIES_EXTENDED = "session_type";
       LINKED_ITEM_PROPERTIES = [];
   end
   
   % SUPERCLASS IMPLEMENTATION (bot.item.abstract.LinkedFilesItem)
   properties (SetAccess = protected, Hidden)
       LINKED_FILE_PROP_BINDINGS = zlclInitLinkedFilePropBindings;
   end   
   
   properties (Dependent, Access=protected)
       nwbLocal; 
   end

   
   %% PROPERTIES - HIDDEN 

    
   properties (Hidden = true, SetAccess = private, Transient = true)
      strSupportedPipelineVersion = '2.0';               % Pipeline version supported by this class
      strPipelineDataset = 'brain_observatory_pipeline'; % Key in NWB file containing the analysed data
      
      FILE_METADATA_MAPPING = struct(...                 % Location of session metadata in NWB file
         'age',                     '/general/subject/age', ...
         'sex',                     '/general/subject/sex', ...
         'imaging_depth',           '/general/optophysiology/imaging_plane_1/imaging depth', ...
         'targeted_structure',      '/general/optophysiology/imaging_plane_1/location', ...
         'ophys_experiment_id',     '/general/session_id', ...
         'experiment_container_id', '/general/experiment_container_id', ...
         'device_string',           '/general/devices/2-photon microscope', ...
         'excitation_lambda',       '/general/optophysiology/imaging_plane_1/excitation_lambda', ...
         'indicator',               '/general/optophysiology/imaging_plane_1/indicator', ...
         'fov',                     '/general/fov', ...
         'genotype',                '/general/subject/genotype', ...
         'session_start_time',      '/session_start_time', ...
         'session_type',            '/general/session_type', ...
         'specimen_name',           '/general/specimen_name', ...
         'generated_by',            '/general/generated_by');
      
      STIMULUS_TABLE_TYPES = struct(...                  % Stimulus information
         'abstract_feature_series',       {{'drifting_gratings', 'static_gratings'}}, ...
         'indexed_time_series',           {{'natural_scenes', 'locally_sparse_noise', ...
         'locally_sparse_noise_4deg', 'locally_sparse_noise_8deg'}}, ...
         'repeated_indexed_time_series',  {{'natural_movie_one', 'natural_movie_two', 'natural_movie_three'}});
      
      smCachedStimulusTable = bot.internal.SimpleMap();  % Internally cached master stimulus table, for searching stimuli
   end
   
   %% PROPERTY ACCESS METHODS
   methods       
       
       function cell_specimen_ids = get.cell_specimen_ids(bos)
           cell_specimen_ids = bos.fetch_cached('cell_specimen_ids',@bos.fetch_cell_specimen_ids);
       end       
       
       function traces = get.corrected_fluorescence_traces(bos)
           traces = bos.fetch_cached('corrected_fluorescence_traces',@bos.fetch_corrected_fluorescence_traces);
       end
       
       function timestamps = get.fluorescence_timestamps(bos)
           timestamps = bos.fetch_cached('fluorescence_timestamps',@bos.fetch_fluorescence_timestamps);
       end
       
       function traces = get.fluorescence_traces(bos)
           traces = bos.fetch_cached('fluorescence_traces',@bos.fetch_fluorescence_traces);
       end
       
       function traces = get.fluorescence_traces_demixed(bos)
           traces = bos.fetch_cached('fluorescence_traces_demixed',@bos.fetch_fluorescence_traces_demixed);
       end
       
       function traces = get.fluorescence_traces_dff(bos)
           traces = bos.fetch_cached('fluorescence_traces_dff',@bos.fetch_fluorescence_traces_dff);
       end
       
       function val = get.max_projection(bos)
           val = bos.fetch_cached('max_projection',bos.fetch_max_projection);
       end
       
       function motion_correction = get.motion_correction(bos)
           % get.motion_correction - GETTER Return the motion correction information for this experimental session
           %
           % Usage: motion_correction = bos.motion_correction
           %
           % `motion_correction` will be a table containing x/y motion correction
           % information applied in this experimental session.
           
           nwb_file = bos.nwbLocal;
           
           % - Try to locate the motion correction data
           nwb_key = h5path('processing', bos.strPipelineDataset, ...
               'MotionCorrection', '2p_image_series');
           
           try
               h5info(nwb_file, h5path(nwb_key, 'xy_translation'));
               nwb_key = h5path(nwb_key, 'xy_translation');
           catch
               try
                   h5info(nwb_file, h5path(nwb_key, 'xy_translations'));
                   nwb_key = h5path(nwb_key, 'xy_translations');
               catch
                   error('BOT:MotionCorrectionNotFound', ...
                       'Could not file motion correction data.');
               end
           end
           
           % - Extract motion correction data from session
           motion_log = h5read(nwb_file, h5path(nwb_key, 'data'));
           motion_time = h5read(nwb_file, h5path(nwb_key, 'timestamps'));
           motion_names = h5read(nwb_file, h5path(nwb_key, 'feature_description'));
           
           % - Create a motion correction table
           motion_correction = array2table(motion_log', 'VariableNames', motion_names);
           motion_correction.timestamp = motion_time;
       end
       
       
       function neuropil_r = get.neuropil_r(bos)
           neuropil_r = bos.fetch_cached('neuropil_r',@bos.fetch_neuropil_r);
       end
       
       function traces = get.neuropil_traces(bos)
           traces = bos.fetch_cached('neuropil_traces',@bos.fetch_neuropil_traces);
       end
      
       
       function nwb_metadata = get.nwb_metadata(bos)
           nwb_metadata = bos.fetch_cached('nwb_metadata',@bos.fetch_nwb_metadata);
       end
       
       function loc = get.nwbLocal(self)
           loc = self.linkedFiles{"SessNWB","LocalFile"};
       end
       
       function tt = get.pupil_location(bos)
           tt = bos.fetch_cached('pupil_location', @bos.fetch_pupil_location);
       end
       
       function tt = get.pupil_size(bos)
           tt = bos.fetch_cached('pupil_size',@bos.fetch_pupil_size);
       end
       
       function roi_ids = get.roi_ids(bos)
           roi_ids = bos.fetch_cached('roi_ids',bos.fetch_roi_ids);
       end
       
       function roi_masks = get.roi_mask(bos)
           roi_masks = bos.fetch_cached('roi_mask',@bos.fetch_roi_mask);
       end
       
       function roi_masks = get.roi_mask_array(bos)
           roi_masks = bos.fetch_cached('roi_mask_array',@bos.fetch_roi_mask_array);
       end
       
       function tt = get.running_speed(bos)
           tt = bos.fetch_cached('running_speed',@bos.fetch_running_speed);
       end
       
       function session_type = get.session_type(bos)
           % get.session_type - GETTER Return the name for the stimulus set used in this session
           %
           % Usage: strSessionType = bos.session_type
           session_type = bos.info.stimulus_name;
       end
       
       function tbl = get.spontaneous_activity_stimulus_table(bos)
           tbl = bos.fetch_cached('spontaneous_activity_stimulus_table',@bos.fetch_spontaneous_activity_stimulus_table);
       end        
      
       
       % TODO: Consider utility of making a public method here, exposing the thresholds as arguments (if so, then can keep a stimulus_epoch_table_default property using the default args)
       function stimulus_epochs = get.stimulus_epoch_table(bos)
           % get.stimulus_epoch_table - GETTER Return the stimulus epoch table for this experimental session
           %
           % Usage: stimulus_epochs = bos.stimulus_epoch_table
           %
           % `stimulus_epochs` will be a table containing information about all
           % stimulus epochs in this session.
           
           % - Hard-coded thresholds from Allen SDK for fetch_epoch_mask_list. These
           % set a maximum limit on the delta aqusistion frames to count as
           % different trials (rows in the stim table).  This helps account for
           % dropped frames, so that they dont cause the cutting of an entire
           % experiment into too many stimulus epochs. If these thresholds are too
           % low, the assert statment in fetch_epoch_mask_list will halt execution.
           % In that case, make a bug report!.
           thresholds = struct('three_session_A', 32+7,...
               'three_session_B', 15, ...
               'three_session_C', 7, ...
               'three_session_C2', 7);
           
           % - Get needed session properties
           stimuli = bos.stimulus_list();
           sessionType = string(bos.session_type);
           
           % - Loop over stimuli to get stimulus tables
           stimulus_epochs = table();
           for stim_index = numel(stimuli):-1:1
               % - Get the stimulus table for this stimulus
               this_stimulus = bos.fetch_stimulus_table(stimuli{stim_index});
               
               % - Set "frame" column for spontaneous stimulus
               if isequal(stimuli{stim_index}, 'spontaneous')
                   this_stimulus.frame = nan(size(this_stimulus, 1), 1);
               end
               
               % - Get epochs for this stimulus
               these_epochs = fetch_epoch_mask_list(this_stimulus, thresholds.(sessionType));
               these_epochs_table = array2table(int32(vertcat(these_epochs{:})), 'VariableNames', {'start_frame', 'end_frame'});
               these_epochs_table.stimulus = repmat(stimuli(stim_index), numel(these_epochs), 1);
               
               % - Append to stimulus epochs table
               stimulus_epochs = vertcat(stimulus_epochs, these_epochs_table); %#ok<AGROW>
           end
           
           % - Sort by initial frame
           stimulus_epochs = sortrows(stimulus_epochs, 'start_frame');
           
           % - Rearrange columns to put 'stimulus' first
           stimulus_epochs = [stimulus_epochs(:, 3) stimulus_epochs(:, 1:2)];
       end
       
       function stimuli = get.stimulus_list(bos)
           % get.stimulus_list - GETTER Return the list of stimuli used in this experimental session
           %
           % Usage: stimuli = bos.stimulus_list
           %
           % `stimuli` will be a cell array of strings, indicating which
           % individual stimulus sets were presented in this session.
           
           % - Get local NWB file
           nwb_file = bos.nwbLocal;
           
           % - Get list of stimuli from NWB file
           strKey = h5path('stimulus', 'presentation');
           sKeys = h5info(nwb_file, strKey);
           [~, stimuli]= cellfun(@fileparts, {sKeys.Groups.Name}, 'UniformOutput', false);
           
           % - Remove trailing "_stimulus"
           stimuli = cellfun(@(s)strrep(s, '_stimulus', ''), stimuli, 'UniformOutput', false);
       end

   end
   
   %% PROPERTY ACCESS CACHING METHODS
   % TODO: reconsider fetch prefix for these local caching methods 

   methods (Access = protected)
   
       function cell_specimen_ids = fetch_cell_specimen_ids(bos)
          cell_specimen_ids = h5read(bos.nwbLocal, ...
              h5path('processing', bos.strPipelineDataset, ...
              'ImageSegmentation', 'cell_specimen_ids'));
       end
      
       % TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      % TODO: Move to derived linked file property group
      function traces = fetch_corrected_fluorescence_traces(bos, cell_specimen_ids)
          
         % fetch_corrected_fluorescence_traces - METHOD Return corrected fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [timestamps, traces] = fetch_corrected_fluorescence_traces(bos <, cell_specimen_ids>)
         %
         % `timestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `traces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `timestamps`. Each column `n` contains the corrected fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.
         
         
         % - Pass an empty matrix to return all cell specimen IDs
         if ~exist('cell_specimen_ids', 'var') || isempty(cell_specimen_ids)
            cell_specimen_ids = [];
         end
         
         % - Starting in pipeline version 2.0, neuropil correction follows trace demixing
         if str2double(bos.nwb_metadata.pipeline_version) >= 2.0
            traces = bos.fetch_demixed_traces(cell_specimen_ids);
         else
            traces = bos.fetch_fluorescence_traces(cell_specimen_ids);
         end
         
         % - Read neuropil correction data
         neuropil_r = bos.fetch_neuropil_r(cell_specimen_ids);
         neuropil_traces = bos.fetch_neuropil_traces(cell_specimen_ids);
         
         % - Correct fluorescence traces using neuropil demixing model
         traces = traces - bsxfun(@times, neuropil_traces, reshape(neuropil_r, 1, []));
      end
       
         function timestamps = fetch_fluorescence_timestamps(bos)
         % get.fluorescence_timestamps - GETTER Return timestamps for the fluorescence traces, in seconds
         %
         % Usage: timestamps = bos.fluorescence_timestamps
         %
         % `timestamps` will be a vector of time points corresponding to
         % fluorescence samples, in seconds.
         
         
         % - Read imaging timestamps from NWB file
         timestamps = h5read(bos.nwbLocal, ...
            h5path('processing', bos.strPipelineDataset, ...
            'Fluorescence', 'imaging_plane_1', 'timestamps'));
         
         % - Convert to 'duration'
         timestamps = seconds(timestamps);
         end
      
        %TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function traces = fetch_fluorescence_traces(bos, cell_specimen_ids)
         % fetch_fluorescence_traces - METHOD Return raw fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [timestamps, traces] = fetch_fluorescence_traces(bos <, cell_specimen_ids>)
         %
         % `timestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `traces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `timestamps`. Each column `n` contains the demixed fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`cell_specimen_ids` permits you specify which cell specimens
         % should be returned.
         
                  
         % SLATED FOR REMOVAL - REMOVED TIMESTAMPS OUTPUT ARG SINCE IT CAN BE ACCESSED VIA SEPARATE PROPERTY
         %          % - Get the fluorescence timestamps
         %          timestamps = bos.fluorescence_timestamps;
         
         % - Find cell specimen IDs, if provided
         if ~exist('cell_specimen_ids', 'var') || isempty(cell_specimen_ids)
            cell_specimen_indices = 1:numel(bos.cell_specimen_ids);
         else
            cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         end
         
         % - Read requested fluorescence traces
         traces = h5read(bos.nwbLocal, ...
            h5path('processing', bos.strPipelineDataset, ...
            'Fluorescence', 'imaging_plane_1', 'data'));
         
         % - Subselect traces
         traces = traces(:, cell_specimen_indices);
      end
      
      %TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function traces = fetch_fluorescence_traces_demixed(bos, cell_specimen_ids)
         % fetch_demixed_traces - METHOD Return neuropil demixed fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [timestamps, traces] = fetch_demixed_traces(bos <, cell_specimen_ids>)
         %
         % `timestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `traces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `timestamps`. Each column `n` contains the demixed fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`cell_specimen_ids` permits you specify which cell specimens
         % should be returned.
         
         % SLATED FOR REMOVAL - REMOVED TIMESTAMPS OUTPUT ARG SINCE IT CAN BE ACCESSED VIA SEPARATE PROPERTY
         %          % - Get the fluorescence timestamps
         %          timestamps = bos.fluorescence_timestamps;
         
         % - Find cell specimen IDs, if provided
         if ~exist('cell_specimen_ids', 'var') || isempty(cell_specimen_ids)
            cell_specimen_indices = 1:numel(bos.cell_specimen_ids);
         else
            cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         end
         
         % - Read requested fluorescence traces
         traces = h5read(bos.nwbLocal, ...
            h5path('processing', bos.strPipelineDataset, ...
            'Fluorescence', 'imaging_plane_1_demixed_signal', 'data'));
         
         % - Subselect traces
         traces = traces(:, cell_specimen_indices);
      end
          
      % TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function traces = fetch_fluorescence_traces_dff(bos, cell_specimen_ids)
         % fetch_dff_traces - METHOD Return dF/F traces for the provided cell specimen IDs
         %
         % Usage: [timestamps, dff_traces] = fetch_dff_traces(bos <, cell_specimen_ids>)
         %
         % `timestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `dff_traces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `timestamps`. Each column `n` contains the delta F/F0 fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`cell_specimen_ids` permits you specify which cell specimens
         % should be returned.
         
         % - Find cell specimen IDs, if provided
         if ~exist('cell_specimen_ids', 'var') || isempty(cell_specimen_ids)
            cell_specimen_indices = 1:numel(bos.cell_specimen_ids);
         else
            cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         end
         
         % TODO: Consider if readout of per-property timestamp is useful for error-checking
         % For now skip this step as it's not done with other fluorescence trace props and it's never found to differ from .fluorescence_timestamps
         %          % Read timesamps
         %           timestamps = h5read(bos.nwbLocal, ...
         %               h5path('processing', bos.strPipelineDataset, ...
         %               'DfOverF', 'imaging_plane_1', 'timestamps'));
         %           timestamps = seconds(strc.timestamps);
         
         % - Read response traces            
         traces = h5read(bos.nwbLocal, ...
            h5path('processing', bos.strPipelineDataset, ...
            'DfOverF', 'imaging_plane_1', 'data'));
         
         % - Subsample response traces to requested cell specimens
         traces = traces(:, cell_specimen_indices);         
         
      end     
      
      function max_projection = fetch_max_projection(bos)
          % get.max_projection - GETTER Return the maximum-intensity projection image for this experimental session
          %
          % Usage: max_projection = bos.max_projection
          %
          % `max_projection` will be an image contianing the
          % maximum-intensity projection of the fluorescence stack obtained
          % in this session.
          
          nwb_file = bos.nwbLocal;
          
          % - Extract the maximum projection from the session
          nwb_key = h5path('processing', bos.strPipelineDataset, ...
              'ImageSegmentation', 'imaging_plane_1', 'reference_images', ...
              'maximum_intensity_projection_image', 'data');
          max_projection = h5read(nwb_file, nwb_key);
      end
      
      function motion_correction = fetch_motion_correction(bos)
          %TODO
      end
          
      
      %TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function neuropil_r = fetch_neuropil_r(bos, cell_specimen_ids)
         % fetch_neuropil_r - METHOD Return the neuropil correction variance explained for the provided cell specimen IDs
         %
         % Usage: cell_specimen_ids = fetch_neuropil_r(bos <, cell_specimen_ids>)
         %
         % `neuropil_r` will be a vector of neuropil correction
         % factors for each analysed cell. The optional argument
         % `cell_specimen_ids` can be used to determine for which cells
         % data should be returned. By default, data for all cells is
         % returned.
         
                  
         % - Find cell specimen IDs, if provided
         if ~exist('cell_specimen_ids', 'var') || isempty(cell_specimen_ids)
            cell_specimen_indices = 1:numel(bos.cell_specimen_ids);
         else
            cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         end
         
         % - Check pipeline version and read neuropil correction R
         if str2double(bos.nwb_metadata.pipeline_version) >= 2.0
            neuropil_r = h5read(bos.nwbLocal, ...
               h5path('processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1_neuropil_response', 'r'));
         else
            neuropil_r = h5read(bos.nwbLocal, ...
               h5path('processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1', 'r'));
         end
         
         % - Subsample R to requested cell specimens
         neuropil_r = neuropil_r(cell_specimen_indices);
      end
     
            function metadata = fetch_nwb_metadata(bos)
         % get.nwb_metadata - GETTER Read metadata from the NWB file
         %
         % Usage: metadata = bos.nwb_metadata
         
         % - Attempt to read each of the metadata fields from the NWB file
         metadata = bos.FILE_METADATA_MAPPING;
         for fieldname = fieldnames(bos.FILE_METADATA_MAPPING)'
            % - Convert to a string (otherwise it would be a cell)
            fieldname = fieldname{1}; %#ok<FXSET>
            
            % - Try to read this metadata entry
            try
               metadata.(fieldname) = h5read(bos.nwbLocal, metadata.(fieldname));
            catch
               metadata.(fieldname) = [];
            end
         end
         
         % - Try to convert CRE line information
         if isfield(metadata, 'genotype') && ~isempty(metadata.genotype)
            metadata.cre_line = strsplit(metadata.genotype, ';');
            metadata.cre_line = metadata.cre_line{1};
         end
         
         % - Try to extract imaging depth in ?m
         if isfield(metadata, 'imaging_depth') && ~isempty(metadata.imaging_depth)
            metadata.imaging_depth_um = strsplit(metadata.imaging_depth);
            metadata.imaging_depth_um = str2double(metadata.imaging_depth_um{1});
         end
         
         % - Try to convert the experiment ID
         if isfield(metadata, 'ophys_experiment_id') && ~isempty(metadata.ophys_experiment_id)
            metadata.ophys_experiment_id = str2double(metadata.ophys_experiment_id);
         end
         
         % - Try to convert the experiment container ID
         if isfield(metadata, 'experiment_container_id') && ~isempty(metadata.experiment_container_id)
            metadata.experiment_container_id = str2double(metadata.experiment_container_id);
         end
         
         % - Convert the start time to a date
         
         %         # convert start time to a date object
         %         session_start_time = meta.get('session_start_time')
         %         if isinstance(session_start_time, basestring):
         %             meta['session_start_time'] = dateutil.parser.parse(session_start_time)
         
         % - Parse the age in days
         if isfield(metadata, 'age') && ~isempty(metadata.age)
            metadata.age_days = sscanf(metadata.age, '%d days');
         end
         
         % - Parse the device string
         if isfield(metadata, 'device_string') && ~isempty(metadata.device_string)
            [~, cMatches] = regexp(metadata.device_string, '(.*?)\.\s(.*?)\sPlease*', 'match', 'tokens');
            metadata.device = cMatches{1}{1};
            metadata.device_name = cMatches{1}{2};
         end
         
         % - Parse the file version
         if isfield(metadata, 'generated_by') && ~isempty(metadata.generated_by)
            metadata.pipeline_version = metadata.generated_by{end};
         else
            metadata.pipeline_version = '0.9';
         end
      end                

      
 function [timestamps, pupil_location] = fetch_pupil_location(bos, as_spherical_coords)
         % fetch_pupil_location - METHOD Return the pupil location trace for this experimental session
         %
         % Usage: [timestamps, pupil_location] = fetch_pupil_location(bos, <as_spherical_coords>)
         %
         % `timestamps` will be a Tx1 vector of times in seconds,
         % corresponding to fluorescence timestamps. `pupil_location` will be a
         % Tx2 matrix, where each row contains the tracked location of the mouse
         % pupil. By default, spherical coordinates [`altitude` `azimuth`] are
         % returned in degrees, otherwise each row is [`x` `y`] in centimeters.
         % (0,0) is the center of the monitor.
         %
         % The optional argument `as_spherical_coords` can be used to select spherical
         % or euclidean coordinates.
         
         % - Fail quickly if eye tracking data is known not to exist
         if bos.info.fail_eye_tracking
            error('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
         end
         
         nwb_file = bos.nwbLocal;
         
         % - Default for spherical coordinates
         if ~exist('bAsSpherical', 'var') || isempty(as_spherical_coords)
            as_spherical_coords = true;
         end
         
         % - Return spherical or euclidean coordinates?
         if as_spherical_coords
            location_key = 'pupil_location_spherical';
         else
            location_key = 'pupil_location';
         end
         
         % - Extract data from NWB file
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'EyeTracking', location_key);
         
         try
            % - Try to read the eye tracking data from the NWB file
            pupil_location = h5read(nwb_file, h5path(nwb_key, 'data'))';
            timestamps = seconds(h5read(nwb_file, h5path(nwb_key, 'timestamps')));
            
            tt = timetable(timestamps,pupil_location);
            
         catch cause
            % - Couldn't find the eye tracking data
            base = MException('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
            base = base.addCause(cause);
            throw(base);
         end
      end
      
      
      function tt = fetch_pupil_size(bos)
         % fetch_pupil_size - METHOD Return the pupil area trace for this experimental session
         %
         % Usage: [timestamps, pupil_areas] = fetch_pupil_size(bos)
         %
         % `timestamps` will be a Tx1 vector of times in seconds,
         % corresponding to fluorescence timestamps. `pupil_areas` will be a
         % Tx1 vector % corresponding to fluorescence timestamps , each element containing the instantaneous estimated pupil
         % area in pixels.
         
         % - Fail quickly if eye tracking data is known not to exist
         if bos.info.fail_eye_tracking
            error('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
         end
         
         nwb_file = bos.nwbLocal;
         
         % - Extract session data from NWB file
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'PupilTracking', 'pupil_size');
         
         try
            % - Try to read the eye tracking data from the NWB file
            pupil_areas = h5read(nwb_file, h5path(nwb_key, 'data'));
            timestamps = seconds(h5read(nwb_file, h5path(nwb_key, 'timestamps'))); % TODO: consider turning this into an error-checking only op; it's observed/expected to correspond to fluorescence_timestamps in initial assessment
            
            tt = timetable(timestamps,pupil_areas);
            
         catch cause
            % - Couldn't find the eye tracking data
            base = MException('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
            base = base.addCause(cause);
            throw(base);
         end
      end
      
      
function roi_ids = fetch_roi_ids(bos)
         % get.roi_ids - GETTER Return the list of ROI IDs for this experimental session
         %
         % Usage: roi_ids = bos.roi_ids
         %
         % `roi_ids` will be a vector containing all ROI IDs analysed in
         % this session.
         
         nwb_file = bos.nwbLocal;
         
         % - Extract list of ROI IDs from NWB file
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'roi_ids');
         roi_ids = cellfun(@str2num, h5read(nwb_file, nwb_key));
end     
      

      % TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function roi_masks = fetch_roi_mask_array(bos, cell_specimen_ids)
         % fetch_roi_mask_array - METHOD Return the ROI mask for the provided cell specimen IDs
         %
         % Usage: roi_masks = fetch_roi_mask_array(bos <, cell_specimen_ids>)
         %
         % `roi_masks` will be a [XxYxC] boolean tensor. Each C slice
         % corresponds to a single imaged ROI, and indicates which pixels in the
         % stack contain that ROI. The optional argument `vnCellSpecimenIDs` can
         % be used to select for which cells data should be returned. By
         % default, a mask is returned for all ROIs.
         
         % - By default, return masks for all cells
         if ~exist('cell_specimen_ids', 'var')
            cell_specimen_ids = bos.cell_specimen_ids;
         end
         
         nwb_file = bos.nwbLocal;
         
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'imaging_plane_1');
         
         % - Get list of ROI names
         roi_list = deblank(h5read(nwb_file, h5path(nwb_key, 'roi_list')));
         
         % - Select only requested cell specimen IDs
         cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         
         % - Loop over ROIs, extract masks
         roi_masks = [];
         for cell_index = cell_specimen_indices'
            % - Get a logical mask for this ROI
            this_mask = logical(h5read(nwb_file, h5path(nwb_key, roi_list{cell_index}, 'img_mask')));
            
            % - Build a logical tensor of ROI masks
            if isempty(roi_masks)
               roi_masks = this_mask;
            else
               roi_masks = cat(3, roi_masks, this_mask);
            end
         end
      end
      
        % TODO: consider adding as public get method for access by cell ID, likely in tandem with Cell item addition
      function roi_masks = fetch_roi_mask(bos, cell_specimen_ids)
         % fetch_roi_mask - METHOD Return connected components structure defining requested ROIs
         %
         % Usage: roi_masks = fetch_roi_mask(bos <, cell_specimen_ids>)
         %
         % `roi_masks` will be a structure as returned from `bwconncomp`, defining a
         % set of ROIs. This can be passed to `labelmatrix`, etc. The optional
         % argument `cell_specimen_ids` can be used to select for which cells
         % data should be returned. By default, a mask is returned for all ROIs.
         
         % - By default, return masks for all cells
         if ~exist('cell_specimen_ids', 'var')
            cell_specimen_ids = bos.cell_specimen_ids;
         end
         
         nwb_file = bos.nwbLocal;
         
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'imaging_plane_1');
         
         % - Get list of ROI names
         roi_list = deblank(h5read(nwb_file, h5path(nwb_key, 'roi_list')));
         
         % - Select only requested cell specimen IDs
         cell_specimen_indices = bos.lookup_cell_specimen_indices(cell_specimen_ids);
         
         % - Initialise a CC structure
         roi_masks = struct('Connectivity', 8, ...
            'ImageSize', {[]}, ...
            'NumObjects', numel(cell_specimen_indices), ...
            'PixelIdxList', {{}}, ...
            'Labels', {{}});
         
         % - Loop over ROIs, extract masks
         for cell_index = numel(cell_specimen_indices):-1:1
            % - Get a logical mask for this ROI
            this_mask = logical(h5read(nwb_file, h5path(nwb_key, roi_list{cell_specimen_indices(cell_index)}, 'img_mask')));
            
            % - Build up a CC structure containing these ROIs
            roi_masks.PixelIdxList{cell_index} = find(this_mask);
            roi_masks.Labels{cell_index} = roi_list{cell_specimen_indices(cell_index)};
         end
         
         % - Fill in CC structure
         roi_masks.ImageSize = size(this_mask);
      end
      
 
      function tt = fetch_running_speed(bos)
         % fetch_running_speed - METHOD Return running speed in cm/s
         %
         % Usage: [timestamps, running_speed] = fetch_running_speed(bos)
         %
         % `timestamps` will be a Tx1 vector containing times in seconds,
         % corresponding to fluorescence timestamps. `running_speed` will be a
         % Tx1 vector containing instantaneous running speeds at each
         % corresponding time point, in cm/s.
         
         nwb_file = bos.nwbLocal;
         
         % - Build a base key for the running speed data
         nwb_key = h5path('processing', bos.strPipelineDataset, ...
            'BehavioralTimeSeries', 'running_speed');
         running_speed_ = h5read(bos.nwbLocal, h5path(nwb_key, 'data'));
         timestamps = seconds(h5read(nwb_file, h5path(nwb_key, 'timestamps')));
         
         % - Align with imaging timestamps
         imaging_timestamps = bos.fluorescence_timestamps;
         
         tt = timetable;
         
         [strc.running_speed, strc.running_speed_timestamps] = align_running_speed(running_speed_, timestamps, imaging_timestamps);
      end
      
      function tbl = fetch_spontaneous_activity_stimulus_table(bos)
          % Return information about the epochs of spontaneous activity in this
         % experimental session.
         
         % - Build a key for this stimulus
         strKey = h5path('stimulus', 'presentation', 'spontaneous_stimulus');
         
         % - Read and convert stimulus data from the NWB file
         try
            % - Read data from the NWB file
            
            nwb_file = bos.nwbLocal;
            events = h5read(nwb_file, h5path(strKey, 'data'))';
            frame_dur = h5read(nwb_file, h5path(strKey, 'frame_duration'))';
            
            % - Locate start and stop events
            start_inds = find(events == 1);
            stop_inds = find(events == -1);
            
            % - Check spontaneous activity data
            assert(numel(start_inds) == numel(stop_inds), ...
               'BOT:StimulusError', 'Inconsistent start and time times in spontaneous activity stimulus table');
            
            % - Create a stimulus table to return
            stim_data = int32([frame_dur(start_inds, 1) frame_dur(stop_inds, 1)]);
            
            % - Create a stimulus table to return
            tbl = array2table(stim_data, 'VariableNames', {'start_frame', 'end_frame'});
            
         catch meCause
            meBase = MException('BOT:StimulusError', 'Could not read spontaneous stimulus from session.\nThe stimulus may not exist.');
            meBase = meBase.addCause(meCause);
            throw(meBase);
         end
      end   
           
     
            
   end       
   
   %% PROPERTY ACCESS HELPERS
   methods (Access=private)       
      
      function cell_specimen_indices = lookup_cell_specimen_indices(bos, cell_specimen_ids)
         % lookup_cell_specimen_indices - METHOD Return indices corresponding to provided cell specimen IDs
         %
         % Usage: cell_specimen_indices = lookup_cell_specimen_indices(bos, cell_specimen_ids)
         %
         % `cell_specimen_ids` is an Nx1 vector of valid cell specimen IDs.
         % `cell_specimen_indices` will be an Nx1 vector with each element
         % indicating the 1-based index of the corresponding cell specimen ID in
         % the NWB data tables and fluorescence matrices.
                           
         % - Read all cell specimen IDs
         all_cell_specimen_ids = bos.cell_specimen_ids;
         
         % - Find provided IDs in list
         [vbFound, cell_specimen_indices] = ismember(cell_specimen_ids, all_cell_specimen_ids);
         
         % - Raise an error if specimens not found
         assert(all(vbFound), 'BOT:NotFound', ...
            'Provided cell specimen ID was not found in this session.');
      end
      
      function [stimulus_template, off_screen_mask] = fetch_locally_sparse_noise_stimulus_template(bos, stimulus_name, mask_off_screen)
         % fetch_locally_sparse_noise_stimulus_template - METHOD Return the locally sparse noise stimulus template used for this sessions
         %
         % Usage: [stimulus_template, off_screen_mask] = fetch_locally_sparse_noise_stimulus_template(bos, stimulus_name <, mask_off_screen>)
         %
         % `stimulus_name` must be one of {'locally_sparse_noise',
         % 'locally_sparse_noise_4deg', 'locally_sparse_noise_8deg'}, and
         % one of these stimuli must have been used in this experimental
         % session. `stimulus_template` will be an [XxYxF] stimulus
         % template, containing the set of locally sparse noise frames used
         % in this experimental session. Each F-slice corresponds to one
         % stimulus frame as referenced in the stimulus tables ('frame').
         %
         % `off_screen_mask` will be an [XxY] boolean matrix, indicating
         % which pixels were displayed to the animal after spatial warping
         % of the stimulus.
         %
         % The optional argument `mask_off_screen` can be used to specify
         % whether off-screen pixels should be blanked in
         % `stimulus_template`. By default, off-screen pixels are blanked.
         
         % - Pre-defined dimensions for locally sparse noise stimuli
         sparse_noise_dimensions = struct(...
            'locally_sparse_noise', [16 28], ...
            'locally_sparse_noise_4deg', [16 28], ...
            'locally_sparse_noise_8deg', [8 14]);
         
         % - By default, mask off screen regions
         if ~exist('mask_off_screen', 'var') || isempty(mask_off_screen)
            mask_off_screen = true;
         end
         
         % - Is the provided stimulus one of the known noise stimuli?
         if ~isfield(sparse_noise_dimensions, stimulus_name)
            stimulus_names = fieldnames(sparse_noise_dimensions);
            error('BOT:UnknownStimulus', ...
               '''strStimulus'' must be one of {%s}.', ...
               sprintf('%s, ', stimulus_names{:}));
         end
         
         % - Get a stimulus template
         stimulus_template = bos.fetch_stimulus_template(stimulus_name);
         stim_template_size = size(stimulus_template);
         
         % - Build a mapping from template to display coordinates
         template_size = sparse_noise_dimensions.(stimulus_name);
         template_size = template_size([2 1]);
         template_display_size = [1260 720];
         display_size = [1920 1200];
         
         scale = template_size ./ template_display_size;
         offset = -(display_size - template_display_size) / 2;
         
         [x, y] = ndgrid((1:display_size(1))-1, (1:display_size(2))-1);
         template_display_coords = cat(3, (x + offset(1)) * scale(1) - .5, (y + offset(2)) * scale(2) - .5);
         template_display_coords = round(template_display_coords);
         
         % - Obtain a mask indicating which stimulus elements are off-screen after warping
         [off_screen_mask, ~] = mask_stimulus_template(template_display_coords, template_size);
         if mask_off_screen
            % - Mask the off-screen stimulus elements
            stimulus_template = reshape(stimulus_template, [], stim_template_size(3));
            stimulus_template(~off_screen_mask(:), :) = 64;
            stimulus_template = reshape(stimulus_template, stim_template_size);
         end
      end
      
      
      % TODO: consider if this should be a user property and/or a user method
      function stimulus_table = fetch_stimulus_table(bos, stimulus_name)
         % fetch_stimulus_table - METHOD Return the stimulus table for the provided stimulus
         %
         % Usage: stimulus_table = fetch_stimulus_table(bos, stimulus_name)
         %
         % `stimulus_name` is a string indicating for which stimulus data
         % should be returned. `stimulus_name` must be one of the stimuli
         % returned by bos.stimulus_list().
         %
         % `stimulus_table` will be a table containing information about the
         % chosen stimulus. The individual stimulus frames can be accessed with
         % method bos.fetch_stimulus_template().
                           
         % - Return a stimulus table for one of the stimulus types
         if ismember(stimulus_name, bos.STIMULUS_TABLE_TYPES.abstract_feature_series)
            stimulus_table = fetch_abstract_feature_series_stimulus_table(bos.nwbLocal, [stimulus_name '_stimulus']);
            return;
            
         elseif ismember(stimulus_name, bos.STIMULUS_TABLE_TYPES.indexed_time_series)
            stimulus_table = fetch_indexed_time_series_stimulus_table(bos.nwbLocal, [stimulus_name '_stimulus']);
            return;
            
         elseif ismember(stimulus_name, bos.STIMULUS_TABLE_TYPES.repeated_indexed_time_series)
            stimulus_table = fetch_repeated_indexed_time_series_stimulus_table(bos.nwbLocal, [stimulus_name '_stimulus']);
            return;
            
         elseif isequal(stimulus_name, 'spontaneous')
            stimulus_table = bos.spontaneous_activity_stimulus_table;
            return;
            
         elseif isequal(stimulus_name, 'master')
            % - Return a master stimulus table containing all stimuli
            % - Loop over stimuli, collect stimulus tables
            stimuli = {};
            variable_names = {};
            for strStimulus = bos.stimulus_list()
               % - Get stimulus as a string
               strStimulus = strStimulus{1}; %#ok<FXSET>
               
               % - Get stimulus table for this stimulus, annotate with stimulus name
               stimuli{end+1} = bos.fetch_stimulus_table(strStimulus); %#ok<AGROW>
               stimuli{end}.stimulus = repmat({strStimulus}, size(stimuli{end}, 1), 1);
               
               % - Collect all variable names
               variable_names = union(variable_names, stimuli{end}.Properties.VariableNames);
            end
            
            % - Loop over stimulus tables and merge
            for nStimIndex = numel(stimuli):-1:1
               % - Find missing variables in this stimulus
               cstrMissingVariables = setdiff(variable_names, stimuli{nStimIndex}.Properties.VariableNames);
               
               % - Add missing variables to this stimulus table
               stimuli{nStimIndex} = [stimuli{nStimIndex} array2table(nan(size(stimuli{nStimIndex}, 1), numel(cstrMissingVariables)), 'VariableNames', cstrMissingVariables)];
            end
            
            % - Concatenate all stimuli and sort by start frame
            stimulus_table = vertcat(stimuli{:});
            stimulus_table = sortrows(stimulus_table, 'start_frame');
            
         else
            % - Raise an error
            error('BOT:Argument', 'Could not find a stimulus table named [%s].', stimulus_name);
         end
      end               
      
      % TODO: consider if this should be a user property and/or a user method
      function stimulus_template = fetch_stimulus_template(bos, stimulus_name)
         % fetch_stimulus_template - METHOD Return the stimulus template for the provided stimulus
         %
         % Usage: stimulus_template = fetch_stimulus_template(bos, stimulus_name)
         %
         % `stimulus_name` is a string array, matching one of the stimuli used
         % in this experimental session. `stimulus_template` will be an [XxYxF]
         % tensor, each F-slice corresponds to a single stimulus frame as
         % referenced in the stimulus tables ('frame', see method
         % fetch_stimulus_table()).
         
         nwb_file = bos.nwbLocal;
         
         % - Extract stimulus template from NWB file
         nwb_key = h5path('stimulus', 'templates', ...
            [stimulus_name '_image_stack'], 'data');
         
         try
            stimulus_template = h5read(nwb_file, nwb_key);
            
         catch cause
            base = MException('BOT:StimulusNotFound', ...
               'A template for the stimulus [%s] was not found.', ...
               stimulus_name);
            base = base.addCause(cause);
            throw(base);
         end
      end    
   
   end
   
   %% METHODS - USER
   
   methods 
       function [stimulus_info, is_valid_frame, stimulus_frame] = getStimulusByFrame(bos, frame_indices)
           % fetch_stimulus - METHOD Return stimulus information for selected frame indices
           %
           % Usage: [stimulus_info, is_valid_frame, stimulus_frame] = fetch_stimulus(bos, frame_indices)
           %
           % `frame_indices` is a vector of fluorescence frame indices
           % (1-based). This method finds the stimuli that correspond to
           % these frame indices. `stimulus_info` will be a table with each
           % row corresponding to a valid frame index. `is_valid_frame` is a
           % boolean vector indicating which frames in `frame_indices` are
           % valid stimulus frames. If a frame falls outside a registered
           % stimulus epoch, it is considered not valid.
           %
           % Each row in `stimulus_info` indicates the full stimulus
           % information associated with the corresponding valid frame in
           % `frame_indices`. For stimuli with a corresponding stimulus
           % template (see method fetch_stimulus_template()), the column
           % 'frame' contains an index indicating which stimulus frame was
           % presented at that point in time.
           %
           % Note: The tensor `stimulus_frame` can optionally be used to
           % return the stimulus template frames associated with each valid
           % frame index. This is not recommended, since it can use a large
           % amount of redundant memory storage. Stimulus templates can only
           % be returned for stimuli that use them (i.e. locally sparse
           % noise, natural movies, etc.)
           
           
           % - Obtain and cache the master stimulus table for this session
           %   Also handles to accelerated search functions
           if isempty(bos.smCachedStimulusTable)
               epoch_stimulus_table = bos.stimulus_epoch_table;
               master_stimulus_table = bos.fetch_stimulus_table('master');
               bos.smCachedStimulusTable(1) = epoch_stimulus_table;
               bos.smCachedStimulusTable(2) = int32(epoch_stimulus_table{:, {'start_frame', 'end_frame'}});
               bos.smCachedStimulusTable(3) = master_stimulus_table;
               bos.smCachedStimulusTable(4) = int32(master_stimulus_table{:, {'start_frame', 'end_frame'}});
               [bos.smCachedStimulusTable(5), bos.smCachedStimulusTable(6)] = bot.internal.fetch_mex_handles();
           end
           
           % - Get the matrix of start and end frames
           epoch_start_end_frames = bos.smCachedStimulusTable(2);
           master_stimulus_table = bos.smCachedStimulusTable(3);
           stimulus_start_end_frames = bos.smCachedStimulusTable(4);
           fhBSSL_int32 = bos.smCachedStimulusTable(6);
           
           % - Ensure that `frame_indices` is sorted
           if ~issorted(frame_indices)
               frame_indices = sort(frame_indices);
           end
           
           % - Ensure that the frame index is a column vector
           frame_indices = reshape(frame_indices, [], 1);
           
           % - Identify search frames that are outside registered epochs
           is_valid_frame = frame_indices >= epoch_start_end_frames(1, 1) & frame_indices <= epoch_start_end_frames(end, 2);
           
           % - Were any frames found?
           if ~any(is_valid_frame)
               stimulus_info = master_stimulus_table([], :);
               stimulus_frame = [];
               return;
           end
           
           % - Find matching stimulus epochs
           start_epoch_index = fhBSSL_int32(epoch_start_end_frames(:, 1), int32(frame_indices(is_valid_frame)));
           end_epoch_index = fhBSSL_int32([epoch_start_end_frames(1, 1); epoch_start_end_frames(:, 2)], int32(frame_indices(is_valid_frame)));
           
           % - Valid frames must fall within a registered stimulus epoch
           is_valid_frame(is_valid_frame) = is_valid_frame(is_valid_frame) & (start_epoch_index == end_epoch_index);
           
           % - Were any frames found?
           if ~any(is_valid_frame)
               stimulus_info = master_stimulus_table([], :);
               stimulus_frame = [];
               return;
           end
           
           % - Find matching stimulus frames
           found_frame_index = fhBSSL_int32(stimulus_start_end_frames(:, 1), int32(frame_indices(is_valid_frame)));
           
           % - Extract an excerpt from the master stimulus table corresponding to these frames
           stimulus_info = master_stimulus_table(found_frame_index, :);
           
           % - Try to extract stimulus frames
           if nargout > 2
               % - Is there more than one stimulus template?
               if numel(unique(stimulus_info.stimulus)) > 1
                   warning('BOT:MultipleStimulusTypes', ...
                       'Warning: Cannot extract stimulus templates for multiple stimulus types simultaneously');
                   stimulus_frame = [];
                   
               else
                   % - Get the name of this stimulus
                   stimulus_name = stimulus_info{1, 'stimulus'};
                   stimulus_name = stimulus_name{1};
                   
                   % - Extract the corresponding stimulus template
                   try
                       stimulus_template = bos.fetch_stimulus_template(stimulus_name);
                       stimulus_frame = stimulus_template(:, :, stimulus_info.frame);
                       
                   catch
                       % - Could not find the appropriate template, so return empty
                       stimulus_frame = [];
                   end
               end
           end
       end
   end
   
%% CONSTRUCTOR
   methods
       function bsObj = ophyssession(session_id)
           % bot.item.ophyssession - CONSTRUCTOR Construct an object containing an experimental session from an Allen Brain Observatory dataset
           %
           % Usage: bsObj = bot.item.ophyssession(id)
           %        vbsObj = bot.item.ophyssession(vids)
           %        bsObj = bot.item.ophyssession(tSessionRow)
           
           if nargin == 0
               return;
           end
           
           % Load associated singleton
           manifest = bot.internal.ophysmanifest.instance();
           
           % - Handle a vector of session IDs
           if ~istable(session_id) && numel(session_id) > 1
               for nIndex = numel(session_id):-1:1
                   bsObj(session_id) = bot.item.ophyssession(session_id(nIndex));
               end
               return;
           end
           
           % - Assign metadata
           session = bsObj.check_and_assign_metadata(session_id, manifest.ophys_sessions, 'session');
           
           % SUSPECTED CRUFT: since we've explicitly constructed an ophysmanifest, check seems unneeded. If checked, it would now use the table property.
           %          % - Ensure that we were given an OPhys session
           %          if session.info.type ~= "OPhys"
           %              error('BOT:Usage', '`bot.item.OPhys` objects may only refer to OPhys experimental sessions.');
           %          end
           
           
           % Superclass initialization (bot.item.abstract.LinkedFilesItem)
           session.initSession();
           
           session.LINKED_FILE_AUTO_DOWNLOAD.SessH5 = false;
           h5Idx = find(contains(string({session.info.well_known_files.path}),"h5",'IgnoreCase',true));
           assert(isscalar(h5Idx),"Expected to find exactly one H5 file ");
           session.insertLinkedFileInfo("SessH5",session.info.well_known_files(h5Idx));
           
           session.initLinkedFiles();
           
       end                 
      
   end  
end   

%% LOCAL FUNCTIONS 

function stimulus_table = fetch_abstract_feature_series_stimulus_table(nwb_file, stimulus_name)
% fetch_abstract_feature_series_stimulus_table - FUNCTION Return a stimlus table for an abstract feature series stimulus

% - Build a key for this stimulus
nwb_key = h5path('stimulus', 'presentation', stimulus_name);

% - Read and convert stimulus data from the NWB file
try
   % - Read data from the NWB file
   stim_data = h5read(nwb_file, h5path(nwb_key, 'data'));
   features = deblank(h5read(nwb_file, h5path(nwb_key, 'features')));
   frame_dur = h5read(nwb_file, h5path(nwb_key, 'frame_duration'));
   
   % - Create a stimulus table to return
   stimulus_table = array2table(stim_data', 'VariableNames', features);
   
   % - Add start and finish frame times
   stimulus_table.start_frame = int32(frame_dur(1, :)');
   stimulus_table.end_frame = int32(frame_dur(2, :)');
   
catch cause
   base = MException('BOT:StimulusError', ...
      'Could not read stimulus [%s] from session.\nThe stimulus may not exist.', stimulus_name);
   base = base.addCause(cause);
   throw(base);
end
end

function stimulus_table = fetch_indexed_time_series_stimulus_table(nwb_file, stimulus_name)
% fetch_indexed_time_series_stimulus_table - FUNCTION Return a stimlus table for an indexed time series stimulus

% - Build a key for this stimulus
nwb_key = h5path('stimulus', 'presentation', stimulus_name);

% - Attempt to read data from this key, otherwise correct
try
   h5info(nwb_file, nwb_key);
catch
   nwb_key = h5path('stimulus', 'presentation', [stimulus_name '_stimulus']);
end

% - Read and convert stimulus data from the NWB file
try
   % - Read data from the NWB file
   inds = h5read(nwb_file, h5path(nwb_key, 'data')) + 1;
   frame_dur = h5read(nwb_file, h5path(nwb_key, 'frame_duration'));
   
   % - Create a stimulus table to return
   stimulus_table = array2table(inds, 'VariableNames', {'frame'});
   
   % - Add start and finish frame times
   stimulus_table.start_frame = int32(frame_dur(1, :)');
   stimulus_table.end_frame = int32(frame_dur(2, :)');
   
catch cause
   base = MException('BOT:StimulusError', 'Could not read stimulus [%s] from session.\nThe stimulus may not exist.');
   base = base.addCause(cause);
   throw(base);
end
end

function stimulus_table = fetch_repeated_indexed_time_series_stimulus_table(nwb_file, stimulus_name)
% fetch_repeated_indexed_time_series_stimulus_table - FUNCTION Return a stimulus table for a repeated stimulus

% - Get the full stimulus table
stimulus_table = fetch_indexed_time_series_stimulus_table(nwb_file, stimulus_name);

% - Locate repeats within stimulus order
unique_stimuli = unique(stimulus_table.frame);
repeat_indices = arrayfun(@(nStim)find(stimulus_table.frame == nStim), unique_stimuli, 'UniformOutput', false);

% - Switch off warnings for extending the table
w = warning('off', 'MATLAB:table:RowsAddedNewVars');

% - Loop over stimulus IDs, assign repeat numbers (zero-based to match Python SDK)
all_repeat_indices = nan(size(stimulus_table, 1), 1);
for nStimulus = 1:numel(unique_stimuli)
   all_repeat_indices(repeat_indices{nStimulus}) = (1:numel(repeat_indices{nStimulus}))' - 1;
end

% - Assign repeat column to table
stimulus_table.repeat = all_repeat_indices;

% - Restore warnings
warning(w);
end

function epoch_mask_list = fetch_epoch_mask_list(st, threshold, max_cuts)
% fetch_epoch_mask_list - FUNCTION Cut a stimulus table into multiple epochs
%
% Usage: epoch_mask_list = fetch_epoch_mask_list(st, threshold, max_cuts)

% - Check that a threshold was supplied
assert(~isempty(threshold), 'BOT:StimulusError', ...
   'Threshold not set for this type of session.');

% - Assign a default max_cuts
if ~exist('max_cuts', 'var') || isempty(max_cuts)
   max_cuts = 3;
end

% - Determine frame deltas and cut indices
delta = st.start_frame(2:end) - st.end_frame(1:end-1);
cut_inds = find(delta > threshold) + 1;

% - Are there too many epochs?
% See: https://gist.github.com/nicain/bce66cd073e422f07cf337b476c63be7
%      https://github.com/AllenInstitute/AllenSDK/issues/66
assert(numel(cut_inds) <= max_cuts, ...
   'BOT:StimulusError', ...
   'More than [%d] epochs were found.\nSee https://github.com/AllenInstitute/AllenSDK/issues/66.', ...
   max_cuts);

% - Loop over epochs
for nEpoch = numel(cut_inds)+1:-1:1
   % - Determine first frame
   if nEpoch == 1
      first_ind = st{1, 'start_frame'};
   else
      first_ind = st{cut_inds(nEpoch-1), 'start_frame'};
   end
   
   % - Determine last frame
   if nEpoch == numel(cut_inds)+1
      last_ind_inclusive = st{end, 'end_frame'};
   else
      last_ind_inclusive = st{cut_inds(nEpoch)-1, 'end_frame'};
   end
   
   % - Build list of epochs
   epoch_mask_list{nEpoch} = [first_ind last_ind_inclusive];
end
end

function [dxcm, dxtime] = align_running_speed(dxcm, dxtime, timestamps)
% align_running_speed - FUNCTION Align running speed data with fluorescence time stamps
%
% Usage: [dxcm, dxtime] = align_running_speed(dxcm, dxtime, timestamps)

% - Do we need to add time points at the beginning of the session?
if dxtime(1) ~= timestamps(1)
   % - Prepend timestamps and nans
   first_match = find(timestamps == dxtime(1), 1, 'first');
   dxtime = [timestamps(1:first_match-1); dxtime];
   dxcm = [nan(first_match, 1); dxcm];
end

% - Do we need to add time points at the end of the session?
num_missing = numel(timestamps) - numel(dxtime);
if num_missing > 0
   dxtime = [dxtime; timestamps(end - (num_missing-1):end)];
   dxcm = [dxcm; nan(num_missing, 1)];
end
end

function texture_coords = warp_stimulus_coords(vertices, distance, mon_height_cm, mon_width_cm, mon_res, eyepoint)
% warp_stimulus_coords - FUNCTION For a list of screen vertices, provides a corresponding list of texture coordinates
%
% Usage: texture_coords = warp_stimulus_coords(vertices <, distance, mon_height_cm, mon_width_cm, mon_res, eyepoint>)

% - Assign default arguments
if ~exist('distance', 'var') || isempty(distance)
   distance = 15;
end

if ~exist('mon_height_cm', 'var') || isempty(mon_height_cm)
   mon_height_cm = 32.5;
end

if ~exist('mon_width_cm', 'var') || isempty(mon_width_cm)
   mon_width_cm = 51;
end

if ~exist('mon_res', 'var') || isempty(mon_res)
   mon_res = [1920 1200];
end

if ~exist('eyepoint', 'var') || isempty(eyepoint)
   eyepoint = [.5 .5];
end

% - Convert from pixels (-1920/2 -> 1920/2) to stimulus space (-0.5 -> 0.5)
vertices = bsxfun(@rdivide, vertices, mon_res);

x = (vertices(:, 1) + .5) * mon_width_cm;
y = (vertices(:, 2) + .5) * mon_height_cm;

xEye = eyepoint(1) * mon_width_cm;
yEye = eyepoint(2) * mon_height_cm;

x = x - xEye;
y = y - yEye;

r = sqrt(x.^2 + y.^2 + distance.^2);

azimuth = atan(x ./ distance);
altitude = asin(y ./ r);

% - Calculate texture coordinates
tx = distance .* (1 + x ./ r) - distance;
ty = distance .* (1 + y ./ r) - distance;

% - The texture coordinates (which are now lying on the sphere) need to be
% remapped back onto the plane of the display. This effectively stretches the
% coordinates away from the eyepoint.

centralAngle = acos(cos(altitude) .* cos(abs(azimuth)));

% - Distance froom eyepoint to texture vertex
arcLength = centralAngle .* distance;

% - Remap the texture coordinates
theta = atan2(ty, tx);
tx = arcLength .* cos(theta);
ty = arcLength .* sin(theta);

u_coords = tx ./ mon_width_cm;
v_coords = ty ./ mon_height_cm;

texture_coords = [u_coords v_coords];

% - Convert back to pixels
texture_coords = bsxfun(@times, texture_coords, mon_res);
end

function mask = make_display_mask(display_shape)
% make_display_mask - FUNCTION Build a display-shaped mask that indicates which stimulus pixels are on screen after warping the stimulus
%
% Usage: mask = make_display_mask(display_shape)

% - Assign default arguments
if ~exist('display_shape', 'var') || isempty(display_shape)
   display_shape = [1920 1200];
end

% - Determine coordinates of the screen
x = (1:display_shape(1))-1 - display_shape(1) / 2;
y = (1:display_shape(2))-1 - display_shape(2) / 2;
[X, Y] = meshgrid(x, y);
display_coords = [X(:) Y(:)];

% - Warp the coordinates to spherical distance
warped_coords = warp_stimulus_coords(display_coords);

% - Determine which stimulus pixels are on-screen after warping
off_warped_coords = round(bsxfun(@plus, warped_coords, display_shape ./ 2));
mask = false(display_shape);
mask(sub2ind(display_shape, off_warped_coords(:, 1), off_warped_coords(:, 2))) = true;
end

function [mask, pixel_fraction] = mask_stimulus_template(template_display_coords, template_shape, display_mask, threshold)
% mask_stimulus_template - FUNCTION Build a mask for a stimulus template of a given shape and display coordinates that indicates which part of the template is on screen after warping
%
% Usage: [mask, pixel_fraction] = mask_stimulus_template(template_display_coords, template_shape, display_mask, threshold)

% - Assign default arguments
if ~exist('display_mask', 'var')
   display_mask = make_display_mask();
end

if ~exist('threshold', 'var') || isempty(threshold)
   threshold = 1;
end

% - Find valid indices for the template, and masked pixels
template_display_coords = reshape(template_display_coords, [], 2) + 1;
valid_indices = all(template_display_coords >= 1, 2) & all(bsxfun(@le, template_display_coords, template_shape), 2);
valid_mask_indices = display_mask(:) & valid_indices;

% - Determine which template units are on the screen above the threshold
pixel_fraction = accumarray(...
   [template_display_coords(valid_mask_indices, 1) template_display_coords(valid_mask_indices, 2)], ...
   1, template_shape);
pixel_totals = accumarray(...
   [template_display_coords(valid_indices, 1) template_display_coords(valid_indices, 2)], ...
   1, template_shape);

% - Create a mask indicating which stimulus pixels should be included
pixel_fraction = pixel_fraction ./ pixel_totals;
mask = pixel_fraction >= threshold;
end

function nwb_key = h5path(varargin)
% h5path - FUNCTION Generate a key path for an HDF5 file
%
% Usage: nwb_key = h5path(strPart1, strPart2, ...)

nwb_key = fullfile(filesep, varargin{:});
if ispc
   nwb_key = strrep(nwb_key, filesep, '/');
end
end


function s = zlclInitLinkedFilePropBindings()

s = struct();

s.SessH5 = string.empty(); %TODO: Should any current props bound to H5? Any new ones? Currently nothing tied to "analysis" H5 path

mc = meta.class.fromName(mfilename('class'));
propNames = string({findobj(mc.PropertyList,'GetAccess','public','-and','Dependent',1,'-and','Transient',1).Name});

s.SessNWB = setdiff(propNames,s.SessH5);

end