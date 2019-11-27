%% Test class for BOT
classdef test < matlab.unittest.TestCase
   
   %% Test methods block
   methods (Test)
      function testCreateCache(testCase) %#ok<*MANU>
         %% Test creating a BOT cache
         boc = bot.cache; %#ok<*NASGU>
      end
      
      function testGetTables(testCase)
         %% Test retrieving the OPhys experiment tables
         boc = bot.cache;
         tSessions = boc.tAllSessions;
         tContainers = boc.tAllContainers;
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
      end
   end
end