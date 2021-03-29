function tbl = manifest2item(tbl)
% MANIFEST2ITEM Refine manifest table for display as an Item table

assert(isa(tbl,'table'),"The input manifest must be a table object");
 
varNames = string(tbl.Properties.VariableNames);


tbl.Properties.UserData = struct();

%% Remove columns whose values are "redundant" (the same for all rows); store these as table properties instead
redundantVarNames = string([]);

userDataString = "";

for col = 1:length(varNames)    
    
   if ~isstruct(tbl{1,col}) && ~iscell(tbl{1,col}) && numel(unique(tbl{:,col},'stable')) == 1 % all (non-compound) values in a column are equal 
       
       redundantVar = varNames(col);
       redundantVarNames = [redundantVarNames redundantVar]; %#ok<AGROW>
              
       %addfield(manifest.Properties.UserData,redundantVar);
       redundantVal = tbl{1,col};
       tbl.Properties.UserData.(redundantVar) = redundantVal;
       
      
       userDataString = userDataString + redundantVar + ": " + string(redundantVal) + " - ";              
   end     
end 
userDataString = userDataString.strip();
userDataString = userDataString.strip("-");
tbl.Properties.Description = userDataString;

tbl = removevars(tbl, redundantVarNames);

%% Remove columns repeating directory values (e.g. with OphysSession)

containsDirVars = varNames(varNames.contains("directory"));
tbl = removevars(tbl, containsDirVars);


%% Initialize refined variable lists (names, values)
refinedVars = setdiff(varNames,[redundantVarNames containsDirVars],"stable");
firstRowVals = table2cell(tbl(1,:));

%% Convert ephys_structure_acronym from cell types to the most string type possible (string type for scalars, cell array of strings for string lists)
 
varIdx = find(refinedVars.contains("structure_acronym"));
if varIdx    
    var = tbl.(refinedVars(varIdx));
    
    if iscell(var)
        if iscell(var{1}) % Handle string lists with empty last value (e.g. ephys session)
            
            % convert to cell string array
            assert(all(cellfun(@(x)isempty(x{end}),var))); % all the cell string arrays end with an empty double array, for reason TBD
            tbl.(refinedVars(varIdx)) = cellfun(@(x)x(1:end-1)',var,'UniformOutput',false);  % convert each cell element to string, skipping the ending empty double array
            
            % dereference to cell array of strings
            for ii=1:height(tbl)
                tbl{ii,varIdx}{1} = string(tbl{ii,varIdx}{1});
            end
            
        else % cell string arrays (almost)
            % Allow case where empty values are numerics
            assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),var)))));
            
            var2 = var;
            [var2{cellfun(@(x)~ischar(x), var)}] = deal('');
            tbl.(refinedVars(varIdx)) = string(var2);
        end
    end
end    


%% Reorder columns


% Identify variables containing string patterns identifying the kind of item info 
containsIDVars = refinedVars(refinedVars.contains("id") & ~refinedVars.matches("id"));
countVars = refinedVars(refinedVars.contains("count"));
dateVars = refinedVars(refinedVars.contains("date"));
typeVars = refinedVars(refinedVars.contains("type"));
stimVars = refinedVars(refinedVars.contains("stimulus"));
nameVars = refinedVars(refinedVars.matches("name"));

% Identify variables with compound data
compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
compoundVars = refinedVars(compoundVarIdxs);

% Create new column order
reorderedVars = ["id" containsIDVars countVars dateVars typeVars compoundVars nameVars stimVars]; 
newVarOrder = ["id" containsIDVars typeVars stimVars setdiff(refinedVars,reorderedVars,"stable") dateVars countVars nameVars compoundVars];


% Do reorder in one step
tbl = tbl(:,newVarOrder);

    
end








