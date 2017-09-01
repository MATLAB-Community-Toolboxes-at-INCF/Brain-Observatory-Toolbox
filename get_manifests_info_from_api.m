% download contain_manifest, seesion_manifest, cell_speciman_mapping from brain observatory api as
% matlab tables, and store them in a struct called "references" for further
% reference

function manifests = get_manifests_info_from_api(varargin)

% manifests = get_manifests_info_from_api(varargin)
% 
% a function makes manifets by fetching raw manifests from AllenAPI, and saves
% it to the direcotrty you want (I prefter BOT direcotry) optionally.


tic
if (nargin > 0 && ~exist([char(varargin) 'manifests.mat'],'file'))|| nargin == 0
    
    % make menifests if you want to save it in a dir that doesn't have
    % it or you simply want to make it for some tempoprary use
    
    container_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::ExperimentContainer,rma::include,ophys_experiments,isi_experiment,specimen%28donor%28conditions,age,transgenic_lines%29%29,targeted_structure,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
    session_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::OphysExperiment,rma::include,experiment_container,well_known_files%28well_known_file_type%29,targeted_structure,specimen%28donor%28age,transgenic_lines%29%29,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
    cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';
    
    options1 = weboptions('ContentType','JSON','TimeOut',60);
    
    container_manifest_raw = webread(container_manifest_url,options1);
    manifests.container_manifest = struct2table(container_manifest_raw.msg);
    
    session_manifest_raw = webread(session_manifest_url,options1);
    manifests.session_manifest = struct2table(session_manifest_raw.msg);
    
    options2 = weboptions('ContentType','table','TimeOut',60);
    
    manifests.cell_id_mapping = webread(cell_id_mapping_url,options2);
    
    % create cre_line table from specimen field of session_manifest and
    % append it back to session_manifest table
    % cre_line is important,make my life easier if it's explicit
    
    session_table = manifests.session_manifest;
    cre_line = cell(size(session_table,1),1);
    for i = 1:size(session_table,1)
        donor_info = session_table(i,:).specimen.donor;
        transgenic_lines_info = struct2table(donor_info.transgenic_lines);
%         cre_line(i,1) = transgenic_lines_info.name(string(transgenic_lines_info.transgenic_line_type_name) == 'driver' & ...
%             contains(transgenic_lines_info.name, 'Cre'));
        cre_line(i,1) = transgenic_lines_info.name(not(cellfun('isempty', strfind(transgenic_lines_info.transgenic_line_type_name, 'driver')))...
            & not(cellfun('isempty', strfind(transgenic_lines_info.name, 'Cre'))));
    end
    
    manifests.session_manifest = [session_table, cre_line];
    manifests.session_manifest.Properties.VariableNames{'Var15'} = 'cre_line';
    
    if nargin == 1
        % save it to the direcotry you specified 
    save([char(varargin) 'manifests.mat'],'manifests')
    toc
    end
    
else 
    fprintf([char(varargin) 'manifests.mat' ' already exists'])
    
end

end



