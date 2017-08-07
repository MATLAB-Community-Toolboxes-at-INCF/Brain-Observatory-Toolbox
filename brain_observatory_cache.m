classdef brain_observatory_cache < handle
    
% add help file information!!!    
%    
%
% this will appear


    
    properties
        session_table
        container_table
        % selected_session_table has to be nonempty to aovid indexing
        % errors, the default value can be anything
        selected_session_table
        stimuli
        targeted_structure
        imaging_depth
        container_id
        session_id
        session_type
        references
    end
    
    properties (Access = private)
        failed = 0
        need_restriction_on_property = 1
    end
    
    methods
        
        % initialize
        function boc = brain_observatory_cache(references)
            
            boc.session_table = references.session_manifest;
            boc.container_table = references.container_manifest;
            boc.references = references;
            
            % get rid of failed ones
            if boc.failed == 0
                failed_container_id = boc.container_table((boc.container_table.failed == 1),:).id;
                boc.session_table = boc.session_table(~ismember(boc.session_table.experiment_container_id,failed_container_id),:);
                boc.container_table = boc.container_table((boc.container_table.failed ~= 1),:);          
            end
            
            boc.selected_session_table =  boc.session_table;
        end
        
        
        % This function gets the total number of experiment containers
        function result = get_total_of_containers(boc)
            result = size(boc.container_table(boc.container_table.failed==0,:),1);
        end
        
        
        
        function result = get_all_imaing_depths(boc)
            result = categories(categorical(cellstr(num2str((boc.container_table.imaging_depth)))));
        end
        
        
        
        function get_summary_of_containers_along_imaing_depths(boc)
            summary(categorical(cellstr(num2str((boc.container_table.imaging_depth)))))
        end
        
        
        
        function summary_table = get_summary_of_containers_along_depths_and_structures(boc)
            
            summary_matrix = NaN(size(boc.get_all_imaing_depths(),1),size(boc.get_all_targeted_structures(),1));
            all_depths = boc.get_all_imaing_depths();
            all_structures = boc.get_all_targeted_structures;
            boc.need_restriction_on_property = 0;
            
            
            for cur_depth = 1: size(boc.get_all_imaing_depths(),1)
                for cur_structure = 1: size(boc.get_all_targeted_structures,1)
                    boc.refresh();
                    boc.get_sessions_by_imaging_depth(str2double(cell2mat(all_depths(cur_depth))));
                    boc.get_sessions_by_targeted_structure(string(all_structures(cur_structure)));
                    total_of_containers = size(boc.selected_session_table,1)/3;
                    summary_matrix(cur_depth,cur_structure) = total_of_containers;
                end
            end
            
            
            summarize_by_depths = sum(summary_matrix,2);
            summary_matrix = [summary_matrix,summarize_by_depths];
            summarize_by_structures = sum(summary_matrix,1);
            summary_matrix = [summary_matrix; summarize_by_structures];
            summary_table = array2table(summary_matrix);
            summary_table.Properties.VariableNames = [all_structures;'total'];
            summary_table.Properties.RowNames = [all_depths;'total'];
            
        end
        
        
        
        
        function result = get.selected_session_table(boc)
            if boc.need_restriction_on_property == 1 && isempty(boc.selected_session_table)
                error(sprintf(['Not a single session meet all of your criteria\n'...
                    ' The last criterion has been declined\n '...
                    ' !!!This is not a bug. It is not my fault!!!\n'...
                    'Actually, if I do not yell at you for killing all sessions, Matlab will'...
                    ' yell at me for indexing an empty table.\n'...
                    'Sorry about that...']))
            else
                result = boc.selected_session_table;
            end
        end
        
        
        
        function refresh(boc)
            
            boc.session_table = boc.references.session_manifest;
            boc.container_table = boc.references.container_manifest;
            
            % remove failed containers
            if boc.failed == 0
                failed_container_id = boc.container_table((boc.container_table.failed == 1),:).id;
                boc.session_table = boc.session_table(~ismember(boc.session_table.experiment_container_id,failed_container_id),:);
                boc.container_table = boc.container_table((boc.container_table.failed ~= 1),:);
            end
            boc.selected_session_table =  boc.session_table;
            
        end
        
        
        
        function result = get_all_targeted_structures (boc)
            container_targeted_structure_table = struct2table(boc.container_table.targeted_structure);
            result = categories(categorical(cellstr(container_targeted_structure_table.acronym)));
        end
        
        
        
        function get_summary_of_container_along_targeted_structures (boc)
            container_targeted_structure_table = struct2table(boc.container_table.targeted_structure);
            summary(categorical(cellstr(container_targeted_structure_table.acronym)))
        end
        
        
        
        function result = get_all_session_types (boc)
            result = categories(categorical(cellstr((boc.session_table.stimulus_name))));
        end
        
        
        
        function result = get_all_stimuli (boc)
            session_by_stimuli = boc.get_session_by_stimuli();
            result = categories(categorical([session_by_stimuli.three_session_A,session_by_stimuli.three_session_B,...
                session_by_stimuli.three_session_C,session_by_stimuli.three_session_C2]));
        end
        
        
        
        function result = get_all_cre_lines (boc)
            result = categories(categorical(boc.container_table.cre_lines));
        end
        
        
        % get_session_by_session_id
        function boc = get_sessions_by_session_id(boc,session_id)
            
            boc.selected_session_table = boc.selected_session_table(boc.selected_session_table.id == session_id, :);
            boc.session_id = session_id;
            boc.container_id = boc.selected_session_table.experiment_container_id;
            
            % complete session_type when looked up a session
            boc.session_type = boc.selected_session_table.stimulus_name;
            
            % complete stimuli when looked up a session
            session_by_stimuli = boc.get_session_by_stimuli();
            boc.stimuli = session_by_stimuli.(char(boc.session_type));
            
            % complete imaging_depth when looked up a session
            boc.imaging_depth = boc.selected_session_table.imaging_depth;
        
            % complete targeted_structure when looked up a session
            boc.targeted_structure = boc.selected_session_table.targeted_structure.acronym;
        
        end
        
        
        
        function boc = get_sessions_by_container_id(boc,container_id)
            boc.selected_session_table = boc.selected_session_table(boc.selected_session_table.experiment_container_id == container_id, :);
            boc.container_id = container_id;
            
            % complete session_type when looked up a container
            boc.session_type = boc.selected_session_table.stimulus_name;
            
            % complete stimuli when looked up a container
            session_by_stimuli = boc.get_session_by_stimuli();
            all_stimuli_exist = {};
            
            for i = 1:length(boc.session_type)
                all_stimuli_exist = [all_stimuli_exist session_by_stimuli.(char(boc.session_type(i)))];
            end
            boc.stimuli = categories(categorical(all_stimuli_exist));
            
            % complete imaing_depth when looked up a container
            boc.imaging_depth = boc.selected_session_table.imaging_depth(1);
            
            % complete targeted_structure when looked up a container
            boc.targeted_structure = boc.selected_session_table.targeted_structure.acronym;
            
            % complete session_id when looked up a container
            boc.session_id = boc.selected_session_table.id;
        
        end
        
        
        
        function boc = get_sessions_by_stimuli(boc,stimuli)
            session_by_stimuli = boc.get_session_by_stimuli();
            % filter sessions by stimuli
            boc.selected_session_table =  boc.selected_session_table(ismember(boc.selected_session_table.stimulus_name,...
                boc.find_session_for_stimuli(stimuli,session_by_stimuli)), :);
            boc.stimuli = stimuli;
        end
        
        
        
        function boc = get_sessions_by_imaging_depth(boc,depth)
            % filter sessions by imaging_depth
            boc.selected_session_table = boc.selected_session_table(boc.selected_session_table.imaging_depth == depth, :);
            boc.imaging_depth = depth;
        end
        
        
        function boc = get_sessions_by_targeted_structure(boc,structure)
            % filter sessions by targeted_structure
            if size(boc.selected_session_table,1) > 1
                exp_targeted_structure_session_table = struct2table(boc.selected_session_table.targeted_structure);
                boc.selected_session_table = boc.selected_session_table(ismember(exp_targeted_structure_session_table.acronym, structure), :);
            elseif size(boc.selected_session_table,1) == 1
                boc.selected_session_table = boc.selected_session_table(strcmp( boc.selected_session_table.targeted_structure.acronym, structure),:);
            end
            boc.targeted_structure = structure;
        end
        
        
        function get_session_data(boc, save_directory_name)
            
            % prepare folder
            if ~exist(save_directory_name,'dir')
                mkdir(save_directory_name)
            end
            
            % get the NWB file URL for selected sessions
            allen_institute_base_url = 'http://api.brain-map.org';
            for cur = 1 : size(boc.selected_session_table,1)
                cur_url = boc.selected_session_table(cur, :). well_known_files.download_link;
                full_url = [allen_institute_base_url cur_url];
                cur_id = boc.selected_session_table(cur, :).id;
                save_file_name = [save_directory_name num2str(cur_id) '.nwb'];
                if ~exist(save_file_name,'file')
                    fprintf('downloading the nwb file')
                    tic
                    websave(save_file_name, full_url);
                    fprintf('the new nwb file is finally donwloaded')
                    toc
                else
                    fprintf('desired nwb file already exists')
                end
            end
        end
    end
    
    
    methods (Static  =  true, Access = private)
        
        function filtered_session = find_session_for_stimuli (stimuli,session_by_stimuli)
            filtered_session = {};
            fields = fieldnames(session_by_stimuli);
            for i = 1 :length(fields)
                if sum(ismember(session_by_stimuli.(char(fields(i))),stimuli)) >= 1
                    filtered_session(length(filtered_session)+1) = cellstr(fields(i));
                end
            end
        end
        
        function session_by_stimuli = get_session_by_stimuli()
            session_by_stimuli.three_session_A = {'drifting_gratings','natural_movie_one','natural_movie_three','spontaneous_activity'};
            session_by_stimuli.three_session_B = {'static_gratings','natural_scene','natural_movie_one','spontaneous_activity'};
            session_by_stimuli.three_session_C = {'locally_sparse_noise_four_degree','natural_movie_one','natural_movie_two','spontaneous_activity'};
            session_by_stimuli.three_session_C2 = {'locally_sparse_noise_four_degree','locally_sparse_noise_eight_degree', ...
                'natural_movie_one','natural_movie_two','spontaneous_activity'};
        end
    end % end of static method
end % end of class