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
            
            %%  Convert _structure_id to _structure_acronym
                    
            areaIDVar = varNames(varNames.endsWith("_structure_id"));
            areaStrVar = replace(areaIDVar,"id","acronym");
            if ~isempty(areaIDVar)
                areaStructVar = varNames(varNames.endsWith("_structure"));
                
                assert(~isempty(areaStructVar) && isstruct(tbl.(areaStructVar)) && isfield(tbl.(areaStructVar),'acronym'));                 
                                
                %idVals = tbl.(areaIDVar);                                                           
                tbl.(areaIDVar) = categorical(string({tbl.(areaStructVar).acronym}')); % "structure" vars are scalar-valued, so can convert to categorical
                tbl = renamevars(tbl,areaIDVar,areaStrVar);                
            end           
            
            
            %% Initialize refined variable lists (names, values)
            refinedVars = setdiff(string(tbl.Properties.VariableNames),[redundantVarNames containsDirVars],"stable");
            
            %% Convert ephys_structure_acronym from cell types to string type
            % TODO: refactor to generalize this for all cell2str convers (some of which is currently implemented in ephysmanifest)
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
            
            IDVar = refinedVars(refinedVars.matches("id")); % the Item ID will be shown first
            experIDVars = refinedVars(refinedVars.endsWith("experiment_id")); % experiments are "virtual" items; these will be ordered towards end
            specimenIDVars = refinedVars(refinedVars.endsWith("specimen_id")); % specimen structures are part of compound types at end; these will be ordered just before
            %structIDVars = refinedVars(refinedVars.endsWith("structure_id")); % specimen structures are part of compound types at end; these will be ordered just before
            
            linkedItemIDVars = setdiff(refinedVars(refinedVars.endsWith("id")), [IDVar experIDVars specimenIDVars]);
                
            countVars = refinedVars(refinedVars.contains("count")); % counts of linked items
            dateVars = refinedVars(refinedVars.contains("date"));
            typeVars = refinedVars(refinedVars.contains("_type")); % specifies some type of the item, i.e. a categorical
            genotypeVars = refinedVars(refinedVars.endsWith(["genotype" "cre_line"])); % specifies some type of the item, i.e. a categorical
            stimVars = refinedVars(refinedVars.contains("stimulus")); % specifies external stimulus applied for the item           
            
            structVars = refinedVars(refinedVars.contains("structure")); %& ~refinedVars.endsWith("id")); % lists out brain structure(s) associated to the item in a stringish way
            longStructVars = string();
            shortStructVars = string();
            for var = structVars
                if iscategorical(tbl.(var))
                    shortStructVars = [shortStructVars var]; %#ok<AGROW>
                elseif isstring(tbl.(var)) 
                    if mean(strlength(tbl.(var))) > 10
                        longStructVars = [longStructVars var]; %#ok<AGROW>
                    else
                        shortStructVars = [shortStructVars var]; %#ok<AGROW>
                    end
                else
                    % no-op (for the brain structure id & struct vars in ophys)
                end
            end                                               
            
            
            nameVars = refinedVars(refinedVars.matches("name")); 
            longNameVars = string();
            shortNameVars = string();
            for var = nameVars
                if iscategorical(tbl.(var))
                    shortNameVars = [shortNameVars var]; %#ok<AGROW>
                elseif isstring(tbl.(var)) 
                    if mean(strlength(tbl.(var))) > 10
                        longNameVars = [longNameVars var]; %#ok<AGROW>
                    else
                        shortNameVars = [shortNameVars var]; %#ok<AGROW>
                    end
                else
                    assert(false);
                end
            end                                               
            
            reorderedVars = [IDVar linkedItemIDVars experIDVars specimenIDVars  countVars dateVars typeVars genotypeVars stimVars longNameVars shortNameVars shortStructVars longStructVars];
            
            % Identify any remaining variables with compound data
            firstRowVals = table2cell(tbl(1,:));
            compoundVarIdxs = cellfun(@(x)isstruct(x) || iscell(x),firstRowVals);
            compoundVars = setdiff(refinedVars(compoundVarIdxs), reorderedVars);
            
            % Create new column order
            reorderedVars = [reorderedVars compoundVars];
            newVarOrder = [IDVar linkedItemIDVars countVars typeVars shortNameVars shortStructVars setdiff(refinedVars,reorderedVars,"sort") genotypeVars  longStructVars stimVars experIDVars dateVars longNameVars specimenIDVars compoundVars];
            newVarOrder(newVarOrder.strlength == 0) = [];
            
            % Do reorder in one step
            tbl = tbl(:,newVarOrder);
            
            
        end
        
    end
    
    
end
