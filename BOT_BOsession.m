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
   
   methods
      function bNWBFileIsCached = IsNWBFileCached(bos)
         % IsNWBFileCached - METHOD Check if the NWB file corresponding to this session is already cached
         %
         % Usage: bNWBFileIsCached = IsNWBFileCached(bos)
         bNWBFileIsCached =  bos.bocCache.IsInCache([bos.bocCache.strABOBaseUrl bos.sSessionInfo.well_known_files.download_link]);
      end
      
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
      function vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         % get_cell_specimen_ids - METHOD Return all cell specimen IDs in this session
         %
         % Usage: vnCellSpecimenIDs = get_cell_specimen_ids(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         % get_cell_specimen_indices - METHOD Return indices corresponding to provided cell specimen IDs
         %
         % Usage: vnCellSpecimenIndices = get_cell_specimen_indices(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_corrected_fluorescence_traces(bos, vnCellSpecimenIDs)
         % get_corrected_fluorescence_traces - METHOD Return corrected fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_corrected_fluorescence_traces(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_demixed_traces(bos, vnCellSpecimenIDs)
         % get_demixed_traces - METHOD Return neuropil demixed fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_demixed_traces(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfdFF] = get_dff_traces(bos, vnCellSpecimenIDs)
         % get_dff_traces - METHOD Return dF/F traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_dff_traces(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vtTimestamps = get_fluorescence_timestamps(bos)
         % get_fluorescence_timestamps - METHOD Return timestamps for the fluorescence traces
         %
         % Usage: vtTimestamps = get_fluorescence_timestamps(bos)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_fluorescence_traces(bos, vnCellSpecimenIDs)
         % get_fluorescence_traces - METHOD Return raw fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_fluorescence_traces(bos, vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
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
      
      function vfR = get_neuropil_r(bos, vnCellSpecimenIDs)
         % get_neuropil_r - METHOD Return the neuropil correction variance explained for the provided cell specimen IDs
         %
         % Usage: vfR = get_neuropil_r(bos, <vnCellSpecimenIDs>)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_neuropil_traces(bos, vnCellSpecimenIDs)
         % get_neuropil_traces - METHOD Return the neuropil traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_neuropil_traces(bos, vnCellSpecimenIDs)
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
      
      function varargout = get_metadata(varargin) %#ok<STOUT>
         % get_metadata - UNIMPLEMENTED METHOD - Access object properties instead
         BBS_ERR_NOT_IMPLEMENTED('Access object properties instead');
      end
      
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