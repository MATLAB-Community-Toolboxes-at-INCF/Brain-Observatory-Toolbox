%% Test class for BOT
classdef test < matlab.unittest.TestCase
   
   %% Test methods block
   methods (Test)
      function testCreateCache(testCase) %#ok<*MANU>
         %% Test creating a BOT cache
         boc = bot.internal.cache; %#ok<*NASGU>
      end
      
      function testOphysTables(testCase)
         %% Test retrieving all OPhys manifest tables
         bom = bot.item.internal.Manifest.instance('ophys');
         bom = bot.item.internal.OphysManifest.instance();
         bom.ophys_sessions;                   % Table of all OPhys experimental sessions
         bom.ophys_experiments;                 % Table of all OPhys experimental containers
         bom.ophys_cells;                      % Table of all OPhys cells
      end
      
      function testEphysTables(testCase)
         %% Test retrieving EPhys manifest tables
         bom = bot.item.internal.Manifest.instance('ephys');
         bom = bot.item.internal.EphysManifest.instance();
         bom.ephys_sessions;                 % Table of all EPhys experimental sessions
         bom.ephys_channels;                 % Table of all EPhys channels
         bom.ephys_probes;                   % Table of all EPhys probes
         bom.ephys_units;                    % Table of all EPhys units
      end
      
      function testGetOPhysSessionFilter(testCase)
         %% Test creating a session filter object
         bosf = bot.util.ophyssessionfilter;
         bosf.clear_filters();
      end
      
      function testOphysSessionFilterGetAllMethods(testCase)
         %% Test the "get all" methods for the OPhys session filter class
         bosf = bot.util.ophyssessionfilter;
         
         bosf.get_all_cre_lines();
         bosf.get_all_imaging_depths();
         bosf.get_all_session_types();
         bosf.get_all_stimuli();
         bosf.get_all_targeted_structures();
      end
      
      function testOPhysSessionFilterGetSummaryMethods(testCase)
         %% Test the "get summary" methods for the OPhys session filter class
         bosf = bot.util.ophyssessionfilter;
         
         bosf.get_summary_of_containers_along_depths_and_structures();
         bosf.get_summary_of_containers_along_imaging_depths();
         bosf.get_summary_of_containers_along_targeted_structures();
         bosf.get_targeted_structure_acronyms();
         bosf.get_total_num_of_containers();
      end
      
      function testOPhysSessionFilterMethods(testCase)
         %% Test using the OPhys session filter filtering methods
         bom = bot.item.internal.OphysManifest.instance();
         bosf = bot.util.ophyssessionfilter;
         
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
         containers = bom.ophys_experiments;
         bosf.clear_filters();
         bosf.filter_sessions_by_container_id(containers{1, 'id'});
         
         % Session ID
         sessions_ = bom.ophys_sessions;
         bosf.clear_filters();
         bosf.filter_sessions_by_session_id(sessions_{1, 'id'});
         
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
         %% Test creation of an OPhys session object
         bosf = bot.util.ophyssessionfilter();
         
         % - Get session IDs
         vIDs = bosf.valid_session_table{:, 'id'};
         
         % - Create some bot.session objects
         bot.session(vIDs(1));
         bot.session(vIDs(1:3));
         bot.session(bosf.valid_session_table(1, :));
         bot.session(bosf.valid_session_table(1:3, :));
      end
      
      function testSessionDataAccess(testCase)
         %% Test data access methods of the bot.session class for OPhys data
         % - Create a bot.session object
         s = bot.session(496934409);

         % - Test summary methods
         vnCellIDs = s.cell_specimen_ids;
         s.nwb_metadata;
         s.session_type;
         s.roi_ids;
         s.stimulus_list;
         
         % - Test data access methods
         s.fluorescence_timestamps;
         s.fluorescence_traces;
         s.fluorescence_traces_demixed;
         s.fluorescence_traces_dff;
         s.corrected_fluorescence_traces;
         s.max_projection;
         s.motion_correction;
         s.neuropil_r;
         s.neuropil_traces;
         s.roi_mask;
         s.roi_mask_array;
         s.running_speed;
         s.pupil_location;
         s.pupil_size;
      end
      
      function testStimulusExtraction(testCase)
         %% Test OPhys session stimulus extraction methods
         % - Create a bot.session object
         s = bot.session(528402271);

         % - Get a vector of fluorescence frame IDs
         vnFrameIDs = 1:numel(s.fluorescence_timestamps);
         
         % - Obtain per-frame stimulus table
         s.getStimulusByFrame(vnFrameIDs);
         
         % - Obtain stimulus summary table
         s.stimulus_epoch_table;
         
         % - Get list of stimuli
         cStimuli = s.stimulus_list;
         
         % - Get a stimulus table for each stimulus
         for cThisStim = cStimuli
            s.getStimulusTable(cThisStim{1});
         end
         
         % - Get a natural movie stimulus template
         s.getStimulusTemplate('natural_movie_one');
         s.getStimulusTable('natural_movie_one');
         
         % - Get a spontantaneous activity stimulus table
         s.spontaneous_activity_stimulus_table;
         
         % - Get an OPhys session with sparse noise
         s = bot.session(566752133);
         
         % - Get the sparse noise stimulus template
         s.getStimulusTemplate('locally_sparse_noise_4deg');
      end      
      
      function testOPhysExperiment(testCase)
          %% Test obtaining OPhys experiment object
          exp_table = bot.fetchExperiments();
          exp = bot.experiment(exp_table.id(1));
          exp = bot.experiment(exp_table(1, :));
          exps = bot.experiment(exp_table.id(1:3));
          exps = bot.experiment(exp_table(1:3, :));
      end
      
      function testOPhysCell(testCase)
          %% Test obtaining OPhys cell object
          cell_table = bot.fetchCells(true);
          cell_table = bot.fetchCells(false);
          cell = bot.cell(cell_table.id(1));
          cell = bot.cell(cell_table(1, :));
          cells = bot.cell(cell_table(1:3, :));
          cells = bot.cell(cell_table.id(1:3));

          assert(~isempty(fieldnames(cells(1).metrics)), '`metrics` property structure was not set properly')
      end
      
      function testEPhysManifest(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.ephysmanifest.instance();
         bom = bot.item.internal.Manifest.instance('ephys');
      end
      
      function test_ephys_sessions(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the EPhys sessionts
         sessions = bot.fetchSessions('ephys');
         
         % - Get a session
         s = bot.session(sessions{1, 'id'});
         s = bot.session(sessions(1, :));
         s = bot.session(sessions{1:3, 'id'});
         s = bot.session(sessions(1:3, :));
      end

      function test_ephys_probes(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the probes table
         probes = bot.fetchProbes();

         % - Get a probe, by ID and by table
         p = bot.probe(probes{1, 'id'});
         p = bot.probe(probes(1, :));
         p = bot.probe(probes{1:3, 'id'});
         p = bot.probe(probes(1:3, :));
      end

      function test_ephys_channels(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the channels table
         channels = bot.fetchChannels();

         % - Get channels, by ID and by table
         c = bot.channel(channels{1, 'id'});
         c = bot.channel(channels(1, :));
         c = bot.channel(channels{1:3, 'id'});
         c = bot.channel(channels(1:3, :));
      end

      function test_ephys_units(testCase)
         %% Test obtaining EPhys units objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the units table
         units = bot.fetchUnits(true);
         units = bot.fetchUnits(false);

         % - Get units, by ID and by table
         u = bot.unit(units{1, 'id'});
         u = bot.unit(units(1, :));
         u = bot.unit(units{1:3, 'id'});
         u = bot.unit(units(1:3, :));
         
         assert(~isempty(fieldnames(u(1).metrics)), '`metrics` property structure was not set properly')
      end
      
      function testLFPCSDExtraction(testCase)
         %% Test LFP and CSD extraction
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get a probe
         p = bot.probe(bom.ephys_probes{1, 'id'});
         
         % - Access LFP data
         p.lfpData;
         
         % - Access CSD data
         p.csdData;
      end
      
      function test_ephys_lazy_attributes(testCase)
         %% Test reading lazy attributes
         bom = bot.item.internal.Manifest.instance('ephys');
         s = bot.session(bom.ephys_sessions{1, 'id'});
         
         s.mean_waveforms;
         s.optogenetic_stimulation_epochs;
         s.inter_presentation_intervals;
         s.running_speed;
         s.mean_waveforms;
         s.stimulus_presentations;
         s.stimulus_conditions;
         s.session_start_time;
         s.spike_amplitudes;
         s.invalid_times;
      
         % s.num_stimulus_presentations; % Not currently implemented, since it requires access to full stimulus table
         s.stimulus_names;
         s.structure_acronyms;
         s.structurewise_unit_counts;
      
         s.stimulus_templates;
         
         try
            s.optogenetic_stimulation_epochs;
         catch
            warning('No optogenetic stimulation data was present for this session.');
         end
      end
      
      function test_ephys_session_methods(testCase)
         %% Test session data access methods
         bom = bot.item.internal.Manifest.instance('ephys');
         s = bot.session(bom.ephys_sessions{1, 'id'});

         sess = bot.fetchSessions('ephys');
         s = bot.session(sess(1, :));

         s.fetch_stimulus_table();
         s.getStimulusEpochsByDuration();
         uid = s.units{1, 'id'};
         s.getPresentationwiseSpikeCounts([0 1], 1, uid);
         s.getPresentationwiseSpikeTimes(0, uid);
         s.getConditionwiseSpikeStatistics(0, uid);
         s.getConditionsByStimulusName("spontaneous");
      end
      
      function test_factory_functions(testCase)
         %% - Test manifest fetch factory functions
         exps = bot.fetchExperiments();
         sess_ephys = bot.fetchSessions('ephys');
         sess_ophys = bot.fetchSessions('ophys');
         units = bot.fetchUnits();
         units = bot.fetchUnits(true);
         probes = bot.fetchProbes();
         channels = bot.fetchChannels();
         cells = bot.fetchCells();
         cells = bot.fetchCells(true);
         
         % - Test "get object" factory functions
         bot.session(sess_ephys{1, 'id'});
         bot.session(sess_ophys{1, 'id'});
         bot.experiment(exps{1, 'id'});
         bot.unit(units{1, 'id'});
         bot.probe(probes{1, 'id'});
         bot.channel(channels{1, 'id'});
         bot.cell(cells{1, 'id'});
      end
   end
end