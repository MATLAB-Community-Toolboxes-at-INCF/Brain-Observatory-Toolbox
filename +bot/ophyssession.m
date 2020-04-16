%% bot.ophyssession - CLASS Represent an experimental container from the Allen Brain Observatory
%
% This is the main interface to access data from an Allen Brain Observatory
% experimental session. Use the `bot.cache` or `bot.sessionfilter` classes to
% identify an experimental session of interest. Then use `bot.ophyssession` to access
% data associated with that session id.
%
% Construction:
% >> bos = bot.opyssession(nSessionID);
%
% Get session metadata:
% >> bos.get_metadata()
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
% >> vnAllCellIDs = bos.get_cell_specimen_ids();
%
% Maximum intensity projection:
% >> imagesc(bos.get_max_projection());
%
% Obtain fluorescence traces:
% >> [vtTimestamps, mfTraces] = bos.get_fluorescence_traces();
% >> [vtTimestamps, mfTraces] = bos.get_dff_traces();
% >> [vtTimestamps, mfTraces] = bos.get_demixed_traces();
% >> [vtTimestamps, mfTraces] = bos.get_corrected_fluorescence_traces();
% >> [vtTimestamps, mfTraces] = bos.get_neuropil_traces();
%
% Get ROIs:
% >> sROIStructure = bos.get_roi_mask();
% >> tbROIMask = bos.get_roi_mask_array();
%
% Obtain behavioural data:
% >> [vtTimestamps, vfPupilLocation] = bos.get_pupil_location();
% >> [vtTimestamps, vfPupilAreas] = bos.get_pupil_size();
% >> [vtTimestamps, vfRunningSpeed] = get_running_speed();
%
% Obtain stimulus information:
% >> bos.get_stimulus_epoch_table()
% ans = 
%          stimulus          start_frame    end_frame
%     ___________________    ___________    _________
%     'static_gratings'        745           15191   
%     'natural_scenes'       16095           30542   
%        ...
%
% >> bos.get_stimulus(vnFrameNumbers)
% ans = 
%     frame    start_frame    end_frame    repeat        stimulus         ...
%     _____    ___________    _________    ______    _________________    ...
%     0        797            804          NaN       'static_gratings'    ...
%        ...
%
% See method documentation for further information.
% 
% [1] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. Available from: portal.brain-map.org/explore/circuits


classdef ophyssession
   
   %% - Public properties
   properties (SetAccess = private)
      sSessionInfo;              % Structure containing session metadata
   end

   properties (SetAccess = private, Dependent = true)
      strLocalNWBFileLocation;   % Local location of the NWB file corresponding to this session, if it has been cached
   end
   
   %% - Private properties
   properties (Hidden = true, SetAccess = private, Transient = true)
      bocCache = bot.cache();                            % Private handle to the BOT cache object
      
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
   
   
   %% - Constructor
   methods
      function bsObj = ophyssession(nSessionID)
         % bot.ophyssession - CONSTRUCTOR Construct an object containing an experimental session from an Allen Brain Observatory dataset
         %
         % Usage: bsObj = bot.ophyssession(nSessionID)
         %        vbsObj = bot.ophyssession(vnSessionIDs)
         %        bsObj = bot.ophyssession(tSessionRow)

         % - Support zero arguments
         if nargin == 0
            return;
         end
         
         % - Were we provided a table?
         if istable(nSessionID)
            tSession = nSessionID;
            
            % - Check for an 'id' column
            if ~ismember(tSession.Properties.VariableNames, 'id')
               error('BOT:InvalidSessionTable', ...
                     'The provided table does not describe an experimental session.');
            end
            
            % - Extract the session IDs
            nSessionID = tSession.id;
         end
         
         % - Check for a numeric argument
         if ~isnumeric(nSessionID)
            help bot.ophyssession/ophyssession;
            error('BOT:Usage', ...
                  'The session ID must be numeric.');
         end
         
         % - Were we provided a vector of session IDs?
         if numel(nSessionID) > 1
            % - Loop over session IDs and construct an object for each
            for nSessIndex = numel(nSessionID):-1:1
               bsObj(nSessIndex) = bot.ophyssession(nSessionID(nSessIndex));
            end
            return;
         end
            
         % - We should try to construct an object with this session ID
         %   First check that the session exists in the manifest of the
         %   Allen Brain Observatory dataset
         vbManifestRow = bsObj.bocCache.tOPhysSessions.id == nSessionID;
         if ~any(vbManifestRow)
            error('BOT:InvalidSessionID', ...
                  'The provided session ID [%d] does not match any session in the manifest of the Allen Brain Observatory dataset.', ...
                  nSessionID);
         end
         
         % - Raise a warning if multiple sessions were found
         if nnz(vbManifestRow) > 1
            warning('BOT:MatchedMultipleSessions', ...
                    'The provided session ID [%d] matched multiple containers. This probably shouldn''t happen. I''m returning the first match.', ...
                    nSessionID);
         end
         
         % - Extract the appropriate table row from the manifest
         bsObj.sSessionInfo = table2struct(bsObj.bocCache.tOPhysSessions(find(vbManifestRow, 1, 'first'), :));
         
      end
   end
   
   
   %% - Matlab BOT methods
   
   methods (Access = private)
      function strNWBURL = GetNWBURL(bos)
         % GetNWBURL - METHOD Get the cloud URL for the NWB dtaa file corresponding to this session
         %
         % Usage: strNWBURL = GetNWBURL(bos)
         
         % - Get well known files
         vs_well_known_files = bos.sSessionInfo.well_known_files;
         
         % - Find (first) NWB file
         vsTypes = [vs_well_known_files.well_known_file_type];
         cstrTypeNames = {vsTypes.name};
         nNWBFile = find(cellfun(@(c)strcmp(c, 'NWBOphys'), cstrTypeNames), 1, 'first');
         
         % - Build URL
         strNWBURL = [bos.bocCache.strABOBaseUrl vs_well_known_files(nNWBFile).download_link];
      end
      
      function bNWBFileIsCached = IsNWBFileCached(bos)
         % IsNWBFileCached - METHOD Check if the NWB file corresponding to this session is already cached
         %
         % Usage: bNWBFileIsCached = IsNWBFileCached(bos)
         bNWBFileIsCached =  bos.bocCache.IsURLInCache(GetNWBURL(bos));
      end
   end
   
   methods
      function strCacheFile = EnsureCached(bos)
         % EnsureCached - METHOD Ensure the data files corresponding to this session are cached
         %
         % Usage: strCachelFile = EnsureCached(bos)
         %
         % This method will force the session data to be downloaded and cached,
         % if it is not already available.
         bos.bocCache.CacheFilesForSessionIDs(bos.sSessionInfo.id);
         strCacheFile = bos.strLocalNWBFileLocation;
      end
      
      function strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         % get.strLocalNWBFileLocation - GETTER METHOD Return the local location of the NWB file correspoding to this session
         %
         % Usage: strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         if ~bos.IsNWBFileCached()
            strLocalNWBFileLocation = [];
         else
            % - Get the local file location for the session NWB URL
            strLocalNWBFileLocation = bos.bocCache.sCacheFiles.ccCache.CachedFileForURL(GetNWBURL(bos));
         end
      end
   end
   
   
   %% - Allen BO data set API. Mimics the brain_observatory_nwb_data_set class from the Allen API
   methods (Hidden = false)      
      function sMetadata = get_metadata(bos)
         % get_metadata - METHOD Read metadata from the NWB file
         %
         % Usage: sMetadata = get_metadata(bos)

         % - Ensure the data has been cached
         EnsureCached(bos);
         
         % - Attempt to read each of the metadata fields from the NWB file
         sMetadata = bos.FILE_METADATA_MAPPING;
         for strFieldname = fieldnames(bos.FILE_METADATA_MAPPING)'
            % - Convert to a string (otherwise it would be a cell)
            strFieldname = strFieldname{1}; %#ok<FXSET>
            
            % - Try to read this metadata entry
            try
               sMetadata.(strFieldname) = h5read(bos.strLocalNWBFileLocation, sMetadata.(strFieldname));
            catch
               sMetadata.(strFieldname) = [];
            end
         end
         
         % - Try to convert CRE line information
         if isfield(sMetadata, 'genotype') && ~isempty(sMetadata.genotype)
            sMetadata.cre_line = strsplit(sMetadata.genotype, ';');
            sMetadata.cre_line = sMetadata.cre_line{1};
         end
         
         % - Try to extract imaging depth in ?m
         if isfield(sMetadata, 'imaging_depth') && ~isempty(sMetadata.imaging_depth)
            sMetadata.imaging_depth_um = strsplit(sMetadata.imaging_depth);
            sMetadata.imaging_depth_um = str2double(sMetadata.imaging_depth_um{1});
         end
         
         % - Try to convert the experiment ID
         if isfield(sMetadata, 'ophys_experiment_id') && ~isempty(sMetadata.ophys_experiment_id)
            sMetadata.ophys_experiment_id = str2double(sMetadata.ophys_experiment_id);
         end

         % - Try to convert the experiment container ID
         if isfield(sMetadata, 'experiment_container_id') && ~isempty(sMetadata.experiment_container_id)
            sMetadata.experiment_container_id = str2double(sMetadata.experiment_container_id);
         end
         
         % - Convert the start time to a date
         
