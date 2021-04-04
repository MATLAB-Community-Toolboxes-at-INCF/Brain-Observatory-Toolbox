%% CLASS ephysmanifest

% Notes regarding various item fetchers
%  fetch_ephys_XXX: retrieves raw item table from cloud cache. Pre-memoized --> place to do core representional transformations
%  fetch_annotated_ephys_XXX: retrieves item table joined with item table one level up in hierarchy, w/ some post-join tranformations (e.g. identifying source table in joined table variable name). Pre-memoized. 
%  fetch_ephys_XXX_table: retrieves item table for public property access, including final transformations (e.g. linked item counts). Post-memoized --> should be cheaper transformations

%% Class definition

classdef ephysmanifest < handle
   properties (Access = private, Transient = true)
      cache = bot.internal.cache;        % BOT Cache object
      api_access;                         % Function handles for low-level API access
   end
   
   properties (SetAccess = private, Dependent = true)
      ephys_sessions;                 % Table of all EPhys experimental sessions
      ephys_channels;                 % Table of all EPhys channels
      ephys_probes;                   % Table of all EPhys probes
      ephys_units;                    % Table of all EPhys units
   end
   
   %% Constructor
   methods (Access = private)
      function manifest = ephysmanifest()
         % - Initialise internal manifest cache
         manifest.api_access.ephys_sessions = [];
         manifest.api_access.ephys_channels = [];
         manifest.api_access.ephys_probes = [];
         manifest.api_access.ephys_units = [];
         
         manifest.api_access.memoized.fetch_ephys_sessions = memoize(@manifest.fetch_ephys_sessions);
         manifest.api_access.memoized.fetch_ephys_channels = memoize(@manifest.fetch_ephys_channels);
         manifest.api_access.memoized.fetch_ephys_probes = memoize(@manifest.fetch_ephys_probes);
         manifest.api_access.memoized.fetch_ephys_units = memoize(@manifest.fetch_ephys_units);
         manifest.api_access.memoized.fetch_annotated_ephys_units = memoize(@manifest.fetch_annotated_ephys_units);
         manifest.api_access.memoized.fetch_annotated_ephys_channels = memoize(@manifest.fetch_annotated_ephys_channels);
         manifest.api_access.memoized.fetch_annotated_ephys_units = memoize(@manifest.fetch_annotated_ephys_units);
         manifest.api_access.memoized.fetch_annotated_ephys_probes = memoize(@manifest.fetch_annotated_ephys_probes);         
      end
   end
   
   methods (Static = true)
      function manifest = instance(clear_manifest)
         % instance - STATIC METHOD Retrieve or reset the singleton instance of the EPhys manifest
         %
         % Usage: manifest = instance()
         %        instance(clear_manifest)
         %
         % `manifest` will be a singleton manifest object.
         %
         % If `clear_manifest` = `true` is provided, then the single
         % instance will be cleared and reset.
         
         arguments
            clear_manifest = false
         end
         
         persistent ephysmanifest
         
         % - Construct the manifest if single instance is not present
         if isempty(ephysmanifest)
            ephysmanifest = bot.internal.ephysmanifest();
         end
         
         % - Return the instance
         manifest = ephysmanifest;
         
         % - Clear the manifest if requested
         if clear_manifest
            ephysmanifest = [];
            clear manifest;
         end
      end
   end
   
   %% Getter methods
   methods
      function ephys_sessions = get.ephys_sessions(manifest)
         % - Try to get cached table
         ephys_sessions = manifest.api_access.ephys_sessions;
         
         % - If table is not already in-memory
         if isempty(ephys_sessions)
            % - Try to retrieve table from on-disk cache
            strKey = 'allen_brain_observatory_ephys_sessions_manifest';
            if manifest.cache.IsObjectInCache(strKey)
               ephys_sessions = manifest.cache.RetrieveObject(strKey);
            else
               % - Construct table from API
               ephys_sessions = manifest.fetch_ephys_sessions_table();
               
               % - Insert object in disk cache
               manifest.cache.InsertObject(strKey, ephys_sessions);
            end
            
            % - Store table in memory cache
            manifest.api_access.ephys_sessions = ephys_sessions;
         end
      end
      
      function ephys_channels = get.ephys_channels(manifest)
         % - Try to get cached table
         ephys_channels = manifest.api_access.ephys_channels;
         
         % - If table is not already in-memory
         if isempty(ephys_channels)
            % - Try to retrieve table from on-disk cache
            nwb_key = 'allen_brain_observatory_ephys_channels_manifest';
            if manifest.cache.IsObjectInCache(nwb_key)
               ephys_channels = manifest.cache.RetrieveObject(nwb_key);
            else
               % - Construct table from API
               ephys_channels = manifest.fetch_ephys_channels_table();
               
               % - Insert object in disk cache
               manifest.cache.InsertObject(nwb_key, ephys_channels);
            end
            
            % - Store table in memory cache
            manifest.api_access.ephys_channels = ephys_channels;
         end
      end
      
      function ephys_probes = get.ephys_probes(manifest)
         % - Try to get cached table
         ephys_probes = manifest.api_access.ephys_probes;
         
         % - If table is not already in-memory
         if isempty(ephys_probes)
            % - Try to retrieve table from on-disk cache
            nwb_key = 'allen_brain_observatory_ephys_probes_manifest';
            if manifest.cache.IsObjectInCache(nwb_key)
               ephys_probes = manifest.cache.RetrieveObject(nwb_key);
            else
               % - Construct table from API
               ephys_probes = manifest.fetch_ephys_probes_table();
               
               % - Insert object in disk cache
               manifest.cache.InsertObject(nwb_key, ephys_probes);
            end
            
            % - Store table in memory cache
            manifest.api_access.ephys_probes = ephys_probes;
         end
      end
      
      function ephys_units = get.ephys_units(manifest)
         % - Try to get cached table
         ephys_units = manifest.api_access.ephys_units;
         
         % - If table is not already in-memory
         if isempty(ephys_units)
            % - Try to retrieve table from on-disk cache
            nwb_key = 'allen_brain_observatory_ephys_units_manifest';
            if manifest.cache.IsObjectInCache(nwb_key)
               ephys_units = manifest.cache.RetrieveObject(nwb_key);
            else
               % - Construct table from API
               ephys_units = manifest.fetch_ephys_units_table();
               
               % - Insert object in disk cache
               manifest.cache.InsertObject(nwb_key, ephys_units);
            end
            
            % - Store table in memory cache
            manifest.api_access.ephys_units = ephys_units;
         end
      end
   end
   
   %% Update manifest method
   methods
      function UpdateManifests(oManifest)
         boc = bot.internal.cache;
         
         % - Invalidate manifests in cache
         boc.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysSession');
         boc.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysUnit');
         boc.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysProbe');
         boc.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysChannel');
         
         % - Remove cached manifest tables
         boc.ocCache.Remove('allen_brain_observatory_ephys_sessions_manifest')
         boc.ocCache.Remove('allen_brain_observatory_ephys_units_manifest')
         boc.ocCache.Remove('allen_brain_observatory_ephys_probes_manifest')
         boc.ocCache.Remove('allen_brain_observatory_ephys_channels_manifest')
         
         % - Clear all caches for memoized access functions
         for strField = fieldnames(oManifest.api_access.memoized)'
            oManifest.api_access.memoized.(strField{1}).clearCache();
         end
         
         % - Reset singleton instance
         bot.internal.ephysmanifest.instance(true);
      end
   end
   
   methods (Access = private)
      %% Low-level getter methods for EPhys data
      
      function ephys_sessions = fetch_ephys_sessions_table(manifest)
         % METHOD - Return the table of all EPhys experimental sessions
                  
         % - Get table of EPhys sessions
         ephys_sessions = manifest.api_access.memoized.fetch_ephys_sessions();
         annotated_ephys_units = manifest.api_access.memoized.fetch_annotated_ephys_units();
         annotated_ephys_channels = manifest.api_access.memoized.fetch_annotated_ephys_channels();
         annotated_ephys_probes = manifest.api_access.memoized.fetch_annotated_ephys_probes();
         
         % - Count numbers of units, channels and probes
         ephys_sessions = count_owned(ephys_sessions, annotated_ephys_units, ...
            "id", "ephys_session_id", "unit_count");
         ephys_sessions = count_owned(ephys_sessions, annotated_ephys_channels, ...
            "id", "ephys_session_id", "channel_count");
         ephys_sessions = count_owned(ephys_sessions, annotated_ephys_probes, ...
            "id", "ephys_session_id", "probe_count");
         
         % - Get structure acronyms
         ephys_sessions = fetch_grouped_uniques(ephys_sessions, annotated_ephys_channels, ...
            'id', 'ephys_session_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
         
         % - Rename variables %TODO: consider move upstream
         ephys_sessions = rename_variables(ephys_sessions, 'genotype', 'full_genotype');
      end
      
      function ephys_units = fetch_ephys_units_table(manifest)
         % METHOD - Return the table of all EPhys recorded units
         ephys_units = manifest.fetch_annotated_ephys_units();
      end
      
      function ephys_probes = fetch_ephys_probes_table(manifest)
         % METHOD - Return the table of all EPhys recorded probes
         
         % - Get the annotated probes
         ephys_probes = manifest.api_access.memoized.fetch_annotated_ephys_probes();
         annotated_ephys_units = manifest.api_access.memoized.fetch_annotated_ephys_units();
         annotated_ephys_channels = manifest.api_access.memoized.fetch_annotated_ephys_channels();
         
         % - Count units and channels
         ephys_probes = count_owned(ephys_probes, annotated_ephys_units, ...
            'id', 'ephys_probe_id', 'unit_count');
         ephys_probes = count_owned(ephys_probes, annotated_ephys_channels, ...
            'id', 'ephys_probe_id', 'channel_count');
         
         % - Get structure acronyms
         ephys_probes = fetch_grouped_uniques(ephys_probes, annotated_ephys_channels, ...
            'id', 'ephys_probe_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
      end
      
      function ephys_channels = fetch_ephys_channels_table(manifest)
         % METHOD - Return the table of all EPhys recorded channels
         
         % - Get annotated channels
         ephys_channels = manifest.api_access.memoized.fetch_annotated_ephys_channels();
         annotated_ephys_units = manifest.api_access.memoized.fetch_annotated_ephys_units();
         
         % - Count owned units
         ephys_channels = count_owned(ephys_channels, annotated_ephys_units, ...
            'id', 'ecephys_channel_id', 'unit_count');
         
         % - Rename variables %TODO: consider move upstream
         ephys_channels = rename_variables(ephys_channels, 'name', 'probe_name');
      end
      
      function [ephys_session_manifest] = fetch_ephys_sessions(manifest)
         % - Fetch the ephys sessions manifest
         % - Download EPhys session manifest
         disp('Fetching EPhys sessions manifest...');
         ephys_session_manifest = manifest.cache.CachedAPICall('criteria=model::EcephysSession', 'rma::include,specimen(donor(age)),well_known_files(well_known_file_type)');
         
         % - Label as EPhys sessions
         ephys_session_manifest = addvars(ephys_session_manifest, ...
            repmat(categorical({'EPhys'}, {'EPhys', 'OPhys'}), size(ephys_session_manifest, 1), 1), ...
            'NewVariableNames', 'type', ...
            'before', 1);
         
         % - Post-process EPhys manifest
         age_in_days = arrayfun(@(s)s.donor.age.days, ephys_session_manifest.specimen);
         cSex = arrayfun(@(s)s.donor.sex, ephys_session_manifest.specimen, 'UniformOutput', false);
         cGenotype = arrayfun(@(s)s.donor.full_genotype, ephys_session_manifest.specimen, 'UniformOutput', false);
         
         vbWT = cellfun(@isempty, cGenotype);
         if any(vbWT)
            cGenotype{vbWT} = 'wt';
         end
         
         cWkf_types = arrayfun(@(s)s.well_known_file_type.name, ephys_session_manifest.well_known_files, 'UniformOutput', false);
         has_nwb = cWkf_types == "EcephysNwb";
         
         % - Add variables
         ephys_session_manifest = addvars(ephys_session_manifest, age_in_days, cSex, cGenotype, has_nwb, ...
            'NewVariableNames', {'age_in_days', 'sex', 'genotype', 'has_nwb'});
         
         % - Rename variables
         ephys_session_manifest = rename_variables(ephys_session_manifest, "stimulus_name", "session_type");
         
         % - Convert variables to useful types
         ephys_session_manifest.date_of_acquisition = datetime(ephys_session_manifest.date_of_acquisition,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
         ephys_session_manifest.id = uint32(ephys_session_manifest.id);
         ephys_session_manifest.isi_experiment_id = uint32(ephys_session_manifest.isi_experiment_id);
         ephys_session_manifest.published_at = datetime(ephys_session_manifest.published_at,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
         ephys_session_manifest.specimen_id = uint32(ephys_session_manifest.specimen_id);
         ephys_session_manifest.sex = categorical(ephys_session_manifest.sex, {'M', 'F'});
         ephys_session_manifest.session_type = categorical(ephys_session_manifest.session_type);
         ephys_session_manifest.genotype = string(ephys_session_manifest.genotype);
      end
      
      function [ephys_unit_manifest] = fetch_ephys_units(manifest)
         % - Fetch the ephys units manifest
         % - Download EPhys units
         disp('Fetching EPhys units manifest...');
         ephys_unit_manifest = manifest.cache.CachedAPICall('criteria=model::EcephysUnit', '');
         
         % - Rename variables
         ephys_unit_manifest = rename_variables(ephys_unit_manifest, ...
            'PT_ratio', 'waveform_PT_ratio', ...
            'amplitude', 'waveform_amplitude', ...
            'duration', 'waveform_duration', ...
            'halfwidth', 'waveform_halfwidth', ...
            'recovery_slope', 'waveform_recovery_slope', ...
            'repolarization_slope', 'waveform_repolarization_slope', ...
            'spread', 'waveform_spread', ...
            'velocity_above', 'waveform_velocity_above', ...
            'velocity_below', 'waveform_velocity_below', ...
            'l_ratio', 'L_ratio', ...
            'ecephys_channel_id', 'ephys_channel_id');
         
         % - Set default filter values
         if ~exist('sFilterValues', 'var') || isempty(sFilterValues) %#ok<NODEF>
            sFilterValues.amplitude_cutoff_maximum = 0.1;
            sFilterValues.presence_ratio_minimum = 0.95;
            sFilterValues.isi_violations_maximum = 0.5;
         end
         
         % - Check filter values
         assert(isstruct(sFilterValues), ...
            'BOT:Usage', ...
            '`sFilterValues` must be a structure with fields {''amplitude_cutoff_maximum'', ''presence_ratio_minimum'', ''isi_violations_maximum''}.')
         
         if ~isfield(sFilterValues, 'amplitude_cutoff_maximum')
            sFilterValues.amplitude_cutoff_maximum = inf;
         end
         
         if ~isfield(sFilterValues, 'presence_ratio_minimum')
            sFilterValues.presence_ratio_minimum = -inf;
         end
         
         if ~isfield(sFilterValues, 'isi_violations_maximum')
            sFilterValues.isi_violations_maximum = inf;
         end
         
         % - Filter units
         ephys_unit_manifest = ...
            ephys_unit_manifest(ephys_unit_manifest.amplitude_cutoff <= sFilterValues.amplitude_cutoff_maximum & ...
            ephys_unit_manifest.presence_ratio >= sFilterValues.presence_ratio_minimum & ...
            ephys_unit_manifest.isi_violations <= sFilterValues.isi_violations_maximum, :);
         
         if any(ephys_unit_manifest.Properties.VariableNames == "quality")
            ephys_unit_manifest = ephys_unit_manifest(ephys_unit_manifest.quality == "good", :);
         end
         
         if any(ephys_unit_manifest.Properties.VariableNames == "ephys_structure_id")
            ephys_unit_manifest = ephys_unit_manifest(~isempty(ephys_unit_manifest.ephys_structure_id), :);
         end
         
         % - Convert variables to useful types
         ephys_unit_manifest.ecephys_channel_id = uint32(ephys_unit_manifest.ephys_channel_id);
         ephys_unit_manifest.id = uint32(ephys_unit_manifest.id);         

         
         for var = string(ephys_unit_manifest.Properties.VariableNames)
             firstRowVal = ephys_unit_manifest{1,var};
             
             if iscellstr(ephys_unit_manifest.(var)) %#ok<ISCLSTR>
                 ephys_unit_manifest.(var) = string(ephys_unit_manifest.(var));                 
             elseif iscell(firstRowVal)
                 assert(isscalar(firstRowVal));
             
                 if all(cellfun(@isnumeric,ephys_unit_manifest.(var)))
                     [ephys_unit_manifest.(var)(cellfun(@isempty,ephys_unit_manifest.(var)))] = deal({nan});
                     ephys_unit_manifest.(var) = cell2mat(ephys_unit_manifest.(var));
                 elseif any(cellfun(@ischar,ephys_unit_manifest.(var)))
                     ephys_unit_manifest.(var) = string_emptyNonChar(ephys_unit_manifest.(var));
                 end
                     
             end                                                     
             
         end
      
      end
      
      function [ephys_probes_manifest] = fetch_ephys_probes(manifest)
         % - Fetch the ephys probes manifest
         disp('Fetching EPhys probes manifest...');
         ephys_probes_manifest = manifest.cache.CachedAPICall('criteria=model::EcephysProbe', '');
         
         % - Rename variables
         ephys_probes_manifest = rename_variables(ephys_probes_manifest, ...
            "use_lfp_data", "has_lfp_data", "ecephys_session_id", "ephys_session_id");
         
         % - Divide the lfp sampling by the subsampling factor for clearer presentation (if provided)
         if all(ismember({'lfp_sampling_rate', 'lfp_temporal_subsampling_factor'}, ...
               ephys_probes_manifest.Properties.VariableNames))
            cfTSF = ephys_probes_manifest.lfp_temporal_subsampling_factor;
            cfTSF(cellfun(@isempty, cfTSF)) = {1}; 
            vfTSF = cell2mat(cfTSF);
            ephys_probes_manifest.lfp_sampling_rate = ...
               ephys_probes_manifest.lfp_sampling_rate ./ vfTSF;
         end
         
         % - Convert variables to useful types
         ephys_probes_manifest.ephys_session_id = uint32(ephys_probes_manifest.ephys_session_id);
         ephys_probes_manifest.id = uint32(ephys_probes_manifest.id);
         ephys_probes_manifest.phase = categorical(ephys_probes_manifest.phase);
         ephys_probes_manifest.name= categorical(ephys_probes_manifest.name);
         
         ltsf = ephys_probes_manifest.lfp_temporal_subsampling_factor;
         [ltsf{cellfun(@isempty,ltsf)}] = deal(nan); %TODO: revisit if this shoudl be '1' replaced as above; for now, just focused on re-representing as a numeric array rather than cell array
         ephys_probes_manifest.lfp_temporal_subsampling_factor = cell2mat(ltsf);


      end
      
      function [ephys_channels_manifest] = fetch_ephys_channels(manifest)
         % - Fetch the ephys units manifest
         disp('Fetching EPhys channels manifest...');
         ephys_channels_manifest = manifest.cache.CachedAPICall('criteria=model::EcephysChannel', "rma::include,structure,rma::options[tabular$eq'ecephys_channels.id,ecephys_probe_id as ephys_probe_id,local_index,probe_horizontal_position,probe_vertical_position,anterior_posterior_ccf_coordinate,dorsal_ventral_ccf_coordinate,left_right_ccf_coordinate,structures.id as ephys_structure_id,structures.acronym as ephys_structure_acronym']");
         
         % - Convert columns to reasonable formats
         id = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.id, 'UniformOutput', false)));
         ephys_probe_id = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.ephys_probe_id, 'UniformOutput', false)));
         local_index = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.local_index, 'UniformOutput', false)));
         probe_horizontal_position = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.probe_horizontal_position, 'UniformOutput', false)));
         probe_vertical_position = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.probe_vertical_position, 'UniformOutput', false)));
         anterior_posterior_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.anterior_posterior_ccf_coordinate, 'UniformOutput', false)));
         dorsal_ventral_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.dorsal_ventral_ccf_coordinate, 'UniformOutput', false)));
         left_right_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.left_right_ccf_coordinate, 'UniformOutput', false)));
         
         ephys_structure_acronym = ephys_channels_manifest.ephys_structure_acronym;
         
         ephys_structure_id = uint32(cell2mat(cellfun(@str2num_nan, ephys_channels_manifest.ephys_structure_id, 'UniformOutput', false))); % so long as it's retained, convert from cell to numeric
         % TODO: consider removing ephys_structure_id altogether from table, after verifying it's fundamentally redundant
         % assert(isempty(setdiff(histcounts(ephys_structure_id),histcounts(categorical(cell2mat(ephys_structure_acronym))))));          
         
         % - Rebuild table
         ephys_channels_manifest = table(id, ephys_probe_id, local_index, ...
            probe_horizontal_position, probe_vertical_position, ...
            anterior_posterior_ccf_coordinate, dorsal_ventral_ccf_coordinate, ...
            left_right_ccf_coordinate, ephys_structure_id, ephys_structure_acronym);
      end
      
      function annotated_ephys_units = fetch_annotated_ephys_units(manifest)
         % METHOD - Return table of annotated EPhys units
         
         % - Annotate units
         annotated_ephys_units = manifest.api_access.memoized.fetch_ephys_units();
         annotated_ephys_channels = manifest.api_access.memoized.fetch_annotated_ephys_channels();
         
         annotated_ephys_units = join(annotated_ephys_units, annotated_ephys_channels, ...
            'LeftKeys', 'ephys_channel_id', 'RightKeys', 'id');
         
         % - Rename variables
         annotated_ephys_units = rename_variables(annotated_ephys_units, ...
            'name', 'probe_name', ...
            'phase', 'probe_phase', ...
            'sampling_rate', 'probe_sampling_rate', ...
            'lfp_sampling_rate', 'probe_lfp_sampling_rate', ...
            'local_index', 'peak_channel');
         
         % - Convert acronyms (cell arrays) to strings, since invalid units
         % have been filtered away
         annotated_ephys_units.ephys_structure_acronym = arrayfun(@(e)string(e{1}), annotated_ephys_units.ephys_structure_acronym);
         
         % - Convert to categorical
         annotated_ephys_units.ephys_structure_acronym = categorical(annotated_ephys_units.ephys_structure_acronym);
      end
      
      function annotated_ephys_probes = fetch_annotated_ephys_probes(manifest)
         % METHOD - Return the annotate table of EPhys probes
         % - Annotate probes and return
         annotated_ephys_probes = manifest.api_access.memoized.fetch_ephys_probes();
         sessions = manifest.api_access.memoized.fetch_ephys_sessions();
         annotated_ephys_probes = join(annotated_ephys_probes, sessions, 'LeftKeys', 'ephys_session_id', 'RightKeys', 'id');
      end
      
      function annotated_ephys_channels = fetch_annotated_ephys_channels(manifest)
         % - METHOD - Return the annotated table of EPhys channels
         annotated_ephys_channels = manifest.api_access.memoized.fetch_ephys_channels();
         annotated_ephys_probes = manifest.api_access.memoized.fetch_annotated_ephys_probes();
         annotated_ephys_channels = join(annotated_ephys_channels, annotated_ephys_probes, ...
            'LeftKeys', 'ephys_probe_id', 'RightKeys', 'id');
        
        
        
      end
   end
