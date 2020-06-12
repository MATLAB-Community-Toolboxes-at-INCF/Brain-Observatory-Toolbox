%% CLASS ephysmanifest

%% Class definition

classdef ephysmanifest < handle
   properties (Access = private, Transient = true)
      oCache = bot.internal.cache;        % BOT Cache object
      sAPIAccess;                         % Function handles for low-level API access
   end
   
   properties (SetAccess = private, Dependent = true)
      tEPhysSessions;                 % Table of all EPhys experimental sessions
      tEPhysChannels;                 % Table of all EPhys channels
      tEPhysProbes;                   % Table of all EPhys probes
      tEPhysUnits;                    % Table of all EPhys units
   end
   
   %% Constructor
   methods
      function oManifest = ephysmanifest()
         % - Initialise internal manifest cache
         oManifest.sAPIAccess.tEPhysSessions = [];
         oManifest.sAPIAccess.tEPhysChannels = [];
         oManifest.sAPIAccess.tEPhysProbes = [];
         oManifest.sAPIAccess.tEPhysUnits = [];
      end
   end
   
   %% Getter methods
   methods
      function tEPhysSessions = get.tEPhysSessions(oManifest)
         % - Try to get cached table
         tEPhysSessions = oManifest.sAPIAccess.tEPhysSessions;
         
         % - If table is not already in-memory
         if isempty(tEPhysSessions)
            % - Try to retrieve table from on-disk cache
            strKey = 'allen_brain_observatory_ephys_sessions_manifest';
            if oManifest.oCache.IsObjectInCache(strKey)
               tEPhysSessions = oManifest.oCache.RetrieveObject(strKey);
            else
               % - Construct table from API
               tEPhysSessions = oManifest.get_tEPhysSessions();
               
               % - Insert object in disk cache
               oManifest.oCache.InsertObject(strKey, tEPhysSessions);
            end
            
            % - Store table in memory cache
            oManifest.sAPIAccess.tEPhysSessions = tEPhysSessions;
         end
      end
      
      function tEPhysChannels = get.tEPhysChannels(oManifest)
         % - Try to get cached table
         tEPhysChannels = oManifest.sAPIAccess.tEPhysChannels;
         
         % - If table is not already in-memory
         if isempty(tEPhysChannels)
            % - Try to retrieve table from on-disk cache
            strKey = 'allen_brain_observatory_ephys_channels_manifest';
            if oManifest.oCache.IsObjectInCache(strKey)
               tEPhysChannels = oManifest.oCache.RetrieveObject(strKey);
            else
               % - Construct table from API
               tEPhysChannels = oManifest.get_tEPhysChannels();
               
               % - Insert object in disk cache
               oManifest.oCache.InsertObject(strKey, tEPhysChannels);
            end
            
            % - Store table in memory cache
            oManifest.sAPIAccess.tEPhysChannels = tEPhysChannels;
         end
      end
      
      function tEPhysProbes = get.tEPhysProbes(oManifest)
         % - Try to get cached table
         tEPhysProbes = oManifest.sAPIAccess.tEPhysProbes;
         
         % - If table is not already in-memory
         if isempty(tEPhysProbes)
            % - Try to retrieve table from on-disk cache
            strKey = 'allen_brain_observatory_ephys_probes_manifest';
            if oManifest.oCache.IsObjectInCache(strKey)
               tEPhysProbes = oManifest.oCache.RetrieveObject(strKey);
            else
               % - Construct table from API
               tEPhysProbes = oManifest.get_tEPhysProbes();
               
               % - Insert object in disk cache
               oManifest.oCache.InsertObject(strKey, tEPhysProbes);
            end
            
            % - Store table in memory cache
            oManifest.sAPIAccess.tEPhysProbes = tEPhysProbes;
         end
      end
      
      function tEPhysUnits = get.tEPhysUnits(oManifest)
         % - Try to get cached table
         tEPhysUnits = oManifest.sAPIAccess.tEPhysUnits;
         
         % - If table is not already in-memory
         if isempty(tEPhysUnits)
            % - Try to retrieve table from on-disk cache
            strKey = 'allen_brain_observatory_ephys_units_manifest';
            if oManifest.oCache.IsObjectInCache(strKey)
               tEPhysUnits = oManifest.oCache.RetrieveObject(strKey);
            else
               % - Construct table from API
               tEPhysUnits = oManifest.get_tEPhysUnits();
               
               % - Insert object in disk cache
               oManifest.oCache.InsertObject(strKey, tEPhysUnits);
            end
            
            % - Store table in memory cache
            oManifest.sAPIAccess.tEPhysUnits = tEPhysUnits;
         end
      end
   end
   
   methods
      function sessions = session(oManifest, vnSessionIDs)
         % - Create session objects
         sessions = bot.ephyssession(vnSessionIDs, oManifest);
      end
      
      function probes = probe(oManifest, vnProbeIDs)
         % - Create probe objects
         probes = bot.internal.ephysprobe(vnProbeIDs, oManifest);
      end
      
      function channels = channel(oManifest, vnChannelIDs)
         % - Create channel objects
         channels = bot.internal.ephyschannel(vnChannelIDs, oManifest);
      end
      
      function units = unit(oManifest, vnUnitIDs)
         % - Create unit objects
         units = bot.internal.ephysunit(vnUnitIDs, oManifest);
      end
   end
   
   %% Update manifest method
   methods
      function UpdateManifests(oManifest)
         % - Invalidate manifests in cache
         oManifest.oCache.sCacheFiles.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysSession');
         oManifest.oCache.sCacheFiles.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysUnit');
         oManifest.oCache.sCacheFiles.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysProbe');
         oManifest.oCache.sCacheFiles.ccCache.RemoveURLsMatchingSubstring('criteria=model::EcephysChannel');
         
         % - Remove cached manifest tables
         oManifest.oCache.RemoveObject('allen_brain_observatory_ephys_sessions_manifest')
         oManifest.oCache.RemoveObject('allen_brain_observatory_ephys_units_manifest')
         oManifest.oCache.RemoveObject('allen_brain_observatory_ephys_probes_manifest')
         oManifest.oCache.RemoveObject('allen_brain_observatory_ephys_channels_manifest')
         
         % - Clear all caches for memoized access functions
         for strField = fieldnames(oManifest.sAPIAccess)'
            oManifest.sAPIAccess.(strField{1}).clearCache();
         end
      end
   end
   
   methods (Access = private)
      %% Low-level getter methods for EPhys data
      
      function tEPhysSessions = get_tEPhysSessions(oManifest)
         % METHOD - Return the table of all EPhys experimental sessions
         
         % - Get table of EPhys sessions
         tEPhysSessions = oManifest.get_ephys_sessions();
         tAnnotatedEPhysUnits = oManifest.get_tAnnotatedEPhysUnits();
         tAnnotatedEPhysChannels = oManifest.get_tAnnotatedEPhysChannels();
         tAnnotatedEPhysProbes = oManifest.get_tAnnotatedEPhysProbes();
         
         % - Count numbers of units, channels and probes
         tEPhysSessions = count_owned(tEPhysSessions, tAnnotatedEPhysUnits, ...
            "id", "ephys_session_id", "unit_count");
         tEPhysSessions = count_owned(tEPhysSessions, tAnnotatedEPhysChannels, ...
            "id", "ephys_session_id", "channel_count");
         tEPhysSessions = count_owned(tEPhysSessions, tAnnotatedEPhysProbes, ...
            "id", "ephys_session_id", "probe_count");
         
         % - Get structure acronyms
         tEPhysSessions = get_grouped_uniques(tEPhysSessions, tAnnotatedEPhysChannels, ...
            'id', 'ephys_session_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
         
         % - Rename variables
         tEPhysSessions = rename_variables(tEPhysSessions, 'genotype', 'full_genotype');
      end
      
      function tEPhysUnits = get_tEPhysUnits(oManifest)
         % METHOD - Return the table of all EPhys recorded units
         tEPhysUnits = oManifest.get_tAnnotatedEPhysUnits();
      end
      
      function tEPhysProbes = get_tEPhysProbes(oManifest)
         % METHOD - Return the table of all EPhys recorded probes
         
         % - Get the annotated probes
         tEPhysProbes = oManifest.get_tAnnotatedEPhysProbes();
         tAnnotatedEPhysUnits = oManifest.get_tAnnotatedEPhysUnits();
         tAnnotatedEPhysChannels = oManifest.get_tAnnotatedEPhysChannels();
         
         % - Count units and channels
         tEPhysProbes = count_owned(tEPhysProbes, tAnnotatedEPhysUnits, ...
            'id', 'ephys_probe_id', 'unit_count');
         tEPhysProbes = count_owned(tEPhysProbes, tAnnotatedEPhysChannels, ...
            'id', 'ephys_probe_id', 'channel_count');
         
         % - Get structure acronyms
         tEPhysProbes = get_grouped_uniques(tEPhysProbes, tAnnotatedEPhysChannels, ...
            'id', 'ephys_probe_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
      end
      
      function tEPhysChannels = get_tEPhysChannels(oManifest)
         % METHOD - Return the table of all EPhys recorded channels
         
         % - Get annotated channels
         tEPhysChannels = oManifest.get_tAnnotatedEPhysChannels();
         tAnnotatedEPhysUnits = oManifest.get_tAnnotatedEPhysUnits();
         
         % - Count owned units
         tEPhysChannels = count_owned(tEPhysChannels, tAnnotatedEPhysUnits, ...
            'id', 'ecephys_channel_id', 'unit_count');
         
         % - Rename variables
         tEPhysChannels = rename_variables(tEPhysChannels, 'name', 'probe_name');
      end
      
      function [ephys_session_manifest] = get_ephys_sessions(oManifest)
         % - Fetch the ephys sessions manifest
         % - Download EPhys session manifest
         disp('Fetching EPhys sessions manifest...');
         ephys_session_manifest = oManifest.oCache.CachedAPICall('criteria=model::EcephysSession', 'rma::include,specimen(donor(age)),well_known_files(well_known_file_type)');
         
         % - Label as EPhys sessions
         ephys_session_manifest = addvars(ephys_session_manifest, ...
            repmat(categorical({'EPhys'}, {'EPhys', 'OPhys'}), size(ephys_session_manifest, 1), 1), ...
            'NewVariableNames', 'BOT_session_type', ...
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
      
      function [ephys_unit_manifest] = get_ephys_units(oManifest)
         % - Fetch the ephys units manifest
         % - Download EPhys units
         disp('Fetching EPhys units manifest...');
         ephys_unit_manifest = oManifest.oCache.CachedAPICall('criteria=model::EcephysUnit', '');
         
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
      end
      
      function [ephys_probes_manifest] = get_ephys_probes(oManifest)
         % - Fetch the ephys probes manifest
         disp('Fetching EPhys probes manifest...');
         ephys_probes_manifest = oManifest.oCache.CachedAPICall('criteria=model::EcephysProbe', '');
         
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
      end
      
      function [ephys_channels_manifest] = get_ephys_channels(oManifest)
         % - Fetch the ephys units manifest
         disp('Fetching EPhys channels manifest...');
         ephys_channels_manifest = oManifest.oCache.CachedAPICall('criteria=model::EcephysChannel', "rma::include,structure,rma::options[tabular$eq'ecephys_channels.id,ecephys_probe_id as ephys_probe_id,local_index,probe_horizontal_position,probe_vertical_position,anterior_posterior_ccf_coordinate,dorsal_ventral_ccf_coordinate,left_right_ccf_coordinate,structures.id as ephys_structure_id,structures.acronym as ephys_structure_acronym']");
         
         % - Convert columns to reasonable formats
         id = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.id, 'UniformOutput', false)));
         ephys_probe_id = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.ephys_probe_id, 'UniformOutput', false)));
         local_index = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.local_index, 'UniformOutput', false)));
         probe_horizontal_position = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.probe_horizontal_position, 'UniformOutput', false)));
         probe_vertical_position = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.probe_vertical_position, 'UniformOutput', false)));
         anterior_posterior_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.anterior_posterior_ccf_coordinate, 'UniformOutput', false)));
         dorsal_ventral_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.dorsal_ventral_ccf_coordinate, 'UniformOutput', false)));
         left_right_ccf_coordinate = uint32(cell2mat(cellfun(@str2num, ephys_channels_manifest.left_right_ccf_coordinate, 'UniformOutput', false)));
         
         es_id = ephys_channels_manifest.ephys_structure_id;
         ephys_structure_id(~cellfun(@isempty, es_id)) = cellfun(@str2num, es_id(~cellfun(@isempty, es_id)), 'UniformOutput', false);
         ephys_structure_id(cellfun(@isempty, es_id)) = {[]};
         ephys_structure_id = ephys_structure_id';
         
         ephys_structure_acronym = ephys_channels_manifest.ephys_structure_acronym;
         
         % - Rebuild table
         ephys_channels_manifest = table(id, ephys_probe_id, local_index, ...
            probe_horizontal_position, probe_vertical_position, ...
            anterior_posterior_ccf_coordinate, dorsal_ventral_ccf_coordinate, ...
            left_right_ccf_coordinate, ephys_structure_id, ephys_structure_acronym);
      end
      
      function tAnnotatedEPhysUnits = get_tAnnotatedEPhysUnits(oManifest)
         % METHOD - Return table of annotated EPhys units
         
         % - Annotate units
         tAnnotatedEPhysUnits = oManifest.get_ephys_units();
         tAnnotatedEPhysChannels = oManifest.get_tAnnotatedEPhysChannels();
         
         tAnnotatedEPhysUnits = join(tAnnotatedEPhysUnits, tAnnotatedEPhysChannels, ...
            'LeftKeys', 'ephys_channel_id', 'RightKeys', 'id');
         
         % - Rename variables
         tAnnotatedEPhysUnits = rename_variables(tAnnotatedEPhysUnits, ...
            'name', 'probe_name', ...
            'phase', 'probe_phase', ...
            'sampling_rate', 'probe_sampling_rate', ...
            'lfp_sampling_rate', 'probe_lfp_sampling_rate', ...
            'local_index', 'peak_channel');
      end
      
      function tAnnotatedEPhysProbes = get_tAnnotatedEPhysProbes(oManifest)
         % METHOD - Return the annotate table of EPhys probes
         % - Annotate probes and return
         tAnnotatedEPhysProbes = oManifest.get_ephys_probes();
         tSessions = oManifest.get_ephys_sessions();
         tAnnotatedEPhysProbes = join(tAnnotatedEPhysProbes, tSessions, 'LeftKeys', 'ephys_session_id', 'RightKeys', 'id');
      end
      
      function tAnnotatedEPhysChannels = get_tAnnotatedEPhysChannels(oCache)
         % - METHOD - Return the annotated table of EPhys channels
         tAnnotatedEPhysChannels = oCache.sAPIAccess.get_ephys_channels();
         tAnnotatedEPhysProbes = oCache.sAPIAccess.tAnnotatedEPhysProbes();
         tAnnotatedEPhysChannels = join(tAnnotatedEPhysChannels, tAnnotatedEPhysProbes, ...
            'LeftKeys', 'ephys_probe_id', 'RightKeys', 'id');
      end
   end
