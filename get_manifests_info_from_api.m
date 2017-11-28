% download contain_manifest, seesion_manifest, cell_speciman_mapping from brain observatory api as
% matlab tables, and store them in a struct called "references" for further
% reference

function manifests = get_manifests_info_from_api(varargin)

% manifests = get_manifests_info_from_api(varargin)
%
% a function makes manifets by fetching raw manifests from AllenAPI, and saves
% it to the direcotrty you want (I prefter BOT direcotry) optionally.

% make menifests if you want to save it in a dir that doesn't have
% it or you simply want to make it for some tempoprary use

% container_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::ExperimentContainer,rma::include,ophys_experiments,isi_experiment,specimen%28donor%28conditions,age,transgenic_lines%29%29,targeted_structure,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
% session_manifest_url = 'http://api.brain-map.org/api/v2/data/query.json?q=model::OphysExperiment,rma::include,experiment_container,well_known_files%28well_known_file_type%29,targeted_structure,specimen%28donor%28age,transgenic_lines%29%29,rma::options%5Bnum_rows$eq%27all%27%5D%5Bcount$eqfalse%5D';
% cell_id_mapping_url = 'http://api.brain-map.org/api/v2/well_known_file_download/590985414';
% 
% % - Download container manifest
% options1 = weboptions('ContentType','JSON','TimeOut',60);

% container_manifest_raw = webread(container_manifest_url,options1);

load manifests_raw.mat

%%
[manifests.container_manifest, sCategories] = convert_container_manifest(container_manifest_raw.msg);

% - Download session manifest
% session_manifest_raw = webread(session_manifest_url,options1);
[manifests.session_manifest, sCategories] = convert_session_manifest(session_manifest_raw.msg, sCategories);

% - Download cell ID mapping
% options2 = weboptions('ContentType','table','TimeOut',60);
manifests.cell_id_mapping = webread(cell_id_mapping_url,options2);

% - Create cre_line table from specimen field of session_manifest and
% append it back to session_manifest table
% cre_line is important, makes life easier if it's explicit

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

% - Convert columns to integer and categorical variables
manifests.session_manifest{:, 2} = uint32(manifests.session_manifest{:, 2});

end

   function [container_manifest, sCategories] = convert_container_manifest(sCM)
      % - Convert simple fields
      cFieldsClasses = {'failed'                  'logical';
                        'failed_facet'            'uint32';
                        'id'                      'uint32';
                        'imaging_depth'           'uint32';
                        'isi_experiment_id'       'uint32';
                        'specimen_id'             'uint32';
                        'targeted_structure_id'   'uint32';
                        'weight'                  'uint32'};
      cFieldData = convert_structure_classes(sCM, cFieldsClasses);
      container_manifest = cell2table(cFieldData, cFieldsClasses(:, 1));
      
      % - Convert complex fields
      [targeted_structure, sCategories] = convert_targeted_structure(sCM.targeted_structure, []);
   end

   function [targeted_structure, sCategories] = convert_targeted_structure(sTS, sCategories)
      % - Get a categorical array of targetted structure acronyms
      if isempty(sCategories) || ~isfield(sCategories, 'cTSAcronyms')
         sCategories.cTSAcronyms = categories(categorical({sTS.acronym}));
      end
      
      % - Convert simple fields
      cFieldsClasses = {'atlas_id'                       'uint32';
                        'color_hex_triplet'              [];
                        'depth'                          'uint32';
                        'failed'                         'logical';
                        'failed_facet'                   'uint32';
                        'graph_id'                       'uint32';
                        'graph_order'                    'uint32';
                        'hemisphere_id'                  'uint32';
                        'id'                             'uint32';
                        'name'                           [];
                        'neuro_name_structure_id'        [];
                        'neuro_name_structure_id_path'   [];
                        'ontology_id'                    'uint32';
                        'parent_structure_id'            'uint32';
                        'safe_name'                      'char';
                        'sphinx_id'                      'uint32';
                        'st_level'                       [];
                        'structure_id_path'              [];
                        'structure_name_facet'           'uint32';
                        'weight'                         'uint32'};
      targeted_structure = struct_cast(sTS, cFieldsClasses);
      
      % - Add categorical 'acronym' field
      cAcronyms = categorical({sTS.acronym}, sCategories.cTSAcronyms);
      [targeted_structure.acronym] = deal_array(cAcronyms);
   end

   function [session_manifest, sCategories] = convert_session_manifest(sSM, sCategories)
   
   end
   
   function cFieldData = struct_cast_to_cell(sData, cFieldsClasses)
   for nFieldIndex = size(cFieldsClasses, 1):-1:1
      if isempty(cFieldsClasses{nFieldIndex, 2})
         % - Do not cast
         cFieldData{nFieldIndex} = {sData(:).(cFieldsClasses{nFieldIndex, 1})};
         
      elseif isequal(cFieldsClasses{nFieldIndex, 2}, 'char')
         % - Convert a string field (assume string source)
         cFieldData{nFieldIndex} = {sData(:).(cFieldsClasses{nFieldIndex, 1})};
         
      else
         % - Convert a non-string field
         cFieldData{nFieldIndex} = cast([sData(:).(cFieldsClasses{nFieldIndex, 1})], cFieldsClasses{nFieldIndex, 2});
      end
   end
   end
   
   function sConvertedStruct = struct_cast(sData, cFieldsClasses)
   % - Cast fields
   cFieldData = struct_cast_to_cell(sData, cFieldsClasses);
   
   % - Convert back to structure
   sConvertedStruct = cell2struct(cFieldData, cFieldsClasses(:, 1));
   end
   
   function varargout = deal_array(array)
   varargout = num2cell(array);
   end