end

%% Helper functions

function table_to_rename = rename_variables(table_to_rename, varargin)
% rename_variables - FUNCTION Rename variables in a table
%
% Usage: table_to_rename = rename_variables(table_to_rename, 'var_source_A', 'var_dest_A', 'var_source_B', 'var_dest_B', ...)
%
% Source variables will be renamed (if found) to destination variable
% names.

% - Loop over pairs of source/dest names
for nVar = 1:2:numel(varargin)
   % - Find variables matching the source name
   vbVarIndex = table_to_rename.Properties.VariableNames == string(varargin{nVar});
   
   if any(vbVarIndex)
      % - Rename this variable to the destination name
      table_to_rename.Properties.VariableNames(vbVarIndex) = string(varargin{nVar + 1});
   end
end
end

function return_table = fetch_grouped_uniques(source_table, scan_table, source_grouping_var, scan_grouping_var, scan_var, source_new_var)
% fetch_grouped_uniques - FUNCTION Find unique values in a table, grouped by a particular key
%
% return_table = fetch_grouped_uniques(source_table, scan_table, strGroupingVarSource, scan_grouping_var, scan_var, source_new_var)
%
% `source_table` and `scan_table` are both tables, which can be joined by matching
% variables `source_table.(strGroupingVarSource)` with
% `scan_table.(strGroupingVarScan)`.
%
% This function finds all `scan_table` rows that match `source_table` rows
% (essentially a join on source_grouping_var ==> scan_grouping_var),
% then collects all unique values of `scan_table.(scan_var)` in those rows.
% The collection of unique values is then copied to the new variable
% `source_table.(source_new_var)` for all those matching source rows in
% `source_table`.

