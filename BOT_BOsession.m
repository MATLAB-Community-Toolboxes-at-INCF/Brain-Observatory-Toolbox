% BOT_BOsession - CLASS Represent an experimental container from the Allen Brain Observatory
%
% 

classdef BOT_BOsession
   
   %% - Public properties
   properties (SetAccess = private)
      sSessionInfo;              % Structure containing session metadata
   end

   properties (SetAccess = private, Dependent = true)
      strLocalNWBFileLocation;   % Local location of the NWB file corresponding to this session, if it has been cached
   end
   
   %% - Private properties
   properties (Hidden = true, SetAccess = private, Transient = true)
      bocCache = BOT_cache();    % Private handle to the BOT cache object
      
      strSupportedPipelineVersion = '2.0';
      strPipelineDataset = 'brain_observatory_pipeline';

      FILE_METADATA_MAPPING = struct(...
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
      
      STIMULUS_TABLE_TYPES = struct( ...
         'abstract_feature_series',       {{'drifting_gratings', 'static_gratings'}}, ...
         'indexed_time_series',           {{'natural_scenes', 'locally_sparse_noise', ...
                                            'locally_sparse_noise_4deg', 'locally_sparse_noise_8deg'}}, ...
         'repeated_indexed_time_series',  {{'natural_movie_one', 'natural_movie_two', 'natural_movie_three'}});
   
      sCachedMetadata = [];
   end
   
   
   %% - Constructor
   methods
      function bsObj = BOT_BOsession(nSessionID)
         % BOT_BOsession - CONSTRUCTOR Construct an object containing a Brain Observatory experimental sesion
         %
         % Usage: bsObj = BOT_BOsession(nSessionID)
         %        vbsObj = BOT_BOsession(vnSessionIDs)
         %        bsObj = BOT_BOsession(tSessionRow)

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
            help BOT_BOsession/BOT_BOsession;
            error('BOT:Usage', ...
                  'The session ID must be numeric.');
         end
         
         % - Were we provided a vector of session IDs?
         if numel(nSessionID) > 1
            % - Loop over session IDs and construct an object for each
            for nSessIndex = numel(nSessionID):-1:1
               bsObj(nSessIndex) = BOT_BOsession(nSessionID(nSessIndex));
            end
            return;
         end
            
         % - We should try to construct an object with this session ID
         %   First check that the session exists in the Allen Brain
         %   Observatory manifest
         vbManifestRow = bsObj.bocCache.tAllSessions.id == nSessionID;
         if ~any(vbManifestRow)
            error('BOT:InvalidSessionID', ...
                  'The provided session ID [%d] does not match any session in the Brain Observatory manifest.', ...
                  nSessionID);
         end
         
         % - Raise a warning if multiple sessions were found
         if nnz(vbManifestRow) > 1
            warning('BOT:MatchedMultipleSessions', ...
                    'The provided session ID [%d] matched multiple containers. This probably shouldn''t happen. I''m returning the first match.', ...
                    nSessionID);
         end
         
         % - Extract the appropriate table row from the manifest
         bsObj.sSessionInfo = table2struct(bsObj.bocCache.tAllSessions(find(vbManifestRow, 1, 'first'), :));
      end
   end
   
   
   %% - Matlab BOT methods
   
   methods (Access = private)
      function bNWBFileIsCached = IsNWBFileCached(bos)
         % IsNWBFileCached - METHOD Check if the NWB file corresponding to this session is already cached
         %
         % Usage: bNWBFileIsCached = IsNWBFileCached(bos)
         bNWBFileIsCached =  bos.bocCache.IsInCache([bos.bocCache.strABOBaseUrl bos.sSessionInfo.well_known_files.download_link]);
      end
      
      function delete(~)
         % delete - DELETER METHOD Clean up when the object is destroyed
         %
         % Usage: delete(bos)
      end
   end
   
   methods
      function strLocalFile = EnsureCached(bos)
         % EnsureCached - METHOD Ensure the NWB file corresponding to this session is cached
         %
         % Usage: strLocalFile = EnsureCached(bos)
         strLocalFile = bos.bocCache.CacheFilesForSessionIDs(bos.sSessionInfo.id);
      end
      
      function strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         % get.strLocalNWBFileLocation - GETTER METHOD Return the local location of the NWB file correspoding to this session
         %
         % Usage: strLocalNWBFileLocation = get.strLocalNWBFileLocation(bos)
         if ~bos.IsNWBFileCached()
            strLocalNWBFileLocation = [];
         else
            % - Get the local file location for the session NWB URL
            strLocalNWBFileLocation = bos.bocCache.sCacheFiles.ccCache.CachedFileForURL([bos.bocCache.strABOBaseUrl bos.sSessionInfo.well_known_files.download_link]);
         end
      end
   end
   
   
   %% - Allen BO data set API
   methods (Hidden = false)
      
      %% - Implemented
      
      function sMetadata = get_metadata(bos)
         % get_metadata - METHOD Read metadata from the NWB file
         %
         % Usage: sMetadata = get_metadata(bos)

         % - Ensure the file has been cached
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
         % get_fluorescence_timestamps - METHOD Return timestamps for the fluorescence traces
         %
         % Usage: vtTimestamps = get_fluorescence_timestamps(bos)
         
         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Read imaging timestamps from NWB file
         vtTimestamps = h5read(bos.strLocalNWBFileLocation, ...
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1', 'timestamps'));         
      end
      
      function vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         % get_cell_specimen_ids - METHOD Return all cell specimen IDs in this session
         %
         % Usage: vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         
         % - Ensure the file has been cached
         EnsureCached(bos);
         
         % - Read list of specimen IDs
         vnCellSpecimenIDs = h5read(bos.strLocalNWBFileLocation, ...
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
               'ImageSegmentation', 'cell_specimen_ids'));
      end
      
      function vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         % get_cell_specimen_indices - METHOD Return indices corresponding to provided cell specimen IDs
         %
         % Usage: vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         
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
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
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
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
               'Fluorescence', 'imaging_plane_1', 'data'));
         
         % - Subselect traces
         mfTraces = mfTraces(:, vnCellSpecimenInds);
      end
      
      function vfR = get_neuropil_r(bos, vnCellSpecimenIDs)
         % get_neuropil_r - METHOD Return the neuropil correction variance explained for the provided cell specimen IDs
         %
         % Usage: vfR = get_neuropil_r(bos <, vnCellSpecimenIDs>)
         
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
               fullfile(filesep, 'processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1_neuropil_response', 'r'));
         else
            vfR = h5read(bos.strLocalNWBFileLocation, ...
               fullfile(filesep, 'processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1', 'r'));
         end
         
         % - Subsample R to requested cell specimens
         vfR = vfR(vnCellSpecimenInds);
      end
      
      function [vtTimestamps, mfTraces] = get_neuropil_traces(bos, vnCellSpecimenIDs)
         % get_neuropil_traces - METHOD Return the neuropil traces for the provided cell specimen IDs
         %
         % Usage: [vtTimestamps, mfTraces] = get_neuropil_traces(bos, vnCellSpecimenIDs)

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
               fullfile(filesep, 'processing', bos.strPipelineDataset, ...
                  'Fluorescence', 'imaging_plane_1_neuropil_response', 'data'));
         else
            mfTraces = h5read(bos.strLocalNWBFileLocation, ...
               fullfile(filesep, 'processing', bos.strPipelineDataset, ...
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
         % Usage: [vtTimestamps, mfTraces] = get_dff_traces(bos, vnCellSpecimenIDs)

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
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
               'DfOverF', 'imaging_plane_1', 'timestamps'));
         
         mfdFF = h5read(bos.strLocalNWBFileLocation, ...
            fullfile(filesep, 'processing', bos.strPipelineDataset, ...
               'DfOverF', 'imaging_plane_1', 'data'));
         
         % - Subsample response traces to requested cell specimens
         mfdFF = mfdFF(:, vnCellSpecimenInds);
      end
      
      function stimulus_table = get_spontaneous_activity_stimulus_table(bos)
         % get_spontaneous_activity_stimulus_table - METHOD Return the sponaneous activity stimulus table for this experimental session
         %
         % Usage: stimulusTable = get_spontaneous_activity_stimulus_table(bos)

         % - Build a key for this stimulus
         strKey = fullfile(filesep, 'stimulus', 'presentation', 'spontaneous_stimulus');
         
         % - Read and convert stimulus data from the NWB file
         try
            % - Read data from the NWB file
            bos.EnsureCached();
            nwb_file = bos.strLocalNWBFileLocation;
            events = h5read(nwb_file, fullfile(strKey, 'data'));
            frame_dur = h5read(nwb_file, fullfile(strKey, 'frame_duration'));

            % - Locate start and stop events
            start_inds = find(events == 1);
            stop_inds = find(events == -1);

            % - Check spontaneous activity data
            assert(numel(start_inds) == numel(stop_inds), ...
                   'BOT:StimulusError', 'Inconsistent start and time times in spontaneous activity stimulus table');
            
            % - Create a stimulus table to return
            stim_data = [frame_dur(1, start_inds) frame_dur(1, stop_inds)];
            
            % - Create a stimulus table to return
            stimulus_table = array2table(stim_data, 'VariableNames', {'start_frame', 'end_frame'});
                        
         catch meCause
            meBase = MException('BOT:StimulusError', 'Could not read spontaneous stimulus from session.\nThe stimulus may not exist.');
            meBase.addCause(meCause);
            throw(meBase);
         end
      end
      
      function cStimuli = list_stimuli(bos)
         % list_stimuli - METHOD Return the list of stimuli used in this experimental session
         %
         % Usage: cStimuli = list_stimuli(bos)

         % - Get local NWB file
         bos.EnsureCached();
         nwb_file = bos.strLocalNWBFileLocation;
         
         % - Get list of stimuli from NWB file
         strKey = fullfile(filesep, 'stimulus', 'presentation');
         sKeys = h5info(nwb_file, strKey);
         [~, cStimuli]= cellfun(@fileparts, {sKeys.Groups.Name}, 'UniformOutput', false);
         
         % - Remove trailing "_stimulus"
         cStimuli = cellfun(@(s)strrep(s, '_stimulus', ''), cStimuli, 'UniformOutput', false);
      end
      
      function strSessionType = get_session_type(bos)
         % get_session_type - METHOD Return the name for the stimulus set used in this session
         strSessionType = bos.sSessionInfo.stimulus_name;
      end
      
      function tStimEpochs = get_stimulus_epoch_table(bos)
         % get_stimulus_epoch_table - METHOD Return the stimulus epoch table for this experimental session
         %
         % Usage: tStimEpochs = get_stimulus_epoch_table(bos)
         
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
               tThisStimulus.frame = 0;
            end
            
            % - Get epochs for this stimulus
            cvnTheseEpochs = get_epoch_mask_list(tThisStimulus, sThresholds.(bos.get_session_type()));
            tTheseEpochs = array2table(vertcat(cvnTheseEpochs{:}), 'VariableNames', {'start_frame', 'end_frame'});
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
                  
      %% - In progress

      
      %% -- Not yet implemented
            
      
      function [template, off_screen_mask] = get_locally_sparse_noise_stimulus_template(bos, strStimulus, bMaskOffScreen)
         % get_locally_sparse_noise_stimulus_template - METHOD Return the locally sparse noise stimulus template used for this sessions
         %
         % Usage: [template, off_screen_mask] = get_locally_sparse_noise_stimulus_template(bos, strStimulus, bMaskOffScreen)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function mfMaxProjection = get_max_projection(bos)
         % get_max_projection - METHOD Return the maximum-intensity projection image for this experimental session
         %
         % Usage: mfMaxProjection = get_max_projection(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function mfShift = get_motion_correction(bos)
         % get_motion_correction - METHOD Return the motion correction information for this experimental session
         %
         % Usage: mfShift = get_motion_correction(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      
      function [vtTimestamps, mfPupilLocation] = get_pupil_location(bos, bAsSpherical)
         % get_pupil_location - METHOD Return the pupil location trace for this experimental session
         %
         % Usage: [vtTimestamps, mfPupilLocation] = get_pupil_location(bos, <bAsSpherical>)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [vtTimestamps, vfPupilAreas] = get_pupil_size(bos)
         % get_pupil_size - METHOD Return the pupil area trace for this experimental session
         %
         % Usage: [vtTimestamps, vfPupilAreas] = get_pupil_size(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vnROIIDs = get_roi_ids(bos)
         % get_roi_ids - METHOD Return the list of ROI IDs for this experimental session
         %
         % Usage: vnROIIDs = get_roi_ids(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function tfROIMasks = get_roi_mask_array(bos, vnCellSpecimenIDs)
         % get_roi_mask_array - METHOD Return the ROI mask for the provided cell specimen IDs
         %
         % Usage: tfROIMasks = get_roi_mask_array(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function [vtTimestamps, vfRunningSpeed] = get_running_speed(bos)
         % get_running_speed - METHOD Return running speed in cm/s
         %
         % Usage: [vtTimestamps, vfRunningSpeed] = get_running_speed(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function stimulus = get_stimulus(bos, vnFrameIndex)
         % get_stimulus - METHOD Retrun the stimulus for the provided frame indices
         %
         % Usage: stimulus = get_stimulus(bos, vnFrameIndex)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function tStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         % get_stimulus_template - METHOD Return the stimulus template for the provided stimulus
         %
         % Usage: tStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
   end

   %% - Unimplemented API methods
   methods (Hidden = true)
      function varargout = get_roi_mask(varargin) %#ok<STOUT>
         % get_roi_mask - UNIMPLEMENTED METHOD - Use method get_roi_mask_array()
         BBS_ERR_NOT_IMPLEMENTED('Use method get_roi_mask_array()');
      end
   end
   
end

%% - Private utility functions

function stimulus_table = get_abstract_feature_series_stimulus_table(nwb_file, stimulus_name)
	% get_abstract_feature_series_stimulus_table - FUNCTION Return a stimlus table for an abstract feature series stimulus

   % - Build a key for this stimulus
   strKey = fullfile(filesep, 'stimulus', 'presentation', stimulus_name);
   
   % - Read and convert stimulus data from the NWB file
   try
      % - Read data from the NWB file
      stim_data = h5read(nwb_file, fullfile(strKey, 'data'));
      features = deblank(h5read(nwb_file, fullfile(strKey, 'features')));
      frame_dur = h5read(nwb_file, fullfile(strKey, 'frame_duration'));
      
      % - Create a stimulus table to return
      stimulus_table = array2table(stim_data', 'VariableNames', features);
      
      % - Add start and finish frame times
      stimulus_table.start_frame = int64(frame_dur(1, :)');
      stimulus_table.end_frame = int64(frame_dur(2, :)');
      
   catch meCause
      meBase = MException('BOT:StimulusError', ...
         'Could not read stimulus [%s] from session.\nThe stimulus may not exist.', stimulus_name);
      meBase.addCause(meCause);
      throw(meBase);
   end
end

function stimulus_table = get_indexed_time_series_stimulus_table(nwb_file, stimulus_name)
   % get_indexed_time_series_stimulus_table - FUNCTION Return a stimlus table for an indexed time series stimulus

   % - Build a key for this stimulus
   strKey = fullfile(filesep, 'stimulus', 'presentation', stimulus_name);
   
   % - Attempt to read data from this key, otherwise correct
   try
      h5info(nwb_file, strKey);
   catch
      strKey = fullfile(filesep, 'stimulus', 'presentation', [stimulus_name '_stimulus']);
   end
   
   % - Read and convert stimulus data from the NWB file
   try
      % - Read data from the NWB file
      inds = h5read(nwb_file, fullfile(strKey, 'data'));
      frame_dur = h5read(nwb_file, fullfile(strKey, 'frame_duration'));
      
      % - Create a stimulus table to return
      stimulus_table = array2table(inds, 'VariableNames', {'frame'});
      
      % - Add start and finish frame times
      stimulus_table.start_frame = int32(frame_dur(1, :)');
      stimulus_table.end_frame = int32(frame_dur(2, :)');
      
   catch meCause
      meBase = MException('BOT:StimulusError', 'Could not read stimulus [%s] from session.\nThe stimulus may not exist.');
      meBase.addCause(meCause);
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
   for nStimulus = 1:numel(vnUniqueStims)
      stimulus_table{cvnRepeatIndices{nStimulus}, 'repeat'} = (1:numel(cvnRepeatIndices{nStimulus}))' - 1;
   end
   
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
      max_cuts = 2;
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


%% - Functions to return errors and warnings about unimplemented methods

function BBS_ERR_NOT_IMPLEMENTED(strAlternative)
% BBS_ERR_NOT_IMPLEMENTED - FUNCTION Throw an error indicating this method is not implemented
%
% Usage: BBS_ERR_NOT_IMPLEMENTED(strAlternative)
error('BOT:UnimplementedAPIMethod', ...
      'This API method is not implemented.\nAlternative: %s', strAlternative);
end

function BBS_WARN_NOT_YET_IMPLEMENTED()
% BBS_WARN_NOT_YET_IMPLEMENTED - FUNCTION Raise a warning indicating this method is not yet implemented
%
% Usage: BBS_WARN_NOT_YET_IMPLEMENTED()
warning('BOT:UnimplementedAPIMethod', ...
      'This API method is not yet implemented.');
end
