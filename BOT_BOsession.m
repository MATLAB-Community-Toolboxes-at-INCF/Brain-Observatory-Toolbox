% BOT_BOsession - CLASS Represent an experimental container from the Allen Brain Observatory
%
% 

classdef BOT_BOsession
   
   %% - Public properties
   properties (SetAccess = private)
   end
   
   %% - Private properties
   properties (Hidden = true, SetAccess = private)
      bocCache = BOT_cache();
   end
   
   %% - Constructor
   methods
      function bsObj = BOT_BOsession(varargin)
         % BOT_BOsession - CONSTRUCTOR Construct an object containing a Brain Observatory experimental sesion
         %
         % Usage: bsObj = BOT_BOsession(nSessionID)
         %        vbsObj = BOT_BOsession(vnSessionIDs)
         %        bsObj = BOT_BOsession(tSessionRow)
      end
   end
   
   
   %% - Allen BO data set API
   methods (Hidden = false)
      function vnCellSpecimenIDs = get_cell_specimen_ids()
         % get_cell_specimen_ids - METHOD Return all cell specimen IDs in this session
         %
         % Usage: vnCellSpecimenIDs = get_cell_specimen_ids()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vnCellSpecimenIndices = get_cell_specimen_indices(vnCellSpecimenIDs)
         % get_cell_specimen_indices - METHOD Return indices corresponding to provided cell specimen IDs
         %
         % Usage: vnCellSpecimenIndices = get_cell_specimen_indices(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_corrected_fluorescence_traces(vnCellSpecimenIDs)
         % get_corrected_fluorescence_traces - METHOD Return corrected fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_corrected_fluorescence_traces(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_demixed_traces(vnCellSpecimenIDs)
         % get_demixed_traces - METHOD Return neuropil demixed fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_demixed_traces(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfdFF] = get_dff_traces(vnCellSpecimenIDs)
         % get_dff_traces - METHOD Return dF/F traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_dff_traces(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vtTimestamps = get_fluorescence_timestamps()
         % get_fluorescence_timestamps - METHOD Return timestamps for the fluorescence traces
         %
         % Usage: vtTimestamps = get_fluorescence_timestamps()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_fluorescence_traces(vnCellSpecimenIDs)
         % get_fluorescence_traces - METHOD Return raw fluorescence traces for the provided cell specimen IDs
         %
         % Usage: [mtTimestamps, mfTraces] = get_fluorescence_traces(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [template, off_screen_mask] = get_locally_sparse_noise_stimulus_template(strStimulus, bMaskOffScreen)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function mfMaxProjection = get_max_projection()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function mfShift = get_motion_correction()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vfR = get_neuropil_r(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [mtTimestamps, mfTraces] = get_neuropil_traces(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function [vtTimestamps, mfPupilLocation] = get_pupil_location(bAsSpherical)
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vfPupilSize = get_pupil_size()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function vnROIIDs = get_roi_ids()
         BBS_WARN_NOT_YET_IMPLEMENTED()
      end
      
      function tfROIMasks = get_roi_mask_array(vnCellSpecimenIDs)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function [vtTimestamps, vfRunningSpeed] = get_running_speed()
         % get_running_speed - METHOD Return running speed in cm/s
         %
         % Usage: [vtTimestamps, vfRunningSpeed] = get_running_speed()
      end
      
      function stimulusTable = get_spontaneous_activity_stimulus_table()
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function stimulus = get_stimulus(vnFrameIndex)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function [vtTimestamps, tStimulusTable] = get_stimulus_epoch_table()
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function tStimulusTable = get_stimulus_table(strStimulusName)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function tStimulusTemplate = get_stimulus_template(strStimulusName)
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
      
      function cStimuli = list_stimuli()
         BBS_WARN_NOT_YET_IMPLEMENTED();
      end
   end

   %% - Unimplemented API methods
   methods (Hidden = true)
      function varargout = get_roi_mask(varargin)
         % get_roi_mask - UNIMPLEMENTED METHOD - Use method get_roi_mask_array()
         BBS_ERR_NOT_IMPLEMENTED('Use method get_roi_mask_array()');
      end
      
      function varargout = get_metadata(varargin)
         % get_metadata - UNIMPLEMENTED METHOD - Access object properties instead
         BBS_ERR_NOT_IMPLEMENTED('Access object properties instead');
      end
      
      function varargout = get_session_type(varargin)
         % get_session_type - UNIMPLEMENTED METHOD - Access object properties instead
         BBS_ERR_NOT_IMPLEMENTED('Access object properties instead');
      end
   end
   
end

%% - Functions to return errors and warnings about unimplemented methods

function BBS_ERR_NOT_IMPLEMENTED(strAlternative)
error('BOT:UnimplementedAPIMethod', ...
      'This API method is not implemented.\nAlternative: %s', strAlternative);
end

function BBS_WARN_NOT_YET_IMPLEMENTED()
warning('BOT:UnimplementedAPIMethod', ...
      'This API method is not yet implemented.');
end