end

%% Helper functions

function tRename = rename_variables(tRename, varargin)
% rename_variables - FUNCTION Rename variables in a table
%
% Usage: tRename = rename_variables(tRename, 'var_source_A', 'var_dest_A', 'var_source_B', 'var_dest_B', ...)
%
% Source variables will be renamed (if found) to destination variable
% names.

% - Loop over pairs of source/dest names
for nVar = 1:2:numel(varargin)
   % - Find variables matching the source name
   vbVarIndex = tRename.Properties.VariableNames == string(varargin{nVar});
   
   if any(vbVarIndex)
      % - Rename this variable to the destination name
      tRename.Properties.VariableNames(vbVarIndex) = string(varargin{nVar + 1});
   end
end
end

function tReturn = get_grouped_uniques(tSource, tScan, strGroupingVarSource, strGroupingVarScan, strScanVar, strSourceNewVar)
% get_grouped_uniques - FUNCTION Find unique values in a table, grouped by a particular key
%
% tReturn = get_grouped_uniques(tSource, tScan, strGroupingVarSource, strGroupingVarScan, strScanVar, strSourceNewVar)
%
% `tSource` and `tScan` are both tables, which can be joined by matching
% variables `tSource.(strGroupingVarSource)` with
% `tScan.(strGroupingVarScan)`.
%
% This function finds all `tScan` rows that match `tSource` rows
% (essentially a join on strGroupingVarSource ==> strGroupingVarScan),
% then collects all unique values of `tScan.(strScanVar)` in those rows.
% The collection of unique values is then copied to the new variable
% `tSource.(strSourcewVar)` for all those matching source rows in
% `tSource`.