%         # convert start time to a date object
%         session_start_time = meta.get('session_start_time')
%         if isinstance(session_start_time, basestring):
%             meta['session_start_time'] = dateutil.parser.parse(session_start_time)

         % - Parse the age in days
         if isfield(sMetadata, 'age') && ~isempty(sMetadata.age)
            sMetadata.age_days = sscanf(sMetadata.age, '%d days');
         end

         % - Parse the device string
         if isfield(sMetadata, 'device_string') && ~isempty(sMetadata.device_string)
            [~, cMatches] = regexp(sMetadata.device_string, '(.*?)\.\s(.*?)\sPlease*', 'match', 'tokens');
            sMetadata.device = cMatches{1}{1};
            sMetadata.device_name = cMatches{1}{2};
         end
         
         % - Parse the file version
         if isfield(sMetadata, 'generated_by') && ~isempty(sMetadata.generated_by)
            sMetadata.pipeline_version = sMetadata.generated_by{end};
         else
            sMetadata.pipeline_version = '0.9';
         end
      end
      
      function vtTimestamps = get_fluorescence_timestamps(bos)
         % get_fluorescence_timestamps - METHOD Return timestamps for the fluorescence traces, in seconds
         %
         % Usage: vtTimestamps = get_fluorescence_timestamps(bos)
         %
         % `vtTimestamps` will be a vector of time points corresponding to
         % fluorescence samples, in seconds.
         
         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Read imaging timestamps from NWB file
         vtTimestamps = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1', 'timestamps'));     
            
         % - Convert to 'duration'
         vtTimestamps = seconds(vtTimestamps);
      end
      
      function vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         % get_cell_specimen_ids - METHOD Return all cell specimen IDs in this session
         %
         % Usage: vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         %
         % `vnCellSpecimenIDs` will be a vector of IDs corresponding to the ROIs
         % analysed in this session.
         
         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Read list of specimen IDs
         vnCellSpecimenIDs = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'ImageSegmentation', 'cell_specimen_ids'));
      end
      
      function vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         % get_cell_specimen_indices - METHOD Return indices corresponding to provided cell specimen IDs
         %
         % Usage: vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         %
         % `vnCellSpecimenIDs` is an Nx1 vector of valid cell specimen IDs.
         % `vnCellSpecimenIndices` will be an Nx1 vector with each element
         % indicating the 1-based index of the corresponding cell specimen ID in
         % the NWB data tables and fluorescence matrices.
         
         % - Ensure the file has been cached
         EnsureCached(bos);

         % - Read all cell specimen IDs
         vnAllCellSpecimenIDs = bos.get_cell_specimen_ids();
         
         % - Find provided IDs in list
         [vbFound, vnCellSpecimenIndices] = ismember(vnCellSpecimenIDs, vnAllCellSpecimenIDs);

         % - Raise an error if specimens not found
         assert(all(vbFound), 'BOT:NotFound', ...
            'Provided cell specimen ID was not found in this session.');
      end
      
      function [vtTimestamps, mfTraces] = get_demixed_traces(bos, vnCellSpecimenIDs)
         % get_demixed_traces - METHOD Return neuropil demixed fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_demixed_traces(bos <, vnCellSpecimenIDs>)
         %
         % `vtTimestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `mfTraces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `vtTimestamps`. Each column `n` contains the demixed fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.
         
         % - Ensure the file has been cached
         EnsureCached(bos);

         % - Get the fluorescence timestamps
         vtTimestamps = bos.get_fluorescence_timestamps();
         
         % - Find cell specimen IDs, if provided
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenInds = 1:numel(bos.get_cell_specimen_ids());
         else
            vnCellSpecimenInds = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         end
                           
         % - Read requested fluorescence traces
         mfTraces = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1_demixed_signal', 'data'));
         
         % - Subselect traces
         mfTraces = mfTraces(:, vnCellSpecimenInds);
      end      
      
      function [vtTimestamps, mfTraces] = get_fluorescence_traces(bos, vnCellSpecimenIDs)
         % get_fluorescence_traces - METHOD Return raw fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_fluorescence_traces(bos <, vnCellSpecimenIDs>)
         %
         % `vtTimestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `mfTraces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `vtTimestamps`. Each column `n` contains the demixed fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.
         
         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Get the fluorescence timestamps
         vtTimestamps = bos.get_fluorescence_timestamps();
         
         % - Find cell specimen IDs, if provided
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenInds = 1:numel(bos.get_cell_specimen_ids());
         else
            vnCellSpecimenInds = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         end
                           
         % - Read requested fluorescence traces
         mfTraces = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1', 'data'));
         
         % - Subselect traces
         mfTraces = mfTraces(:, vnCellSpecimenInds);
      end
      
      function vfR = get_neuropil_r(bos, vnCellSpecimenIDs)
         % get_neuropil_r - METHOD Return the neuropil correction variance explained for the provided cell specimen IDs
         %
         % Usage: vfR = get_neuropil_r(bos <, vnCellSpecimenIDs>)
         %
         % `vfR` will be a vector of neuropil correction factors for each
         % analysed cell. The optional argument `vnCellSpecimenIDs` can be used
         % to determine for which cells data should be returned. By default,
         % data for all cells is returned.
         
         % - Ensure the file has been cached
         EnsureCached(bos);

         % - Find cell specimen IDs, if provided
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenInds = 1:numel(bos.get_cell_specimen_ids());
         else
            vnCellSpecimenInds = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         end
                           
         % - Check pipeline version and read neuropil correction R
         sMetadata = bos.get_metadata();
         if str2double(sMetadata.pipeline_version) >= 2.0
            vfR = h5read(bos.strLocalNWBFileLocation, ...
               h5path('processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1_neuropil_response', 'r'));
         else
            vfR = h5read(bos.strLocalNWBFileLocation, ...
               h5path('processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1', 'r'));
         end
         
         % - Subsample R to requested cell specimens
         vfR = vfR(vnCellSpecimenInds);
      end
      
      function [vtTimestamps, mfTraces] = get_neuropil_traces(bos, vnCellSpecimenIDs)
         % get_neuropil_traces - METHOD Return the neuropil traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_neuropil_traces(bos <, vnCellSpecimenIDs>)
         %
         % `vtTimestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `mfTraces`
         % will be a TxN matrix of neuropil fluorescence samples, with each row
         % `t` contianing the data for the timestamp in the corresponding entry
         % of `vtTimestamps`. Each column `n` contains the neuropil response for
         % a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.

         % - Ensure the file has been cached
         EnsureCached(bos);

         % - Get the fluorescence timestamps
         vtTimestamps = bos.get_fluorescence_timestamps();
         
         % - Find cell specimen IDs, if provided
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenInds = 1:numel(bos.get_cell_specimen_ids());
         else
            vnCellSpecimenInds = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         end
                           
         % - Check pipeline version and read neuropil correction R
         sMetadata = bos.get_metadata();
         if str2double(sMetadata.pipeline_version) >= 2.0
            mfTraces = h5read(bos.strLocalNWBFileLocation, ...
               h5path('processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1_neuropil_response', 'data'));
         else
            mfTraces = h5read(bos.strLocalNWBFileLocation, ...
               h5path('processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1', 'neuropil_traces'));
         end
         
         % - Subselect traces
         mfTraces = mfTraces(:, vnCellSpecimenInds);         
      end
      
      function [vtTimestamps, mfTraces] = get_corrected_fluorescence_traces(bos, vnCellSpecimenIDs)
         % get_corrected_fluorescence_traces - METHOD Return corrected fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_corrected_fluorescence_traces(bos <, vnCellSpecimenIDs>)
         %
         % `vtTimestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `mfTraces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `vtTimestamps`. Each column `n` contains the demixed fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.
         
         % - Ensure the file has been cached
         EnsureCached(bos);

         % - Pass an empty matrix to return all cell specimen IDs
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenIDs = [];
         end
            
         % - Starting in pipeline version 2.0, neuropil correction follows trace demixing
         sMetadata = bos.get_metadata();
         if str2double(sMetadata.pipeline_version) >= 2.0
            [vtTimestamps, mfTraces] = bos.get_demixed_traces(vnCellSpecimenIDs);
         else
            [vtTimestamps, mfTraces] = bos.get_fluorescence_traces(vnCellSpecimenIDs);
         end
         
         % - Read neuropil correction data
         vfR = bos.get_neuropil_r(vnCellSpecimenIDs);
         [~, mfNeuropilTraces] = bos.get_neuropil_traces(vnCellSpecimenIDs);
         
         % - Correct fluorescence traces using neuropil demixing model
         mfTraces = mfTraces - bsxfun(@times, mfNeuropilTraces, reshape(vfR, 1, []));         
      end
      
      function [vtTimestamps, mfdFF] = get_dff_traces(bos, vnCellSpecimenIDs)
         % get_dff_traces - METHOD Return dF/F traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_dff_traces(bos <, vnCellSpecimenIDs>)
         %
         % `vtTimestamps` will be a Tx1 vector of timepoints in seconds, each
         % point defining a sample time for the fluorescence samples. `mfTraces`
         % will be a TxN matrix of fluorescence samples, with each row `t`
         % contianing the data for the timestamp in the corresponding entry of
         % `vtTimestamps`. Each column `n` contains the delta F/F0 fluorescence
         % data for a single cell specimen.
         %
         % By default, traces for all cell specimens are returned. The optional
         % argument`vnCellSpecimenIDs` permits you specify which cell specimens
         % should be returned.

         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Find cell specimen IDs, if provided
         if ~exist('vnCellSpecimenIDs', 'var') || isempty(vnCellSpecimenIDs)
            vnCellSpecimenInds = 1:numel(bos.get_cell_specimen_ids());
         else
            vnCellSpecimenInds = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         end
                           
         % - Read timestamps and response traces
         vtTimestamps = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'DfOverF', 'imaging_plane_1', 'timestamps'));
         vtTimestamps = seconds(vtTimestamps);
         
         mfdFF = h5read(bos.strLocalNWBFileLocation, ...
            h5path('processing', bos.strPipelineDataset, ...
               'DfOverF', 'imaging_plane_1', 'data'));
         
         % - Subsample response traces to requested cell specimens
         mfdFF = mfdFF(:, vnCellSpecimenInds);
      end
      
      function stimulus_table = get_spontaneous_activity_stimulus_table(bos)
         % get_spontaneous_activity_stimulus_table - METHOD Return the sponaneous activity stimulus table for this experimental session
         %
         % Usage: stimulus_table = get_spontaneous_activity_stimulus_table(bos)
         %
         % Return information about the epochs of spontaneous activity in this
         % experimental session.

         % - Build a key for this stimulus
         strKey = h5path('stimulus', 'presentation', 'spontaneous_stimulus');
         
         % - Read and convert stimulus data from the NWB file
         try
            % - Read data from the NWB file
            bos.EnsureCached();
            nwb_file = bos.strLocalNWBFileLocation;
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
            stimulus_table = array2table(stim_data, 'VariableNames', {'start_frame', 'end_frame'});

         catch meCause
            meBase = MException('BOT:StimulusError', 'Could not read spontaneous stimulus from session.\nThe stimulus may not exist.');
            meBase = meBase.addCause(meCause);
            throw(meBase);
         end
      end
      
      function cStimuli = list_stimuli(bos)
         % list_stimuli - METHOD Return the list of stimuli used in this experimental session
         %
         % Usage: cStimuli = list_stimuli(bos)
         %
         % `cStimuli` will be a cell array of strings, indicating which
         % individual stimulus sets were presented in this session.

         % - Get local NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Get list of stimuli from NWB file
         strKey = h5path('stimulus', 'presentation');
         sKeys = h5info(nwb_file, strKey);
         [~, cStimuli]= cellfun(@fileparts, {sKeys.Groups.Name}, 'UniformOutput', false);
         
         % - Remove trailing "_stimulus"
         cStimuli = cellfun(@(s)strrep(s, '_stimulus', ''), cStimuli, 'UniformOutput', false);
      end
      
      function strSessionType = get_session_type(bos)
         % get_session_type - METHOD Return the name for the stimulus set used in this session
         %
         % Usage: strSessionType = get_session_type(bos)
         strSessionType = bos.sSessionInfo.stimulus_name;
      end
      
      function tStimEpochs = get_stimulus_epoch_table(bos)
         % get_stimulus_epoch_table - METHOD Return the stimulus epoch table for this experimental session
         %
         % Usage: tStimEpochs = get_stimulus_epoch_table(bos)
         %
         % `tStimEpochs` will be a table containing information about all
         % stimulus epochs in this session.
         
         % - Hard-coded thresholds from Allen SDK for get_epoch_mask_list. These
         % set a maximum limit on the delta aqusistion frames to count as
         % different trials (rows in the stim table).  This helps account for
         % dropped frames, so that they dont cause the cutting of an entire
         % experiment into too many stimulus epochs. If these thresholds are too
         % low, the assert statment in get_epoch_mask_list will halt execution.
         % In that case, make a bug report!.
         sThresholds = struct('three_session_A', 32+7,...
                              'three_session_B', 15, ...
                              'three_session_C', 7, ...
                              'three_session_C2', 7);
         
         % - Get list of stimuli for this session
         cstrStimuli = bos.list_stimuli();
         
         % - Loop over stimuli to get stimulus tables
         tStimEpochs = table();
         for nStimIndex = numel(cstrStimuli):-1:1
            % - Get the stimulus table for this stimulus
            tThisStimulus = bos.get_stimulus_table(cstrStimuli{nStimIndex});
            
            % - Set "frame" column for spontaneous stimulus
            if isequal(cstrStimuli{nStimIndex}, 'spontaneous')
               tThisStimulus.frame = nan(size(tThisStimulus, 1), 1);
            end
            
            % - Get epochs for this stimulus
            cvnTheseEpochs = get_epoch_mask_list(tThisStimulus, sThresholds.(bos.get_session_type()));
            tTheseEpochs = array2table(int32(vertcat(cvnTheseEpochs{:})), 'VariableNames', {'start_frame', 'end_frame'});
            tTheseEpochs.stimulus = repmat(cstrStimuli(nStimIndex), numel(cvnTheseEpochs), 1);
            
            % - Append to stimulus epochs table
            tStimEpochs = vertcat(tStimEpochs, tTheseEpochs); %#ok<AGROW>
         end
         
         % - Sort by initial frame
         tStimEpochs = sortrows(tStimEpochs, 'start_frame');
         
         % - Rearrange columns to put 'stimulus' first
         tStimEpochs = [tStimEpochs(:, 3) tStimEpochs(:, 1:2)];
      end
            
      function tStimulusTable = get_stimulus_table(bos, strStimulusName)
         % get_stimulus_table - METHOD Return the stimulus table for the provided stimulus
         %
         % Usage: tStimulusTable = get_stimulus_table(bos, strStimulusName)
         %
         % `strStimulusName` is a string indicating for which stimulus data
         % should be returned. `strStimulusName` must be one of the stimuli
         % returned by bos.list_stimuli().
         %
         % `tStimulusTable` will be a table containing information about the
         % chosen stimulus. The individual stimulus frames can be accessed with
         % method bos.get_stimulus_template().

         % - Ensure the NWB file is cached
         bos.EnsureCached();         
         
         % - Return a stimulus table for one of the stimulus types
         if ismember(strStimulusName, bos.STIMULUS_TABLE_TYPES.abstract_feature_series)
            tStimulusTable = get_abstract_feature_series_stimulus_table(bos.strLocalNWBFileLocation, [strStimulusName '_stimulus']);
            return;
            
         elseif ismember(strStimulusName, bos.STIMULUS_TABLE_TYPES.indexed_time_series)
            tStimulusTable = get_indexed_time_series_stimulus_table(bos.strLocalNWBFileLocation, [strStimulusName '_stimulus']);
            return;
            
         elseif ismember(strStimulusName, bos.STIMULUS_TABLE_TYPES.repeated_indexed_time_series)
            tStimulusTable = get_repeated_indexed_time_series_stimulus_table(bos.strLocalNWBFileLocation, [strStimulusName '_stimulus']);
            return;
            
         elseif isequal(strStimulusName, 'spontaneous')
            tStimulusTable = bos.get_spontaneous_activity_stimulus_table();
            return;
            
         elseif isequal(strStimulusName, 'master')
            % - Return a master stimulus table containing all stimuli
            % - Loop over stimuli, collect stimulus tables
            ctStimuli = {};
            cstrVariableNames = {};
            for strStimulus = bos.list_stimuli()
               % - Get stimulus as a string
               strStimulus = strStimulus{1}; %#ok<FXSET>
               
               % - Get stimulus table for this stimulus, annotate with stimulus name
               ctStimuli{end+1} = bos.get_stimulus_table(strStimulus); %#ok<AGROW>
               ctStimuli{end}.stimulus = repmat({strStimulus}, size(ctStimuli{end}, 1), 1);
               
               % - Collect all variable names
               cstrVariableNames = union(cstrVariableNames, ctStimuli{end}.Properties.VariableNames);
            end
            
            % - Loop over stimulus tables and merge
            for nStimIndex = numel(ctStimuli):-1:1
               % - Find missing variables in this stimulus
               cstrMissingVariables = setdiff(cstrVariableNames, ctStimuli{nStimIndex}.Properties.VariableNames);
               
               % - Add missing variables to this stimulus table
               ctStimuli{nStimIndex} = [ctStimuli{nStimIndex} array2table(nan(size(ctStimuli{nStimIndex}, 1), numel(cstrMissingVariables)), 'VariableNames', cstrMissingVariables)];
            end
            
            % - Concatenate all stimuli and sort by start frame
            tStimulusTable = vertcat(ctStimuli{:});
            tStimulusTable = sortrows(tStimulusTable, 'start_frame');
            
         else
            % - Raise an error
            error('BOT:Argument', 'Could not find a stimulus table named [%s].', strStimulusName);
         end
      end
      
      function mfMaxProjection = get_max_projection(bos)
         % get_max_projection - METHOD Return the maximum-intensity projection image for this experimental session
         %
         % Usage: mfMaxProjection = get_max_projection(bos)
         %
         % `mfMaxProjection` will be an image contianing the maximum-intensity
         % projection of the fluorescence stack obtained in this session.

         % - Ensure session data is cached, and locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Extract the maximum projection from the session
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'imaging_plane_1', 'reference_images', ...
            'maximum_intensity_projection_image', 'data');
         mfMaxProjection = h5read(nwb_file, strKey);
      end
      
      function vnROIIDs = get_roi_ids(bos)
         % get_roi_ids - METHOD Return the list of ROI IDs for this experimental session
         %
         % Usage: vnROIIDs = get_roi_ids(bos)
         %
         % `vnROIIDs` will be a vector containing all ROI IDs analysed in this
         % session.
         
         % - Ensure session data is cached, and locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Extract list of ROI IDs from NWB file
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'roi_ids');
         vnROIIDs = cellfun(@str2num, h5read(nwb_file, strKey));
      end
      
      function [vtTimestamps, vfRunningSpeed] = get_running_speed(bos)
         % get_running_speed - METHOD Return running speed in cm/s
         %
         % Usage: [vtTimestamps, vfRunningSpeed] = get_running_speed(bos)
         %
         % `vtTimestamps` will be a Tx1 vector containing times in seconds,
         % corresponding to fluorescence timestamps. `vfRunningSpeed` will be a
         % Tx1 vector containing instantaneous running speeds at each
         % corresponding time point, in cm/s.
      
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Build a base key for the running speed data
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'BehavioralTimeSeries', 'running_speed');
         vfRunningSpeed = h5read(nwb_file, h5path(strKey, 'data'));
         vtTimestamps = seconds(h5read(nwb_file, h5path(strKey, 'timestamps')));
         
         % - Align with imaging timestamps
         vtImageTimestamps = bos.get_fluorescence_timestamps();
         [vfRunningSpeed, vtTimestamps] = align_running_speed(vfRunningSpeed, vtTimestamps, vtImageTimestamps);
      end
      
      function tMotionCorrection = get_motion_correction(bos)
         % get_motion_correction - METHOD Return the motion correction information for this experimental session
         %
         % Usage: tMotionCorrection = get_motion_correction(bos)
         %
         % `tMotionCorrection` will be a table containing x/y motion correction
         % information applied in this experimental session.
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Try to locate the motion correction data
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'MotionCorrection', '2p_image_series');
         
         try
            h5info(nwb_file, h5path(strKey, 'xy_translation'));
            strKey = h5path(strKey, 'xy_translation');
         catch
            try
               h5info(nwb_file, h5path(strKey, 'xy_translations'));
               strKey = h5path(strKey, 'xy_translations');
            catch
               error('BOT:MotionCorrectionNotFound', ...
                     'Could not file motion correction data.');
            end
         end
         
         % - Extract motion correction data from session
         motion_log = h5read(nwb_file, h5path(strKey, 'data'));
         motion_time = h5read(nwb_file, h5path(strKey, 'timestamps'));
         motion_names = h5read(nwb_file, h5path(strKey, 'feature_description'));
         
         % - Create a motion correction table
         tMotionCorrection = array2table(motion_log', 'VariableNames', motion_names);
         tMotionCorrection.timestamp = motion_time;
      end
      
      function [vtTimestamps, mfPupilLocation] = get_pupil_location(bos, bAsSpherical)
         % get_pupil_location - METHOD Return the pupil location trace for this experimental session
         %
         % Usage: [vtTimestamps, mfPupilLocation] = get_pupil_location(bos, <bAsSpherical>)
         %
         % `vtTimestamps` will be a Tx1 vector of times in seconds,
         % corresponding to fluorescence timestamps. `mfPupilLocation` will be a
         % Tx2 matrix, where each row contains the tracked location of the mouse
         % pupil. By default, spherical coordinates [`altitude` `azimuth`] are
         % returned in degrees, otherwise each row is [`x` `y`] in centimeters.
         % (0,0) is the center of the monitor.
         %
         % The optional argument `bAsSpherical` can be used to select spherical
         % or euclidean coordinates.
         
         % - Fail quickly if eye tracking data is known not to exist
         if bos.sSessionInfo.fail_eye_tracking
            error('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
         end
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Default for spherical coordinates
         if ~exist('bAsSpherical', 'var') || isempty(bAsSpherical)
            bAsSpherical = true;
         end
         
         % - Return spherical or euclidean coordinates?
         if bAsSpherical
            location_key = 'pupil_location_spherical';
         else
            location_key = 'pupil_location';
         end
         
         % - Extract data from NWB file
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'EyeTracking', location_key);
         
         try
            % - Try to read the eye tracking data from the NWB file
            mfPupilLocation = h5read(nwb_file, h5path(strKey, 'data'))';
            vtTimestamps = seconds(h5read(nwb_file, h5path(strKey, 'timestamps')));
            
         catch meCause
            % - Couldn't find the eye tracking data
            meBase = MException('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
            meBase = meBase.addCause(meCause);
            throw(meBase);
         end
      end
      
      function [vtTimestamps, vfPupilAreas] = get_pupil_size(bos)
         % get_pupil_size - METHOD Return the pupil area trace for this experimental session
         %
         % Usage: [vtTimestamps, vfPupilAreas] = get_pupil_size(bos)
         %
         % `vtTimestamps` will be a Tx1 vector of times in seconds,
         % corresponding to fluorescence timestamps. `vfPupilAreas` will be a
         % Tx1 vector, each element containing the instantaneous estimated pupil
         % area in pixels.
         
         % - Fail quickly if eye tracking data is known not to exist
         if bos.sSessionInfo.fail_eye_tracking
            error('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
         end
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Extract session data from NWB file
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'PupilTracking', 'pupil_size');
         
         try
            % - Try to read the eye tracking data from the NWB file
            vfPupilAreas = h5read(nwb_file, h5path(strKey, 'data'));
            vtTimestamps = seconds(h5read(nwb_file, h5path(strKey, 'timestamps')));
            
         catch meCause
            % - Couldn't find the eye tracking data
            meBase = MException('BOT:NoEyeTracking', ...
               'No eye tracking data is available for this experiment.');
            meBase = meBase.addCause(meCause);
            throw(meBase);
         end
      end
      
      function tbROIMasks = get_roi_mask_array(bos, vnCellSpecimenIDs)
         % get_roi_mask_array - METHOD Return the ROI mask for the provided cell specimen IDs
         %
         % Usage: tbROIMasks = get_roi_mask_array(bos <, vnCellSpecimenIDs>)
         %
         % `tbROIMasks` will be a [XxYxC] boolean tensor. Each C slice
         % corresponds to a single imaged ROI, and indicates which pixels in the
         % stack contain that ROI. The optional argument `vnCellSpecimenIDs` can
         % be used to select for which cells data should be returned. By
         % default, a mask is returned for all ROIs.
         
         % - By default, return masks for all cells
         if ~exist('vnCellSpecimenIDs', 'var')
            vnCellSpecimenIDs = bos.get_cell_specimen_ids;
         end
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'imaging_plane_1');
         
         % - Get list of ROI names
         cstrRoiList = deblank(h5read(nwb_file, h5path(strKey, 'roi_list')));
         
         % - Select only requested cell specimen IDs
         vnCellIndices = bos.get_cell_specimen_indices(vnCellSpecimenIDs);
         
         % - Loop over ROIs, extract masks
         tbROIMasks = [];
         for nCellIndex = vnCellIndices'
            % - Get a logical mask for this ROI
            mbThisMask = logical(h5read(nwb_file, h5path(strKey, cstrRoiList{nCellIndex}, 'img_mask')));
            
            % - Build a logical tensor of ROI masks
            if isempty(tbROIMasks)
               tbROIMasks = mbThisMask;
            else
               tbROIMasks = cat(3, tbROIMasks, mbThisMask);
            end
         end
      end
      
      function sROIs = get_roi_mask(bos, vnCellSpecimenIDs)
         % get_roi_mask - METHOD Return connected components structure defining requested ROIs
         %
         % Usage: sROIs = get_roi_mask(bos <, vnCellSpecimenIDs>)
         %
         % `sROIs` will be a structure as returned from `bwconncomp`, defining a
         % set of ROIs. This can be passed to `labelmatrix`, etc. The optional
         % argument `vnCellSpecimenIDs` can be used to select for which cells
         % data should be returned. By default, a mask is returned for all ROIs.
         
         % - By default, return masks for all cells
         if ~exist('vnCellSpecimenIDs', 'var')
            vnCellSpecimenIDs = bos.get_cell_specimen_ids;
         end
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         strKey = h5path('processing', bos.strPipelineDataset, ...
            'ImageSegmentation', 'imaging_plane_1');
         
         % - Get list of ROI names
         cstrRoiList = deblank(h5read(nwb_file, h5path(strKey, 'roi_list')));
         
         % - Select only requested cell specimen IDs
         vnCellIndices = bos.get_cell_specimen_indices(vnCellSpecimenIDs);

         % - Initialise a CC structure
         sROIs = struct('Connectivity', 8, ...
                        'ImageSize', {[]}, ...
                        'NumObjects', numel(vnCellIndices), ...
                        'PixelIdxList', {{}}, ...
                        'Labels', {{}});

         % - Loop over ROIs, extract masks
         for nCellIndex = numel(vnCellIndices):-1:1
            % - Get a logical mask for this ROI
            mbThisMask = logical(h5read(nwb_file, h5path(strKey, cstrRoiList{vnCellIndices(nCellIndex)}, 'img_mask')));

            % - Build up a CC structure containing these ROIs
            sROIs.PixelIdxList{nCellIndex} = find(mbThisMask);
            sROIs.Labels{nCellIndex} = cstrRoiList{vnCellIndices(nCellIndex)};
         end
         
         % - Fill in CC structure
         sROIs.ImageSize = size(mbThisMask);
      end

      function tfStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         % get_stimulus_template - METHOD Return the stimulus template for the provided stimulus
         %
         % Usage: tfStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         %
         % `strStimulusName` is a string array, matching one of the stimuli used
         % in this experimental session. `tfStimulusTemplate` will be an [XxYxF]
         % tensor, each F-slice corresponds to a single stimulus frame as
         % referenced in the stimulus tables ('frame', see method
         % get_stimulus_table()).
         
         % - Ensure session data is cached, locate NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Extract stimulus template from NWB file
         strKey = h5path('stimulus', 'templates', ...
            [strStimulusName '_image_stack'], 'data');
         
         try
            tfStimulusTemplate = h5read(nwb_file, strKey);
            
         catch meCause
            meBase = MException('BOT:StimulusNotFound', ...
               'A template for the stimulus [%s] was not found.', ...
               strStimulusName);
            meBase = meBase.addCause(meCause);
            throw(meBase);
         end
      end
      
      function [tfStimTemplate, mbOffScreenMask] = get_locally_sparse_noise_stimulus_template(bos, strStimulus, bMaskOffScreen)
         % get_locally_sparse_noise_stimulus_template - METHOD Return the locally sparse noise stimulus template used for this sessions
         %
         % Usage: [tfStimTemplate, mbOffScreenMask] = get_locally_sparse_noise_stimulus_template(bos, strStimulus <, bMaskOffScreen>)
         %
         % `strStimulus` must be one of {'locally_sparse_noise',
         % 'locally_sparse_noise_4deg', 'locally_sparse_noise_8deg'}, and one of
         % these stimuli must have been used in this experimental session.
         % `tfStimTemplate` will be an [XxYxF] stimulus template, containing the
         % set of locally sparse noise frames used in this experimental session.
         % Each F-slice corresponds to one stimulus frame as referenced in the
         % stimulus tables ('frame').
         %
         % `mbOffScreenMask` will be an [XxY] boolean matrix, indicating which
         % pixels were displayed to the animal after spatial warping of the
         % stimulus.
         %
         % The optional argument `bMaskOffScreen` can be used to specify whether
         % off-screen pixels should be blanked in `tfStimTemplate`. By default,
         % off-screen pixels are blanked.
         
         % - Pre-defined dimensions for locally sparse noise stimuli
         sLocallySparseNoiseDimensions = struct(...
            'locally_sparse_noise', [16 28], ...
            'locally_sparse_noise_4deg', [16 28], ...
            'locally_sparse_noise_8deg', [8 14]);

         % - By default, mask off screen regions
         if ~exist('bMaskOffScreen', 'var') || isempty(bMaskOffScreen)
            bMaskOffScreen = true;
         end
         
         % - Is the provided stimulus one of the known noise stimuli?
         if ~isfield(sLocallySparseNoiseDimensions, strStimulus)
            cstrStimNames = fieldnames(sLocallySparseNoiseDimensions);
            error('BOT:UnknownStimulus', ...
               '''strStimulus'' must be one of {%s}.', ...
               sprintf('%s, ', cstrStimNames{:}));
         end
         
         % - Get a stimulus template
         tfStimTemplate = bos.get_stimulus_template(strStimulus);
         vnTemplateSize = size(tfStimTemplate);
         
         % - Build a mapping from template to display coordinates
         template_size = sLocallySparseNoiseDimensions.(strStimulus);
         template_size = template_size([2 1]);
         template_display_size = [1260 720];
         display_size = [1920 1200];
         
         scale = template_size ./ template_display_size;
         offset = -(display_size - template_display_size) / 2;
         
         [x, y] = ndgrid((1:display_size(1))-1, (1:display_size(2))-1);
         template_display_coords = cat(3, (x + offset(1)) * scale(1) - .5, (y + offset(2)) * scale(2) - .5);
         template_display_coords = round(template_display_coords);
         
         % - Obtain a mask indicating which stimulus elements are off-screen after warping
         [mbOffScreenMask, ~] = mask_stimulus_template(template_display_coords, template_size);
         if bMaskOffScreen
            % - Mask the off-screen stimulus elements
            tfStimTemplate = reshape(tfStimTemplate, [], vnTemplateSize(3));
            tfStimTemplate(~mbOffScreenMask(:), :) = 64;
            tfStimTemplate = reshape(tfStimTemplate, vnTemplateSize);
         end
      end
      
      function [tStimulus, vbValidFrame, tfStimFrame] = get_stimulus(bos, vnFrameIndex)
         % get_stimulus - METHOD Return stimulus information for selected frame indices
         %
         % Usage: [tStimulus, vbValidFrame, tfStimFrame] = get_stimulus(bos, vnFrameIndex)
         %
         % `vnFrameIndex` is a vector of fluorescence frame indices (1-based).
         % This method finds the stimuli that correspond to these frame indices.
         % `tStimulus` will be a table with each row corresponding to a valid
         % frame index. `vbValidFrame` is a boolean vector indicating which
         % frames in `vnFrameIndex` are valid stimulus frames. If a frame falls
         % outside a registered stimulus epoch, it is considered not valid.
         %
         % Each row in `tStimulus` indicates the full stimulus information
         % associated with the corresponding valid frame in `vnFrameIndex`. For
         % stimuli with a corresponding stimulus template (see method
         % get_stimulus_template()), the column 'frame' contains an index
         % indicating which stimulus frame was presented at that point in time.
         %         
         % Note: The tensor `tfStimFrame` can optionally be used to return the
         % stimulus template frames associated with each valid frame index. This
         % is not recommended, since it can use a large amount of redundant
         % memory storage. Stimulus templates can only be returned for stimuli
         % that use them (i.e. locally sparse noise, natural movies, etc.)
         
         % - Ensure NWB file is cached
         bos.EnsureCached();
         
         % - Obtain and cache the master stimulus table for this session
         %   Also handles to accelerated search functions
         if isempty(bos.smCachedStimulusTable)
            tEpochStimTable = bos.get_stimulus_epoch_table();
            tMasterStimTable = bos.get_stimulus_table('master');
            bos.smCachedStimulusTable(1) = tEpochStimTable;
            bos.smCachedStimulusTable(2) = int32(tEpochStimTable{:, {'start_frame', 'end_frame'}});
            bos.smCachedStimulusTable(3) = tMasterStimTable;
            bos.smCachedStimulusTable(4) = int32(tMasterStimTable{:, {'start_frame', 'end_frame'}});
            [bos.smCachedStimulusTable(5), bos.smCachedStimulusTable(6)] = bot.internal.get_mex_handles();
         end
         
         % - Get the matrix of start and end frames
         mnEpochStartEndFrames = bos.smCachedStimulusTable(2);
         tMasterStimTable = bos.smCachedStimulusTable(3);
         mnStimulusStartEndFrames = bos.smCachedStimulusTable(4);
         fhBSSL_int32 = bos.smCachedStimulusTable(6);
         
         % - Ensure that `vnFrameIndex` is sorted
         if ~issorted(vnFrameIndex)
            vnFrameIndex = sort(vnFrameIndex);
         end
         
         % - Ensure that the frame index is a column vector
         vnFrameIndex = reshape(vnFrameIndex, [], 1);

         % - Identify search frames that are outside registered epochs
         vbValidFrame = vnFrameIndex >= mnEpochStartEndFrames(1, 1) & vnFrameIndex <= mnEpochStartEndFrames(end, 2);
         
         % - Were any frames found?
         if ~any(vbValidFrame)
            tStimulus = tMasterStimTable([], :);
            tfStimFrame = [];
            return;
         end
         
         % - Find matching stimulus epochs
         vnStartEpochIndex = fhBSSL_int32(mnEpochStartEndFrames(:, 1), int32(vnFrameIndex(vbValidFrame)));
         vnEndEpochIndex = fhBSSL_int32([mnEpochStartEndFrames(1, 1); mnEpochStartEndFrames(:, 2)], int32(vnFrameIndex(vbValidFrame)));
         
         % - Valid frames must fall within a registered stimulus epoch
         vbValidFrame(vbValidFrame) = vbValidFrame(vbValidFrame) & (vnStartEpochIndex == vnEndEpochIndex);
         
         % - Were any frames found?
         if ~any(vbValidFrame)
            tStimulus = tMasterStimTable([], :);
            tfStimFrame = [];
            return;
         end
         
         % - Find matching stimulus frames
         vnFoundFrameIndex = fhBSSL_int32(mnStimulusStartEndFrames(:, 1), int32(vnFrameIndex(vbValidFrame)));
         
         % - Extract an excerpt from the master stimulus table corresponding to these frames
         tStimulus = tMasterStimTable(vnFoundFrameIndex, :);
         
         % - Try to extract stimulus frames
         if nargout > 2
            % - Is there more than one stimulus template?
            if numel(unique(tStimulus.stimulus)) > 1
               warning('BOT:MultipleStimulusTypes', ...
                       'Warning: Cannot extract stimulus templates for multiple stimulus types simultaneously');
               tfStimFrame = [];

            else
               % - Get the name of this stimulus
               strStimulus = tStimulus{1, 'stimulus'};
               strStimulus = strStimulus{1};
               
               % - Extract the corresponding stimulus template
               try
                  tfStimTemplate = bos.get_stimulus_template(strStimulus);
                  tfStimFrame = tfStimTemplate(:, :, tStimulus.frame);
                  
               catch
                  % - Could not find the appropriate template, so return empty
                  tfStimFrame = [];
               end
            end
         end
      end
   end
end

%% - Private utility functions

function stimulus_table = get_abstract_feature_series_stimulus_table(nwb_file, stimulus_name)
	% get_abstract_feature_series_stimulus_table - FUNCTION Return a stimlus table for an abstract feature series stimulus

   % - Build a key for this stimulus
   strKey = h5path('stimulus', 'presentation', stimulus_name);
   
   % - Read and convert stimulus data from the NWB file
   try
      % - Read data from the NWB file
      stim_data = h5read(nwb_file, h5path(strKey, 'data'));
      features = deblank(h5read(nwb_file, h5path(strKey, 'features')));
      frame_dur = h5read(nwb_file, h5path(strKey, 'frame_duration'));
      
      % - Create a stimulus table to return
      stimulus_table = array2table(stim_data', 'VariableNames', features);
      
      % - Add start and finish frame times
      stimulus_table.start_frame = int32(frame_dur(1, :)');
      stimulus_table.end_frame = int32(frame_dur(2, :)');
      
   catch meCause
      meBase = MException('BOT:StimulusError', ...
         'Could not read stimulus [%s] from session.\nThe stimulus may not exist.', stimulus_name);
      meBase = meBase.addCause(meCause);
      throw(meBase);
   end
end

function stimulus_table = get_indexed_time_series_stimulus_table(nwb_file, stimulus_name)
   % get_indexed_time_series_stimulus_table - FUNCTION Return a stimlus table for an indexed time series stimulus

   % - Build a key for this stimulus
   strKey = h5path('stimulus', 'presentation', stimulus_name);
   
   % - Attempt to read data from this key, otherwise correct
   try
      h5info(nwb_file, strKey);
   catch
      strKey = h5path('stimulus', 'presentation', [stimulus_name '_stimulus']);
   end
   
   % - Read and convert stimulus data from the NWB file
   try
      % - Read data from the NWB file
      inds = h5read(nwb_file, h5path(strKey, 'data')) + 1;
      frame_dur = h5read(nwb_file, h5path(strKey, 'frame_duration'));
      
      % - Create a stimulus table to return
      stimulus_table = array2table(inds, 'VariableNames', {'frame'});
      
      % - Add start and finish frame times
      stimulus_table.start_frame = int32(frame_dur(1, :)');
      stimulus_table.end_frame = int32(frame_dur(2, :)');
      
   catch meCause
      meBase = MException('BOT:StimulusError', 'Could not read stimulus [%s] from session.\nThe stimulus may not exist.');
      meBase = meBase.addCause(meCause);
      throw(meBase);
   end
end

function stimulus_table = get_repeated_indexed_time_series_stimulus_table(nwb_file, stimulus_name)
   % get_repeated_indexed_time_series_stimulus_table - FUNCTION Return a stimulus table for a repeated stimulus
   
   % - Get the full stimulus table
   stimulus_table = get_indexed_time_series_stimulus_table(nwb_file, stimulus_name);
   
   % - Locate repeats within stimulus order
   vnUniqueStims = unique(stimulus_table.frame);
   cvnRepeatIndices = arrayfun(@(nStim)find(stimulus_table.frame == nStim), vnUniqueStims, 'UniformOutput', false);
   
   % - Switch off warnings for extending the table
   w = warning('off', 'MATLAB:table:RowsAddedNewVars');
   
   % - Loop over stimulus IDs, assign repeat numbers (zero-based to match Python SDK)
   vnRepeatIndices = nan(size(stimulus_table, 1), 1);
   for nStimulus = 1:numel(vnUniqueStims)
      vnRepeatIndices(cvnRepeatIndices{nStimulus}) = (1:numel(cvnRepeatIndices{nStimulus}))' - 1;
   end

   % - Assign repeat column to table
   stimulus_table.repeat = vnRepeatIndices;

   % - Restore warnings
   warning(w);
end

function epoch_mask_list = get_epoch_mask_list(st, threshold, max_cuts)
   % get_epoch_mask_list - FUNCTION Cut a stimulus table into multiple epochs
   %
   % Usage: epoch_mask_list = get_epoch_mask_list(st, threshold, max_cuts)
   
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
      nFirstMatch = find(timestamps == dxtime(1), 1, 'first');
      dxtime = [timestamps(1:nFirstMatch-1); dxtime];
      dxcm = [nan(nFirstMatch, 1); dxcm];
   end
   
   % - Do we need to add time points at the end of the session?
   nNumMissing = numel(timestamps) - numel(dxtime);
   if nNumMissing > 0
      dxtime = [dxtime; timestamps(end - (nNumMissing-1):end)];
      dxcm = [dxcm; nan(nNumMissing, 1)];
   end
end

function retCoords = warp_stimulus_coords(vertices, distance, mon_height_cm, mon_width_cm, mon_res, eyepoint)
   % warp_stimulus_coords - FUNCTION For a list of screen vertices, provides a corresponding list of texture coordinates
   % 
   % Usage: retCoords = warp_stimulus_coords(vertices <, distance, mon_height_cm, mon_width_cm, mon_res, eyepoint>)

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
   
   retCoords = [u_coords v_coords];
   
   % - Convert back to pixels
   retCoords = bsxfun(@times, retCoords, mon_res);
end

function mbMask = make_display_mask(display_shape)
   % make_display_mask - FUNCTION Build a display-shaped mask that indicates which stimulus pixels are on screen after warping the stimulus
   %
   % Usage: mbMask = make_display_mask(display_shape)

   % - Assign default arguments
   if ~exist('display_shape', 'var') || isempty(display_shape)
      display_shape = [1920 1200];
   end

   % - Determine coordinates of the screen
   x = (1:display_shape(1))-1 - display_shape(1) / 2;
   y = (1:display_shape(2))-1 - display_shape(2) / 2;
   [mX, mY] = meshgrid(x, y);
   display_coords = [mX(:) mY(:)];
   
   % - Warp the coordinates to spherical distance
   warped_coords = warp_stimulus_coords(display_coords);
   
   % - Determine which stimulus pixels are on-screen after warping
   off_warped_coords = round(bsxfun(@plus, warped_coords, display_shape ./ 2));
   mbMask = false(display_shape);
   mbMask(sub2ind(display_shape, off_warped_coords(:, 1), off_warped_coords(:, 2))) = true;
end

function [mbMask, mfPixelFraction] = mask_stimulus_template(template_display_coords, template_shape, display_mask, threshold)
   % mask_stimulus_template - FUNCTION Build a mask for a stimulus template of a given shape and display coordinates that indicates which part of the template is on screen after warping
   %
   % Usage: [mbMask, mfPixelFraction] = mask_stimulus_template(template_display_coords, template_shape, display_mask, threshold)

   % - Assign default arguments
   if ~exist('display_mask', 'var')
      display_mask = make_display_mask();
   end

   if ~exist('threshold', 'var') || isempty(threshold)
      threshold = 1;
   end

   % - Find valid indices for the template, and masked pixels
   template_display_coords = reshape(template_display_coords, [], 2) + 1;
   vbValidIndices = all(template_display_coords >= 1, 2) & all(bsxfun(@le, template_display_coords, template_shape), 2);
   vbValidMaskIndices = display_mask(:) & vbValidIndices;
   
   % - Determine which template units are on the screen above the threshold
   mfPixelFraction = accumarray(...
      [template_display_coords(vbValidMaskIndices, 1) template_display_coords(vbValidMaskIndices, 2)], ...
      1, template_shape);
   mnPixelTotals = accumarray(...
      [template_display_coords(vbValidIndices, 1) template_display_coords(vbValidIndices, 2)], ...
      1, template_shape);
   
   % - Create a mask indicating which stimulus pixels should be included
   mfPixelFraction = mfPixelFraction ./ mnPixelTotals;
   mbMask = mfPixelFraction >= threshold;
end

function strPath = h5path(varargin)
   % h5path - FUNCTION Generate a path for an HDF5 file
   %
   % Usage: strPath = h5path(strPart1, strPart2, ...)
   
   strPath = fullfile(filesep, varargin{:});
   if ispc
      strPath = strrep(strPath, filesep, '/');
   end
end
