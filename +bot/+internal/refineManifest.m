function manifest = refineManifest(manifest)
%REFINEMANIFEST Refine manifest table for public consumption/display

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

%% Reorder columns

varNames = setdiff(varNames,redundantVarNames,"stable");

% Identify variables containing string patterns identifying the kind of item info 
containsIDVars = varNames(varNames.contains("id") & ~varNames.matches("id"));
countVars = varNames(varNames.contains("count"));
dateVars = varNames(varNames.contains("date"));
typeVars = varNames(varNames.contains("type"));

% Identify variables with compound data
firstRowVals = table2cell(manifest(1,:));
compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
compoundVars = varNames(compoundVarIdxs);

% Create new column order
reorderedVars = ["id" containsIDVars countVars dateVars typeVars compoundVars]; 
newVarOrder = ["id" containsIDVars typeVars setdiff(varNames,reorderedVars,"stable") dateVars countVars compoundVars];


% Do reorder in one step
manifest = manifest(:,newVarOrder);

    
end








