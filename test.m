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
         bom = bot.internal.manifest.instance('ophys');
         bom = bot.internal.ophysmanifest.instance();
         bom.ophys_sessions;                   % Table of all OPhys experimental sessions
         bom.ophys_containers;                 % Table of all OPhys experimental containers
      end
      
      function testEphysTables(testCase)
         %% Test retrieving EPhys manifest tables
         bom = bot.internal.manifest.instance('ephys');
         bom = bot.internal.ephysmanifest.instance();
         bom.ephys_sessions;                 % Table of all EPhys experimental sessions
         bom.ephys_channels;                 % Table of all EPhys channels
         bom.ephys_probes;                   % Table of all EPhys probes
         bom.ephys_units;                    % Table of all EPhys units
      end
      
      
      
      function testObtainSessionObject(testCase)
         %% Test creation of an OPhys session object
         bosf = bot.fetchSessions('ophys');
         
         % - Get session IDs
         vIDs = bosf{:, 'id'};
         
         % - Create some bot.item.concrete.OphysSession objects
         bot.item.concrete.OphysSession(vIDs(1));
      end
      
      
      
      function testCacheSessionObject(testCase)
         %% Test obtaining an OPhys session object data from the cache
         % - Create a bot.item.ophyssession object
         s = bot.item.concrete.OphysSession(704298735);
         
         % - Ensure the data is in the cache
         % s.EnsureCached();
      end
      
      function testSessionDataAccess(testCase)
         %% Test data access methods of the bot.item.ophyssession class for OPhys data
         % - Create a bot.item.ophyssession object
         s = bot.item.concrete.OphysSession(496934409);

         % - Test summary methods
         s.nwb_metadata;
         s.session_type;
         s.roi_ids;
         s.stimulus_list;
         
         % - Test data access methods
         s.fluorescence_timestamps;
         s.fluorescence_traces;
         s.fluorescence_traces_demixed;
         s.corrected_fluorescence_traces;
         s.fluorescence_traces_dff;
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
         % - Create a bot.item.ophyssession object
         s = bot.item.concrete.OphysSession(528402271);

         % - Get a vector of fluorescence frame IDs
         vnFrameIDs = 1:numel(s.fluorescence_timestamps);
         
         % - Obtain per-frame stimulus table
         % s.fetch_stimulus(vnFrameIDs);
         
         % - Obtain stimulus summary table
         s.stimulus_epoch_table;
         
         % - Get list of stimuli
         cStimuli = s.stimulus_list;
         
         % - Get a stimulus table for each stimulus
         %for cThisStim = cStimuli
         %   s.fetch_stimulus_table(cThisStim{1});
         %end
         
         % - Get a natural movie stimulus template
         getStimulusTemplate(s, 'natural_movie_one');
         getStimulusTable(s,'natural_movie_one');
         
         % - Get a spontantaneous activity stimulus table
         s.spontaneous_activity_stimulus_table;
         
         % - Get an OPhys session with sparse noise
         %s = bot.item.concrete.OphysSession(566752133);
         
         % - Get the sparse noise stimulus template
         % getStimulusTemplate(s,'locally_sparse_noise_4deg');
         % s.fetch_locally_sparse_noise_stimulus_template('locally_sparse_noise_4deg');
      end      
      
      function testEPhysManifest(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.internal.ephysmanifest.instance();
         bom = bot.internal.manifest.instance('ephys');
      end
      
      function test_ephys_sessions(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.internal.manifest.instance('ephys');
         
         % - Get a session
         s = bot.session(bom.ephys_sessions{1, 'id'});
         s = bot.session(bom.ephys_sessions(1, :));
      end

      function test_ephys_probes(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.internal.manifest.instance('ephys');

         % - Get a probe, by ID and by table
         p = bot.probe(bom.ephys_probes{1, 'id'});
         p = bot.probe(bom.ephys_probes(1, :));
         %p = bot.probe(bom.ephys_probes{[1, 2], 'id'});
      end

      function test_ephys_channels(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.internal.manifest.instance('ephys');

         % - Get channels, by ID and by table
         c = bot.channel(bom.ephys_channels{1, 'id'});
         c = bot.channel(bom.ephys_channels(1, :));
         %c = bot.channel(bom.ephys_channels{[1, 2], 'id'});
      end

      function test_ephys_units(testCase)
         %% Test obtaining EPhys objects
         % - Get the EPhys manifest
         bom = bot.internal.manifest.instance('ephys');

         % - Get units, by ID and by table
         u = bot.unit(bom.ephys_units{1, 'id'});
         u = bot.unit(bom.ephys_units(1, :));
         %u = bot.unit(bom.ephys_units{[1, 2], 'id'});
      end

      function testLFPCSDExtraction(testCase)
         %% Test LFP and CSD extraction
         % - Get the EPhys manifest
         bom = bot.internal.manifest.instance('ephys');

         % - Get a probe
         p = bot.probe(bom.ephys_probes{1, 'id'});
         
         % - Access LFP data
         p.lfpData;
         
         % - Access CSD data
         p.csdData;
      end
      
      function test_lazy_attributes(testCase)
         %% Test reading lazy attributes
         bom = bot.internal.manifest.instance('ephys');
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
      
         %s.num_stimulus_presentations;
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
         bom = bot.internal.manifest.instance('ephys');
         s = bot.session(bom.ephys_sessions{1, 'id'});

         %s.fetch_stimulus_table();
         %s.fetch_parameter_values_for_stimulus("flashes");
         %s.fetch_stimulus_parameter_values();
         
         uid = s.units{1, 'id'};
         s.getPresentationwiseSpikeCounts([0 1], 1, uid);
         s.getPresentationwiseSpikeTimes(0, uid);
      end
      
      function test_factory_functions(testCase)
         %% - Test manifest fetch factory functions
         exps = bot.fetchExperiments();
         sess_ephys = bot.fetchSessions('ephys');
         sess_ophys = bot.fetchSessions('ophys');
         units = bot.fetchUnits();
         probes = bot.fetchProbes();
         channels = bot.fetchChannels();
         
         % - Test "get object" factory functions
         bot.session(sess_ephys{1, 'id'});
         bot.session(sess_ophys{1, 'id'});
         %bot.experiment(exps{1, 'id'});
         bot.unit(units{1, 'id'});
         bot.probe(probes{1, 'id'});
         bot.channel(channels{1, 'id'});
      end
   end
end