% - Get list of keys in `scan_table`.(`scan_grouping_var`)
all_keys_scan = scan_table.(scan_grouping_var);

% - Get list of keys in `source_table`.(`source_grouping_var`)
all_keys_source = source_table.(source_grouping_var);

% - Make a new cell array for `source_table` to contain unique values
groups = cell(size(source_table, 1), 1);

% - Loop over unique scan keys
for source_row_index = 1:numel(all_keys_source)
   % - Get the key for this row
   this_key = all_keys_source(source_row_index);
   
   % - Find rows in scan matching this group (can be cells; `==` doesn't work)
   if iscell(all_keys_scan)
      vbScanGroupRows = arrayfun(@(o)isequal(o, this_key), all_keys_scan);
   else
      vbScanGroupRows = all_keys_scan == this_key;
   end
   
   % - Extract all values in `scan_table`.(`scan_var`) for the matching rows
   all_values = reshape(scan_table{vbScanGroupRows, scan_var}, [], 1);
   
   % - Find unique values for this group
   if iscell(all_values)
      % - Handle "empty" values
      is_empty_value = cellfun(@isempty, all_values);
      if any(is_empty_value)
         unique_values = [unique(all_values(~is_empty_value)); {[]}];
      else
         unique_values = unique(all_values);
      end
   else
      unique_values = unique(all_values);
   end
   
   % - Assign these unique values to row in `source_Table`
   groups(source_row_index) = {unique_values};
end

% - Add the groups to `source_table`
return_table = addvars(source_table, groups, 'NewVariableNames', source_new_var);
end


function return_table = count_owned(source_table, scan_table, grouping_var_source, grouping_var_scan, new_var_source)
% count_owned - FUNCTION Count the number of rows in `scan_table` owned by a particular variable value
%
% Usage: return_table = count_owned(source_table, scan_table, grouping_var_source, grouping_var_scan, new_var_source)
%
% This function finds the number of rows in `scan_table` that are
% conceptually owned by values of an index variable in `source_table`, by
% performing a join between `source_table.(grouping_var_source)` and
% `scan_table.(grouping_var_scan)`.
%
% The count of rows in `scan_table` is then added to the new variable in
% `source_table.(new_var_source)`.

% - Get list of keys in `scan_table`.(`grouping_var_scan`)
all_keys_scan = scan_table.(grouping_var_scan);

% - Get list of keys in `source_table`.(`grouping_var_source`)
all_keys_source = source_table.(grouping_var_source);

% - Make a new variable for `source_table` to contain counts
counts = nan(size(source_table, 1), 1);

% - Loop over unique source keys
for source_row_index = 1:numel(all_keys_source)
   % - Get the key for this row
   this_key = all_keys_source(source_row_index);
   
   % - Find rows in scan matching this group (can be cells; `==` doesn't work)
   if iscell(all_keys_scan)
      scan_group_rows = arrayfun(@(o)isequal(o, this_key), all_keys_scan);
   else
      scan_group_rows = all_keys_scan == this_key;
   end
   
   % - Assign these counts to matching group rows in `source_table`
   counts(source_row_index) = nnz(scan_group_rows);
end

% - Add the counts to the table
return_table = addvars(source_table, counts, 'NewVariableNames', new_var_source);
end


function n = str2num_nan(s)
   if isempty(s)
      n = nan;
   else
      n = str2double(s);
   end
end

function cvec = string_emptyNonChar(cvec)
% Convert cellstr to string, handling special cases of an "almost" cellstr array input which represents empty values as a non-char

if iscellstr(cvec) %#ok<ISCLSTR>
    cvec = string(cvec);
else
    assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),cvec)))));
    
    [cvec{cellfun(@(x)~ischar(x), cvec)}] = deal('');
    cvec = string(cvec);
end

end