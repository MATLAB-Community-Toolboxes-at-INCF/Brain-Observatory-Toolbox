%% CLASS EphysManifest
%
% This class can be used to obtain various `tables of items´ from the 
% Visual Coding Neuropixels dataset [1] obtained with the Allen Brain 
% Observatory platform [2].
%
% Item tables contain overview information about individual items belonging 
% to the dataset and tables for the following item types are available:
%   ephys_sessions     : Experimental sessions
%   ephys_probes       : Neuropixels probes
%   ephys_channels     : Recording channel of a probe
%   ephys_units        : Functional unit as detected by spike sorting
%
%
% USAGE:
%
% Construction:
% >> bem = bot.item.internal.Manifest.instance('ephys')
% >> bem = bot.item.internal.EphysManifest.instance()
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Coding Neuropixels dataset. 
%       Available from: portal.brain-map.org/explore/circuits/visual-coding-neuropixels.
% [2] Copyright 2016 Allen Institute for Brain Science. Allen Brain Observatory. 
%       Available from: portal.brain-map.org/explore/circuits

% Notes regarding fetching of item tables for the ephys manifest.
% 
% The item tables goes through three steps of processing after being
% downloaded:
%   1) Preprocessing: The item table is restructured by adding extra
%           information, renaming variables and converting data types to
%           appropriate types for the table format.
%   2) Joining: The table is joined with the item table one level up in the
%           hierarchy w/ some post-join tranformations (e.g. identifying 
%           source table in joined table variable name).
%   3) Adding linked item counts: Counts for linked items of tables for all
%           tables below the current in the hierarchy is added as separate
%           table variables.
%   
%   Methods for performing step 1) and 2) are memoized in order to reduce
%   overhead when fetching the different tables. Because tables are
%   dependent on tables bove or below in the hierarchy, fetching one table
%   might require a partial fetching of one or more other tables. By
%   memoizing these steps, it is ensured that intermediate processing steps
%   are cached for later use.

% Note: The S3 session table has some discrepencies, and the download from 
% api is quick anyway, so this is always retrieved from api.


%% Class definition

classdef EphysManifest < bot.item.internal.Manifest
    
    properties (SetAccess = private, Dependent = true)
        ephys_sessions     % Table of all EPhys experimental sessions
        ephys_probes       % Table of all EPhys probes
        ephys_channels     % Table of all EPhys channels
        ephys_units        % Table of all EPhys units
    end

% %     properties (SetAccess = private, Dependent = true) % Todo: rename?
% %         Sessions     % Table of all EPhys experimental sessions
% %         Probes       % Table of all EPhys probes
% %         Channels     % Table of all EPhys channels
% %         Units        % Table of all EPhys units
% %     end
        
    properties (Constant, Access=protected, Hidden)
        DATASET_NAME = "VisualCoding"
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ephys;
        ITEM_TYPES = ["Session", "Probe", "Channel", "Unit"]
        DOWNLOAD_FROM = containers.Map(...
            bot.item.internal.EphysManifest.ITEM_TYPES, ...
            ["API", "", "", ""] )
    end

    properties (Access = protected)
        FileResource = bot.internal.fileresource.S3Bucket.instance()
    end  

    %% Constructor
    methods (Access = private)
        function eManifest = EphysManifest()

            eManifest@bot.item.internal.Manifest()

            % Memoize methods for fetching item tables at various stages
            eManifest.MemoizedFetcher.RawTable = ...
                memoize(@eManifest.fetchRawItemTable);
            
            eManifest.MemoizedFetcher.JointTable = ...
                memoize(@eManifest.fetchJointItemTable);
        end
    end

    %% Method for interacting with singleton instance
    methods (Static = true) 
        function manifest = instance(action)
            % instance Get or clear singleton instance of the EPhys manifest
            %
            %   manifest = bot.item.internal.EphysManifest.instance()
            %   returns a singleton instance of the EphysManifest class
            %        
            %   bot.item.internal.EphysManifest.instance("clear") will 
            %   clear the singleton instance from memory
            
            arguments
                action (1,1) string {mustBeMember(action, ...
                    ["get", "clear", "reset"])} = "get";
            end
            
            persistent ephysmanifest % singleton instance
            
            % - Clear the manifest if requested
            if ismember(action, ["clear", "reset"])
                delete(ephysmanifest); ephysmanifest = [];
            end

            if ismember(action, ["get", "reset"])
                % - Construct the manifest if singleton instance is not present
                if isempty(ephysmanifest)
                    ephysmanifest = bot.item.internal.EphysManifest();
                end

                % - Return the instance
                manifest = ephysmanifest; 
            end
        end
    end

    %% Getter methods
    methods

        function sessionTable = get.ephys_sessions(eManifest)
            sessionTable = eManifest.fetch_cached('ephys_sessions', ...
                @(itemType) eManifest.fetch_item_table('Session') );
        end

        function probeTable = get.ephys_probes(eManifest)
            probeTable = eManifest.fetch_cached('ephys_probes', ...
                @(itemType) eManifest.fetch_item_table('Probe'));
        end

        function channelTable = get.ephys_channels(eManifest)
            channelTable = eManifest.fetch_cached('ephys_channels', ...
                @(itemType) eManifest.fetch_item_table('Channel') );
        end

        function unitTable = get.ephys_units(eManifest)
            unitTable = eManifest.fetch_cached('ephys_units', ...
                @(itemType) eManifest.fetch_item_table('Unit') );
        end

    end
    

    %% Low-level getter method for EPhys item tables
    methods (Access = protected)

        function itemTable = fetch_item_table(eManifest, itemType)
        %fetch_item_table Fetch item table (get from cache or download)
        %
        %   itemTable = fetch_item_table(eManifest, itemType) fetches the
        %   item table (itemTable) for the given item type (itemType),
        %   either by retrieving from the disk cache, or by downloading and
        %   processing the table if it does not exist in the disk cache.
        %
        %   itemType must be a character vector or a string and must be one
        %   of the following:
        %       'Session', 'Probe', 'Channel', 'Unit'

            cache_key = eManifest.getManifestCacheKey(itemType);

            if eManifest.cache.IsObjectInCache(cache_key)
                itemTable = eManifest.cache.RetrieveObject(cache_key);

            else
                itemTable = eManifest.fetchAnnotatedItemTable(itemType);

                eManifest.cache.InsertObject(cache_key, itemTable);
                eManifest.clearTempTableFromCache(itemType)
            end

            % Apply standardized table display logic
            itemTable = eManifest.applyUserDisplayLogic(itemTable); 
        end

        function itemTable = fetchRawItemTable(eManifest, itemType)
        %fetchRawItemTable Download the item table and preprocess it
        
            itemTable = eManifest.download_item_table(itemType);

            fcnName = sprintf('%s.preprocess_ephys_%s_table', class(eManifest), lower(itemType)); % Static method
            itemTable = feval(fcnName, itemTable);
        end
            
        function itemTable = fetchJointItemTable(eManifest, itemType)
        %fetchRawItemTable Join a preprocessed item table with it's parent

            itemTable = eManifest.MemoizedFetcher.RawTable(itemType);

            % Join with upstream item table (parent node)
            fcnName = sprintf('join_ephys_%s_table_with_parent', lower(itemType));
            itemTable = feval(fcnName, eManifest, itemTable);
        end

        function itemTable = fetchAnnotatedItemTable(eManifest, itemType)
        %fetchAnnotatedItemTable Add counts of linked items to item table

            itemTable = eManifest.MemoizedFetcher.JointTable(itemType);
            
            % Add counts of linked items (child nodes) to item table
            fcnName = sprintf('add_linked_item_counts_to_%s_table', lower(itemType));
            itemTable = feval(fcnName, eManifest, itemTable);
        end

    end
    
    methods (Static, Access = protected)
        
        function dataTable = readS3ItemTable(cacheFilePath)
        %readS3ItemTable Read table from file downloaded from S3 bucket
        %
        %   Use readtable (ephys item tables are stored in csv files)
            dataTable = readtable(cacheFilePath);
        end
        
    end

    methods (Access = private) % Annotate - Add linked item counts for all downstream tables
        % Session - Probe - Channel 

        function session_table = add_linked_item_counts_to_session_table(eManifest, session_table)
            
            % Get joint tables for each of the children tables of session
            joint_probe_table = eManifest.MemoizedFetcher.JointTable('Probe');
            joint_channel_table = eManifest.MemoizedFetcher.JointTable('Channel');
            joint_unit_table = eManifest.MemoizedFetcher.JointTable('Unit');
            
            % - Count numbers of units, channels and probes
            session_table = count_owned(session_table, joint_unit_table, ...
                "id", "ephys_session_id", "unit_count");
            session_table = count_owned(session_table, joint_channel_table, ...
                "id", "ephys_session_id", "channel_count");
            session_table = count_owned(session_table, joint_probe_table, ...
                "id", "ephys_session_id", "probe_count");
            
            % - Get structure acronyms Todo?
            session_table = fetch_grouped_uniques(session_table, joint_channel_table, ...
                'id', 'ephys_session_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
        end

        function probe_table = add_linked_item_counts_to_probe_table(eManifest, probe_table)
            
            joint_channel_table = eManifest.MemoizedFetcher.JointTable('Channel');
            joint_unit_table = eManifest.MemoizedFetcher.JointTable('Unit');
            
            % - Count units and channels
            probe_table = count_owned(probe_table, joint_unit_table, ...
                'id', 'ephys_probe_id', 'unit_count');
            probe_table = count_owned(probe_table, joint_channel_table, ...
                'id', 'ephys_probe_id', 'channel_count');
            
            % - Get structure acronyms
            probe_table = fetch_grouped_uniques(probe_table, joint_channel_table, ...
                'id', 'ephys_probe_id', 'ephys_structure_acronym', 'ephys_structure_acronyms');
        end

        function channel_table = add_linked_item_counts_to_channel_table(eManifest, channel_table)
            
            joint_unit_table = eManifest.MemoizedFetcher.JointTable('Unit');
            
            % - Count owned units
            channel_table = count_owned(channel_table, ...
                joint_unit_table, 'id', 'ephys_channel_id', 'unit_count');
        end

        function unit_table = add_linked_item_counts_to_unit_table(~, unit_table)
            % No downstream tables - pass
        end
    
    end

    methods (Access = private) % Join with upstream table
        % For the join operation, we want to join the table with the table
        % one level up in the hierarchy. However, we can't join with the 
        % fully processed table, because it contains linked items count, 
        % and we dont want to include these! Therefore the memoized method
        % is used to obtain a table which is not fully processed.

        function annotated_session_table = join_ephys_session_table_with_parent(~, session_table)
            annotated_session_table = session_table;
            % No downstream tables - pass
        end

        function annotated_probe_table = join_ephys_probe_table_with_parent(eManifest, probe_table)
            
            session_table_raw = eManifest.MemoizedFetcher.RawTable('Session');

            annotated_probe_table = join(probe_table, session_table_raw, ...
                'LeftKeys', 'ephys_session_id', 'RightKeys', 'id');
        end

        function joint_channel_table = join_ephys_channel_table_with_parent(eManifest, channel_table)
            
            joint_probe_table = eManifest.MemoizedFetcher.JointTable('Probe');
            joint_channel_table = join(channel_table, joint_probe_table, ...
                'LeftKeys', 'ephys_probe_id', 'RightKeys', 'id');
        end

        function joint_unit_table = join_ephys_unit_table_with_parent(eManifest, unit_table)

            % - Annotate units
            joint_channel_table = eManifest.MemoizedFetcher.JointTable('Channel');

            joint_unit_table = join(unit_table, joint_channel_table, ...
                'LeftKeys', 'ephys_channel_id', 'RightKeys', 'id');
            
            % - Rename variables
            joint_unit_table = rename_variables(joint_unit_table, ...
                'name', 'probe_name', ...
                'phase', 'probe_phase', ...
                'sampling_rate', 'probe_sampling_rate', ...
                'lfp_sampling_rate', 'probe_lfp_sampling_rate', ...
                'local_index', 'peak_channel');
            
            % Apply upstream transformation, converting acronymys(cell arrays) to categoricals, since invalid units  have been filtered away   
            % TODO: Refactor ephys_structure_acronym handling to at least generalize between units & channels; possibly delegate to manifest
            joint_unit_table.ephys_structure_acronym = categorical(arrayfun(@(e)string(e{1}), joint_unit_table.ephys_structure_acronym));   
        end

    end

    methods (Static, Access = private) % Preprocess tables (restructure)

        function session_table = preprocess_ephys_session_table(session_table)
            
            num_sessions = size(session_table, 1);

            % - Label as EPhys sessions
            session_table = addvars(session_table, ...
                repmat(categorical({'EPhys'}, {'EPhys', 'OPhys'}), num_sessions, 1), ...
                'NewVariableNames', 'type', ...
                'before', 1);
            
            % - Get some specimen/subject info
            age_in_days = arrayfun(@(s)s.donor.age.days, session_table.specimen);
            cSex = arrayfun(@(s)s.donor.sex, session_table.specimen, 'UniformOutput', false);
            cGenotype = arrayfun(@(s)s.donor.full_genotype, session_table.specimen, 'UniformOutput', false);
            
            vbWT = cellfun(@isempty, cGenotype);
            if any(vbWT)
                cGenotype{vbWT} = 'wt';
            end
            
            % Get boolean flag for whether nwb file exists
            cWkf_types = arrayfun(@(s)s.well_known_file_type.name, session_table.well_known_files, 'UniformOutput', false);
            has_nwb = cWkf_types == "EcephysNwb";
            
            % - Add variables
            session_table = addvars(session_table, age_in_days, cSex, cGenotype, has_nwb, ...
                'NewVariableNames', {'age_in_days', 'sex', 'full_genotype', 'has_nwb'});
            
            % - Rename variables
            session_table = rename_variables(session_table, "stimulus_name", "session_type");
            
            % - Convert variables to useful types
            session_table.date_of_acquisition = datetime(session_table.date_of_acquisition,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
            session_table.id = uint32(session_table.id);
            session_table.isi_experiment_id = uint32(session_table.isi_experiment_id);
            session_table.published_at = datetime(session_table.published_at,'InputFormat','yyyy-MM-dd''T''HH:mm:ss''Z''','TimeZone','UTC');
            session_table.specimen_id = uint32(session_table.specimen_id);
            session_table.sex = categorical(session_table.sex, {'M', 'F'});
            session_table.session_type = categorical(session_table.session_type);
            session_table.full_genotype = string(session_table.full_genotype);

        end

        function probe_table = preprocess_ephys_probe_table(probe_table)
            
            % - Rename variables
            probe_table = rename_variables(probe_table, ...
                "use_lfp_data", "has_lfp_data", "ecephys_session_id", "ephys_session_id");
            
            % - Divide the lfp sampling by the subsampling factor for clearer presentation (if provided)
            if all(ismember({'lfp_sampling_rate', 'lfp_temporal_subsampling_factor'}, ...
                    probe_table.Properties.VariableNames))
                cfTSF = probe_table.lfp_temporal_subsampling_factor;
                if iscell(cfTSF)
                    cfTSF(cellfun(@isempty, cfTSF)) = {1};
                    vfTSF = cell2mat(cfTSF);
                else
                    cfTSF(isnan(cfTSF)) = 1;
                    vfTSF = cfTSF;
                end
                probe_table.lfp_sampling_rate = ...
                    probe_table.lfp_sampling_rate ./ vfTSF;
            end
            
            % - Convert variables to useful types
            probe_table.ephys_session_id = uint32(probe_table.ephys_session_id);
            probe_table.id = uint32(probe_table.id);
            probe_table.phase = categorical(probe_table.phase);
            probe_table.name= categorical(probe_table.name);
            
            ltsf = probe_table.lfp_temporal_subsampling_factor;
            if iscell(ltsf)
                [ltsf{cellfun(@isempty,ltsf)}] = deal(nan); %TODO: revisit if this shoudl be '1' replaced as above; for now, just focused on re-representing as a numeric array rather than cell array
                ltsf = cell2mat(ltsf);
            else
                % missing values are already nan
            end
            probe_table.lfp_temporal_subsampling_factor = ltsf;

            % - Convert has_lfp_data to logical if data is stored as 'True'
            % and 'False'
            if iscell( probe_table.has_lfp_data )
                if ischar( probe_table.has_lfp_data{1} )
                    if any(strcmp( probe_table.has_lfp_data{1}, {'True', 'False'}))
                        probe_table.has_lfp_data = strcmp(probe_table.has_lfp_data, 'True');
                    end
                end
            end
        end

        function channel_table = preprocess_ephys_channel_table(channel_table)
            
            % Todo: treat api and s3 result differently

            if any(strcmp(channel_table.Properties.VariableNames, 'ecephys_probe_id'))
                % Table was downloaded from s3, requires different processing

                % - Rename variables
                channel_table = rename_variables(channel_table, ...
                    'ecephys_probe_id', 'ephys_probe_id', ...
                    'ecephys_structure_id', 'ephys_structure_id', ...
                    'ecephys_structure_acronym', 'ephys_structure_acronym');
                
                % Convert to uint32
                varNames = {'id', 'ephys_probe_id', 'local_index', 'probe_horizontal_position', ...
                    'probe_vertical_position', 'anterior_posterior_ccf_coordinate', ...
                    'dorsal_ventral_ccf_coordinate', 'left_right_ccf_coordinate', ...
                    'ephys_structure_id'};
                
                for i = 1:numel(varNames)
                    channel_table.(varNames{i}) = uint32( channel_table.(varNames{i}) );
                end
            else % Table was downloaded from api

                % - Convert columns to reasonable formats
                id = uint32(cell2mat(cellfun(@str2num_nan, channel_table.id, 'UniformOutput', false)));
                ephys_probe_id = uint32(cell2mat(cellfun(@str2num_nan, channel_table.ephys_probe_id, 'UniformOutput', false)));
                local_index = uint32(cell2mat(cellfun(@str2num_nan, channel_table.local_index, 'UniformOutput', false)));
                probe_horizontal_position = uint32(cell2mat(cellfun(@str2num_nan, channel_table.probe_horizontal_position, 'UniformOutput', false)));
                probe_vertical_position = uint32(cell2mat(cellfun(@str2num_nan, channel_table.probe_vertical_position, 'UniformOutput', false)));
                anterior_posterior_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, channel_table.anterior_posterior_ccf_coordinate, 'UniformOutput', false)));
                dorsal_ventral_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, channel_table.dorsal_ventral_ccf_coordinate, 'UniformOutput', false)));
                left_right_ccf_coordinate = uint32(cell2mat(cellfun(@str2num_nan, channel_table.left_right_ccf_coordinate, 'UniformOutput', false)));
            
                ephys_structure_acronym = channel_table.ephys_structure_acronym;
            
                ephys_structure_id = uint32(cell2mat(cellfun(@str2num_nan, channel_table.ephys_structure_id, 'UniformOutput', false))); % so long as it's retained, convert from cell to numeric
                % TODO: consider removing ephys_structure_id altogether from table, after verifying it's fundamentally redundant
                % assert(isempty(setdiff(histcounts(ephys_structure_id),histcounts(categorical(cell2mat(ephys_structure_acronym))))));
                
                % - Rebuild table
                channel_table = table(id, ephys_probe_id, local_index, ...
                    probe_horizontal_position, probe_vertical_position, ...
                    anterior_posterior_ccf_coordinate, dorsal_ventral_ccf_coordinate, ...
                    left_right_ccf_coordinate, ephys_structure_id, ephys_structure_acronym);
            end
        end

        function unit_table = preprocess_ephys_unit_table(unit_table)
            
            % - Rename variables
            unit_table = rename_variables(unit_table, ...
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
            unit_table = ...
                unit_table(unit_table.amplitude_cutoff <= sFilterValues.amplitude_cutoff_maximum & ...
                unit_table.presence_ratio >= sFilterValues.presence_ratio_minimum & ...
                unit_table.isi_violations <= sFilterValues.isi_violations_maximum, :);
            
            if any(unit_table.Properties.VariableNames == "quality")
                unit_table = unit_table(unit_table.quality == "good", :);
            end
            
            if any(unit_table.Properties.VariableNames == "ephys_structure_id")
                unit_table = unit_table(~isempty(unit_table.ephys_structure_id), :);
            end
            
            % - Convert variables to useful types
            unit_table.ephys_channel_id = uint32(unit_table.ephys_channel_id);
            unit_table.id = uint32(unit_table.id);
            
            for var = string(unit_table.Properties.VariableNames)
                firstRowVal = unit_table{1,var};
                
                if iscellstr(unit_table.(var)) %#ok<ISCLSTR>
                    unit_table.(var) = string(unit_table.(var));
                elseif iscell(firstRowVal)
                    assert(isscalar(firstRowVal));
                    
                    if all(cellfun(@isnumeric,unit_table.(var)))
                        [unit_table.(var)(cellfun(@isempty,unit_table.(var)))] = deal({nan});
                        unit_table.(var) = cell2mat(unit_table.(var));
                    elseif any(cellfun(@ischar,unit_table.(var)))
                        unit_table.(var) = string_emptyNonChar(unit_table.(var));
                    end
                    
                end
            end
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