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
      


      
      %% -- Second priority
            
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
      
      function stimulusTable = get_spontaneous_activity_stimulus_table(bos)
         % get_spontaneous_activity_stimulus_table - METHOD Return the sponaneous activity stimulus table for this experimental session
         %
         % Usage: stimulusTable = get_spontaneous_activity_stimulus_table(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function stimulus = get_stimulus(bos, vnFrameIndex)
         % get_stimulus - METHOD Retrun the stimulus for the provided frame indices
         %
         % Usage: stimulus = get_stimulus(bos, vnFrameIndex)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function [vtTimestamps, tStimulusTable] = get_stimulus_epoch_table(bos)
         % get_stimulus_epoch_table - METHOD Return the stimulus epoch table for this experimental session
         %
         % Usage: [vtTimestamps, tStimulusTable] = get_stimulus_epoch_table(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function tStimulusTable = get_stimulus_table(bos, strStimulusName)
         % get_stimulus_table - METHOD Return the stimulus table for the provided stimulus
         %
         % Usage: tStimulusTable = get_stimulus_table(bos, strStimulusName)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function tStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         % get_stimulus_template - METHOD Return the stimulus template for the provided stimulus
         %
         % Usage: tStimulusTemplate = get_stimulus_template(bos, strStimulusName)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function cStimuli = list_stimuli(bos)
         % list_stimuli - METHOD Return the list of stimuli used in this experimental session
         %
         % Usage: cStimuli = list_stimuli(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
   end

   %% - Unimplemented API methods
   methods (Hidden = true)
      function varargout = get_roi_mask(varargin) %#ok<STOUT>
         % get_roi_mask - UNIMPLEMENTED METHOD - Use method get_roi_mask_array()
         BBS_ERR_NOT_IMPLEMENTED('Use method get_roi_mask_array()');
      end
      
%       function varargout = get_metadata(varargin) %#ok<STOUT>
%          % get_metadata - UNIMPLEMENTED METHOD - Access object properties instead
%          BBS_ERR_NOT_IMPLEMENTED('Access object properties instead');
%       end
      
      function varargout = get_session_type(varargin) %#ok<STOUT>
         % get_session_type - UNIMPLEMENTED METHOD - Access object properties instead
         BBS_ERR_NOT_IMPLEMENTED('Access object properties instead');
      end
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
