%% Test class for BOT
classdef test < matlab.unittest.TestCase
   
   %% Test methods block
   methods (Test)
      function testCreateCache(testCase) %#ok<*MANU>
         %% Test creating a BOT cache
         boc = bot.cache; %#ok<*NASGU>
      end
      
      function testGetTables(testCase)
         %% Test retrieving all OPhys and ECEPhys manifest tables
         boc = bot.cache;
         boc.tOPhysSessions;                   % Table of all OPhys experimental sessions
         boc.tOPhysContainers;                 % Table of all OPhys experimental containers
         boc.tECEPhysSessions;                 % Table of all ECEPhys experimental sessions
         boc.tECEPhysChannels;                 % Table of all ECEPhys channels
         boc.tECEPhysProbes;                   % Table of all ECEPhys probes
         boc.tECEPhysUnits;                    % Table of all ECEPhys units
      end
      
      function testGetSessionFilter(testCase)
         %% Test creating a session filter object
         bosf = bot.sessionfilter;
         bosf.clear_filters();
      end
      
      function testSessionFilterGetAllMethods(testCase)
         %% Test the "get all" methods for the session filter class
         bosf = bot.sessionfilter;
         
         bosf.get_all_cre_lines();
         bosf.get_all_imaging_depths();
         bosf.get_all_session_types();
         bosf.get_all_stimuli();
         bosf.get_all_targeted_structures();
      end
      
      function testSessionFilterGetSummaryMethods(testCase)
         %% Test the "get summary" methods for the session filter class
         bosf = bot.sessionfilter;
         
         bosf.get_summary_of_containers_along_depths_and_structures();
         bosf.get_summary_of_containers_along_imaging_depths();
         bosf.get_summary_of_containers_along_targeted_structures();
         bosf.get_targeted_structure_acronyms();
         bosf.get_total_num_of_containers();
      end
      
      function testSessionFilterMethods(testCase)
         %% Test using the session filter filtering methods
         boc = bot.cache;
         bosf = bot.sessionfilter;
         
         % CRE lines
         cre_lines = bosf.get_all_cre_lines();
         bosf.clear_filters();
         bosf.filter_session_by_cre_line(cre_lines{1});

         % Imaging depth
         im_depths = bosf.get_all_imaging_depths();
         bosf.clear_filters();
         bosf.filter_sessions_by_imaging_depth(im_depths(1));
         
         % Eye tracking
         bosf.clear_filters();
         bosf.filter_session_by_eye_tracking(true);
         
         % Container ID
         tContainers = boc.tAllContainers;
         bosf.clear_filters();
         bosf.filter_sessions_by_container_id(tContainers{1, 'id'});
         
         % Session ID
         tSessions = boc.tAllSessions;
         bosf.clear_filters();
         bosf.filter_sessions_by_session_id(tSessions{1, 'id'});
         
         % Session type
         session_types = bosf.get_all_session_types();
         bosf.clear_filters();
         bosf.filter_sessions_by_session_type(session_types{1});
         
         % Stimuli
         stimuli = bosf.get_all_stimuli();
         bosf.clear_filters();
         bosf.filter_sessions_by_stimuli(stimuli{1});
         
         % Targeted structures
         structures = bosf.get_all_targeted_structures();
         bosf.clear_filters();
         bosf.filter_sessions_by_targeted_structure(structures{1});
         
         % Get filtered session table
         bosf.filter_sessions_by_targeted_structure(structures{1});
         t = bosf.filtered_session_table;
      end
      
      function testObtainSessionObject(testCase)
         %% Test creation of a session object
         bosf = bot.sessionfilter();
         
         % - Get session IDs
         vIDs = bosf.valid_session_table{:, 'id'};
         
         % - Create some bot.session objects
         bot.session(vIDs(1));
         bot.session(vIDs(1:2));
         bot.session(bosf.valid_session_table(1, :));
      end
      
      function testCacheSessionObject(testCase)
         %% Test obtaining a session object data from the cache
         % - Create a bot.session object
         s = bot.session(704298735);
         
         % - Ensure the data is in the cache
         s.EnsureCached();
      end
      
      function testSessionDataAccess(testCase)
         %% Test data access methods of the bot.session class
         % - Create a bot.session object
         s = bot.session(528402271);

         % - Test summary methods
         vnCellIDs = s.get_cell_specimen_ids();
         s.get_cell_specimen_indices(vnCellIDs);
         s.get_metadata();
         s.get_session_type();
         s.get_roi_ids();
         s.list_stimuli();
         
         % - Test data access methods
         s.get_fluorescence_timestamps();
         s.get_fluorescence_traces();
         s.get_demixed_traces();
         s.get_corrected_fluorescence_traces();
         s.get_dff_traces();
         s.get_max_projection();
         s.get_motion_correction();
         s.get_neuropil_r();
         s.get_neuropil_traces();
         s.get_roi_mask();
         s.get_roi_mask_array();
         s.get_running_speed();
         s.get_pupil_location();
         s.get_pupil_size();
      end
      
      function testStimulusExtraction(testCase)
         %% Test OPhys session stimulus extraction methods
         % - Create a bot.session object
         s = bot.session(528402271);

         % - Get a vector of fluorescence frame IDs
         vnFrameIDs = 1:numel(s.get_fluorescence_timestamps());
         
         % - Obtain per-frame stimulus table
         s.get_stimulus(vnFrameIDs);
         
         % - Obtain stimulus summary table
         s.get_stimulus_epoch_table();
         
         % - Get list of stimuli
         cStimuli = s.list_stimuli();
         
         % - Get a stimulus table for each stimulus
         for cThisStim = cStimuli
            s.get_stimulus_table(cThisStim{1});
         end
         
         % - Get a natural movie stimulus template
         s.get_stimulus_template('natural_movie_one');
         
         % - Get a spontantaneous activity stimulus table
         s.get_spontaneous_activity_stimulus_table();
         
         % - Get a session with sparse noise
         s = bot.session(566752133);
         
         % - Get the sparse noise stimulus template
         s.get_stimulus_template('locally_sparse_noise_4deg');
         s.get_locally_sparse_noise_stimulus_template('locally_sparse_noise_4deg');
      end
      
      function testCache(testCase)
         %% - Get a cache object, for a temporary directory
         boc = bot.cache(tempdir);
         
         % - Ensure the manifests are refreshed
         boc.UpdateManifests();
         
         % - Download files for a session
         boc.CacheFilesForSessionIDs(566752133);
      end
   end
end