function T = castTableVariables(T, varNames, typeName)
     
    if ischar(varNames); varNames = {varNames}; end
    
    for i = 1:numel(varNames)
        thisName = varNames{i};
        T.(thisName) = feval(typeName, T.(thisName));
    end
end