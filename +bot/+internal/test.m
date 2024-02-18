%% Test class for BOT
classdef test < matlab.unittest.TestCase
   
    % Todo: 
    % [ ] set up test cache...
    % [ ] test live scripts

   %% Test methods block
   methods (Test)
      function testCreateCache(testCase) %#ok<*MANU>
         %% Test creating a BOT cache
         boc = bot.internal.Cache.instance(); %#ok<*NASGU>
      end
      
      function testOphysTables(testCase)
         %% Test retrieving all OPhys manifest tables
         bom = bot.item.internal.Manifest.instance('ophys');
         bom = bot.item.internal.OphysManifest.instance();
         bom.ophys_sessions;                   % Table of all OPhys experimental sessions
         bom.ophys_experiments;                % Table of all OPhys experimental containers
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

      function testObtainSessionObject(testCase)
         %% Test creation of an OPhys session object
         sess = bot.listSessions('VisualCoding', 'ophys');
         
         % - Get session IDs
         vIDs = sess.id;
         
         % - Create some bot.item.Session objects
         bot.getSessions(vIDs(1));
         bot.getSessions(vIDs(1:3));
         bot.getSessions(sess(1, :));
         bot.getSessions(sess(1:3, :));

         % - Fetch all sessions from one experiment
         exps = bot.listExperiments();
         s = bot.getSessions(sess(sess.experiment_container_id == exps.id(1), :));
      end
      
      function testSessionDataAccess(testCase)
         %% Test data access methods of the bot.item.Session class for OPhys data
         % - Create a bot.item.Session object
         s = bot.getSessions(496934409);

         % - Test summary methods
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
         s = bot.getSessions(528402271);

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
         s = bot.getSessions(566752133);
         
         % - Get the sparse noise stimulus template
         s.getStimulusTemplate('locally_sparse_noise_4deg');
      end      
      
      function testOPhysExperiment(testCase)
          %% Test obtaining OPhys experiment object
          exp_table = bot.listExperiments();
          exp = bot.getExperiments(exp_table.id(1));
          exp = bot.getExperiments(exp_table(1, :));
          exps = bot.getExperiments(exp_table.id(1:3));
          exps = bot.getExperiments(exp_table(1:3, :));
      end
      
      function testOPhysCell(testCase)
          %% Test obtaining OPhys cell object
          cell_table = bot.listCells('VisualCoding', true);
          cell_table = bot.listCells('VisualCoding', false);
          cell = bot.getCells(cell_table.id(1));
          cell = bot.getCells(cell_table(1, :));
          cells = bot.getCells(cell_table(1:3, :));
          cells = bot.getCells(cell_table.id(1:3));

          assert(~isempty(fieldnames(cells(1).metrics)), '`metrics` property structure was not set properly')
      end
      
      function testEPhysManifest(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.EphysManifest.instance();
         bom = bot.item.internal.Manifest.instance('ephys');
      end
      
      function test_ophys_cells(testCase)
          %% Tect obtaining OPhys cells
          cells = bot.listCells();
          c = bot.getCells(cells(1, :));
          c = bot.getCells(cells.id(1));
          c = bot.getCells(cells(1:3, :));
      end

      function test_ephys_sessions(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the EPhys sessionts
         sessions = bot.listSessions('VisualCoding', 'ephys');
         
         % - Get a session
         s = bot.getSessions(sessions{1, 'id'});
         s = bot.getSessions(sessions(1, :));
         s = bot.getSessions(sessions{1:3, 'id'});
         s = bot.getSessions(sessions(1:3, :));
      end

      function test_ephys_probes(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the probes table
         probes = bot.listProbes();

         % - Get a probe, by ID and by table
         p = bot.getProbes(probes{1, 'id'});
         p = bot.getProbes(probes(1, :));
         p = bot.getProbes(probes{1:3, 'id'});
         p = bot.getProbes(probes(1:3, :));
      end

      function test_ephys_channels(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the channels table
         channels = bot.listChannels();

         % - Get channels, by ID and by table
         c = bot.getChannels(channels{1, 'id'});
         c = bot.getChannels(channels(1, :));
         c = bot.getChannels(channels{1:3, 'id'});
         c = bot.getChannels(channels(1:3, :));
      end

      function test_ephys_units(testCase)
         %% Test obtaining EPhys units objects
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get the units table
         units = bot.listUnits('VisualCoding', true);
         units = bot.listUnits('VisualCoding', false);

         % - Get units, by ID and by table
         u = bot.getUnits(units{1, 'id'});
         u = bot.getUnits(units(1, :));
         u = bot.getUnits(units{1:3, 'id'});
         u = bot.getUnits(units(1:3, :));
         
         assert(~isempty(fieldnames(u(1).metrics)), '`metrics` property structure was not set properly')
      end
      
      function testLFPCSDExtraction(testCase)
         %% Test LFP and CSD extraction
         % - Get the EPhys manifest
         bom = bot.item.internal.Manifest.instance('ephys');

         % - Get a probe
         p = bot.getProbes(bom.ephys_probes{1, 'id'});
         
         % - Access LFP data
         p.lfpData;
         
         % - Access CSD data
         p.csdData;
      end
      
      function test_ephys_lazy_attributes(testCase)
         %% Test reading lazy attributes
         bom = bot.item.internal.Manifest.instance('ephys');
         s = bot.getSessions(bom.ephys_sessions{1, 'id'});
         
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
         s = bot.getSessions(bom.ephys_sessions{1, 'id'});

         sess = bot.listSessions('VisualCoding', 'ephys');
         s = bot.getSessions(sess(1, :));

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
         exps = bot.listExperiments();
         sess_ephys = bot.listSessions('VisualCoding', 'ephys');
         sess_ophys = bot.listSessions('VisualCoding', 'ophys');
         units = bot.listUnits();
         units = bot.listUnits('VisualCoding', true);
         probes = bot.listProbes();
         channels = bot.listChannels();
         cells = bot.listCells();
         cells = bot.listCells('VisualCoding', true);
         
         % - Test "get object" factory functions
         bot.getSessions(sess_ephys{1, 'id'});
         bot.getSessions(sess_ophys{1, 'id'});
         bot.getExperiments(exps{1, 'id'});
         bot.getUnits(units{1, 'id'});
         bot.getProbes(probes{1, 'id'});
         bot.getChannels(channels{1, 'id'});
         bot.getCells(cells{1, 'id'});
      end

      function testFactoryFunctionsVisualBehavior(testCase)
         sess_ephys = bot.listSessions('VisualBehavior', 'ephys');
         sess_ophys = bot.listSessions('VisualBehavior', 'ophys');

         exps = bot.listExperiments('VisualBehavior');
         probes = bot.listProbes('VisualBehavior');
         channels = bot.listChannels('VisualBehavior');
         units = bot.listUnits('VisualBehavior', true);
         cells = bot.listCells('VisualBehavior', true);
         
         % - Test "get object" factory functions
         bot.getSessions(sess_ephys{1, 'id'});
         bot.getSessions(sess_ophys{1, 'id'});
         bot.getExperiments(exps{1, 'id'});
         bot.getUnits(units{1, 'id'});
         bot.getProbes(probes{1, 'id'});
         bot.getChannels(channels{1, 'id'});
         bot.getCells(cells{1, 'id'});
      end

      function testOphysQuickStart(testCase)
         captured = evalc('run(''OphysQuickstart.mlx'')');
         close all
      end
   end
end