% - Get list of keys in `tScan`.(`strGroupingVarScan`)
voAllKeysScan = tScan.(strGroupingVarScan);

% - Get list of keys in `tSource`.(`strGroupingVarSource`)
voAllKeysSource = tSource.(strGroupingVarSource);

% - Make a new cell array for `tSource` to contain unique values
cGroups = cell(size(tSource, 1), 1);

% - Loop over unique scan keys
for nSourceRow = 1:numel(voAllKeysSource)
   % - Get the key for this row
   oKey = voAllKeysSource(nSourceRow);
   
   % - Find rows in scan matching this group (can be cells; `==` doesn't work)
   if iscell(voAllKeysScan)
      vbScanGroupRows = arrayfun(@(o)isequal(o, oKey), voAllKeysScan);
   else
      vbScanGroupRows = voAllKeysScan == oKey;
   end
   
   % - Extract all values in `tScan`.(`strScanVar`) for the matching rows
   voAllValues = reshape(tScan{vbScanGroupRows, strScanVar}, [], 1);
   
   % - Find unique values for this group
   if iscell(voAllValues)
      % - Handle "empty" values
      vbEmptyValues = cellfun(@isempty, voAllValues);
      if any(vbEmptyValues)
         voUniqueValues = [unique(voAllValues(~vbEmptyValues)); {[]}];
      else
         voUniqueValues = unique(voAllValues);
      end
   else
      voUniqueValues = unique(voAllValues);
   end
   
   % - Assign these unique values to row in `tSource`
   cGroups(nSourceRow) = {voUniqueValues};
end

% - Add the groups to `tSource`
tReturn = addvars(tSource, cGroups, 'NewVariableNames', strSourceNewVar);
end


function tReturn = count_owned(tSource, tScan, strGroupingVarSource, strGroupingVarScan, strSourceNewVar)
% count_owned - FUNCTION Count the number of rows in `tScan` owned by a particular variable value
%
% Usage: tReturn = count_owned(tSource, tScan, strGroupingVarSource, strGroupingVarScan, strSourceNewVar)
%
% This function finds the number of rows in `tScan` that are
% conceptually owned by values of an index variable in `tSource`, by
% performing a join between `tSource.(strGroupingVarSource)` and
% `tScan.(strGroupingVarScan)`.
%
% The count of rows in `tScan` is then added to the new variable in
% `tSource.(strSourceNewVar)`.

% - Get list of keys in `tScan`.(`strGroupingVarScan`)
voAllKeysScan = tScan.(strGroupingVarScan);

% - Get list of keys in `tSource`.(`strGroupingVarSource`)
voAllKeysSource = tSource.(strGroupingVarSource);

% - Make a new variable for `tSource` to contain counts
vnCounts = nan(size(tSource, 1), 1);

% - Loop over unique source keys
for nSourceRow = 1:numel(voAllKeysSource)
   % - Get the key for this row
   oKey = voAllKeysSource(nSourceRow);
   
   % - Find rows in scan matching this group (can be cells; `==` doesn't work)
   if iscell(voAllKeysScan)
      vbScanGroupRows = arrayfun(@(o)isequal(o, oKey), voAllKeysScan);
   else
      vbScanGroupRows = voAllKeysScan == oKey;
   end
   
   % - Assign these counts to matching group rows in `tSource`
   vnCounts(nSourceRow) = nnz(vbScanGroupRows);
end

% - Add the counts to the table
tReturn = addvars(tSource, vnCounts, 'NewVariableNames', strSourceNewVar);
end
