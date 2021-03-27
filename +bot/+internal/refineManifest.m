function manifest = refineManifest(manifest)
%REFINEMANIFEST Refine manifest table for public consumption/display

assert(isa(manifest,'table'),"The input manifest must be a table object");
 
varNames = string(manifest.Properties.VariableNames);

manifest.Properties.UserData = struct();

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
    
end








