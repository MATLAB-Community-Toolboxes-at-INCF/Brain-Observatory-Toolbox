%% CLASS bot.ecephyssession - Encapsulate and provide data access to an ECEPhys session dataset from the Allen Brain Observatory



classdef ecephyssession < bot.session
   %% Properties
   properties
      num_units
      num_probes
      num_channels
      num_stimulus_presentations
      stimulus_names
      stimulus_conditions
      rig_geometry_data
      rig_equipment_name
      specimen_name
      age_in_days
      sex
      full_genotype
      session_type
      units
      structure_acronyms
      structurewise_unit_counts
      metadata
      stimulus_presentations
      spike_times      
   end
      
   %% Private properties
   properties (Access = private)
      sPropertyCache;               % Structure for cached property access methods
   end
   
   
   %% Constructor
   methods
      function oSession = ecephyssession
         % - Memoize property access functions
      end
   end
   
   %% Public methods
   methods
      function get_current_source_density
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_lfp
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_valid_time_points
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function filter_invalid_times_by_tags
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_inter_presentation_intervals_for_stimulus
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_stimulus_table
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_stimulus_epochs
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_invalid_times
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_pupil_data
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function mask_invalid_stimulus_presentations
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function presentationwise_spike_counts
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function presentationwise_spike_times
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function conditionwise_spike_statistics
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_parameter_values_for_stimulus
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function get_stimulus_parameter_values
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function channel_structure_intervals
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_spike_times
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_stimulus_presentations
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_units_table
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_nwb1_waveforms
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_mean_waveforms
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function build_inter_presentation_intervals
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function filter_owned_df
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function remove_detailed_stimulus_parameters
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function from_nwb_path
         error('BOT:NotImplemented', 'This method is not implemented');
      end
      function warn_invalid_spike_intervals      
         error('BOT:NotImplemented', 'This method is not implemented');
      end
   end
   
   %% Private methods
   methods (Access = private)
   end
end