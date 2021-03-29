function manifest = refineManifest(manifest)
% MANIFEST2ITEM Refine manifest table for display as an Item table

assert(isa(manifest,'table'),"The input manifest must be a table object");
 
varNames = string(manifest.Properties.VariableNames);


manifest.Properties.UserData = struct();

%% Remove columns whose values are "redundant" (the same for all rows); store these as table properties instead
redundantVarNames = string([]);

for col = 1:length(varNames)    
    
   if ~isstruct(manifest{1,col}) && ~iscell(manifest{1,col}) && numel(unique(manifest{:,col},'stable')) == 1 % all (non-compound) values in a column are equal 
       
       redundantVar = varNames(col);
       redundantVarNames = [redundantVarNames redundantVar]; %#ok<AGROW>
              
       %addfield(manifest.Properties.UserData,redundantVar);
       manifest.Properties.UserData.(redundantVar) = manifest{1,col};
   end     
end    

manifest = removevars(manifest, redundantVarNames);

%% Initialize refined variable lists (names, values)
refinedVars = setdiff(varNames,redundantVarNames,"stable");
firstRowVals = table2cell(manifest(1,:));

%% Convert ephys_structure_acronym from cell types to the most string type possible (string type for scalars, cell array of strings for string lists)
 
varIdx = find(refinedVars.contains("structure_acronym"));
if varIdx    
    var = manifest.(refinedVars(varIdx));
    
    if iscell(var)
        if iscell(var{1}) % Handle string lists with empty last value (e.g. ephys session)
            
            % convert to cell string array
            assert(all(cellfun(@(x)isempty(x{end}),var))); % all the cell string arrays end with an empty double array, for reason TBD
            manifest.(refinedVars(varIdx)) = cellfun(@(x)x(1:end-1)',var,'UniformOutput',false);  % convert each cell element to string, skipping the ending empty double array
            
            % dereference to cell array of strings
            for ii=1:height(manifest)
                manifest{ii,varIdx}{1} = string(manifest{ii,varIdx}{1});
            end
            
        else % cell string arrays (almost)
            % Allow case where empty values are numerics
            assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),var)))));
            
            var2 = var;
            [var2{cellfun(@(x)~ischar(x), var)}] = deal('');
            manifest.(refinedVars(varIdx)) = string(var2);
        end
    end
end    


%% Reorder columns


% Identify variables containing string patterns identifying the kind of item info 
containsIDVars = refinedVars(refinedVars.contains("id") & ~refinedVars.matches("id"));
countVars = refinedVars(refinedVars.contains("count"));
dateVars = refinedVars(refinedVars.contains("date"));
typeVars = refinedVars(refinedVars.contains("type"));

% Identify variables with compound data
compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
compoundVars = refinedVars(compoundVarIdxs);

% Create new column order
reorderedVars = ["id" containsIDVars countVars dateVars typeVars compoundVars]; 
newVarOrder = ["id" containsIDVars typeVars setdiff(refinedVars,reorderedVars,"stable") dateVars countVars compoundVars];


% Do reorder in one step
manifest = manifest(:,newVarOrder);

    
end








