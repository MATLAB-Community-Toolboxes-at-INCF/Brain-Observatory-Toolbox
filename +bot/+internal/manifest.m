% manifest — Create or download a manifest from the Allen Brain Observatory

classdef manifest < handle 

    
    %% STATIC METHODS - PUBLIC
    methods (Static)

        function manifest = instance(type)
            
            arguments
                type (1,1) string {mustBeMember(type, ["ephys" "ophys"])}
            end
            
            switch(lower(type))
                case 'ophys'
                    manifest = bot.internal.ophysmanifest.instance();
                    
                case 'ephys'
                    manifest = bot.internal.ephysmanifest.instance();
                    
                otherwise
                    error('`manifest_type` must be one of {''ophys'', ''ephys''}');
            end
        end         
        
        function tbl = applyUserDisplayLogic(tbl)
            % Refine manifest table for user display as a table of Items
            
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
            
            %% Convert ephys_structure_acronym from cell types to string type
            
            varIdx = find(refinedVars.contains("structure_acronym"));
            if varIdx
                var = tbl.(refinedVars(varIdx));
                
                if iscell(var)
                    if iscell(var{1}) % case of: cell string array with empty last value (ephys session case)
                        
                        % convert to cell string array
                        assert(all(cellfun(@(x)isempty(x{end}),var))); % all the cell string arrays end with an empty double array, for reason TBD
                        tbl.(refinedVars(varIdx)) = cellfun(@(x)join(string(x(1:end-1))',"; "),var); % convert each cell element to string, skipping the ending empty double array
                        
                    else % case of: 'almost' cell string arrays, w/ empty values represented as numerics
                        assert(all(cellfun(@isempty,var(cellfun(@(x)~ischar(x),var)))));
                        
                        var2 = var;
                        [var2{cellfun(@(x)~ischar(x), var)}] = deal('');
                        tbl.(refinedVars(varIdx)) = string(var2);
                    end
                end
            end                                               
            
            %% Reorder columns
            
            %TODO: reimplement the mapping of string patterns to variable types programatically as a containers.Map
            
            % Identify variables containing string patterns identifying the kind of item info
            containsIDVars = refinedVars(refinedVars.contains("id") & ~refinedVars.matches("id") & ~refinedVars.contains("structure")); % the "id" var & brain structure vars will be handled separately
            countVars = refinedVars(refinedVars.contains("count")); % counts of linked items
            dateVars = refinedVars(refinedVars.contains("date"));
            typeVars = refinedVars(refinedVars.contains("type")); % specifies some type of the item, i.e. a categorical
            stimVars = refinedVars(refinedVars.contains("stimulus")); % specifies external stimulus applied for the item
            nameVars = refinedVars(refinedVars.matches("name")); % a string variable associated to each item in Visual Coding - 2P
            structVars = refinedVars(refinedVars.contains("structure")); % specifies the brain structure(s) associated to the item
            
            reorderedVars = ["id" containsIDVars countVars dateVars typeVars stimVars nameVars structVars];
            
            % Identify any remaining variables with compound data
            firstRowVals = table2cell(tbl(1,:));
            compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
            compoundVars = setdiff(refinedVars(compoundVarIdxs), reorderedVars);
            
            % Create new column order
            reorderedVars = [reorderedVars compoundVars];
            newVarOrder = ["id" containsIDVars typeVars stimVars setdiff(refinedVars,reorderedVars,"stable") structVars dateVars countVars nameVars compoundVars];
            
            % Do reorder in one step
            tbl = tbl(:,newVarOrder);
            
            
        end
        
    end
    
    
end
