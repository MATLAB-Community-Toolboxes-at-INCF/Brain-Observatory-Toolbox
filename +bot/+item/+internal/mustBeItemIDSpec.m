function  mustBeItemIDSpec(val)
%MUSTBEITEMIDSPEC Validation function for items specified to BOT item factory functions for item object array construction


eidTypePrefix = "mustBeBOTItemId:";
eidTypeSuffix = "";
msgType = "";

if istable(val)
    if ~ismember(val.Properties.VariableNames, 'id')
        eidTypeSuffix = "invalidItemTable";
        msgType = "Table supplied not recognized as a valid BOT Item information table";        
    end   
elseif ~isnumeric(val) || ~isvector(val) || ~all(isfinite(val)) || any(val<=0) 
    eidTypeSuffix = "invalidItemIDs";
    msgType = "Must specify BOT item object(s) to create with either a numeric vector of valid ID values or a valid Item information table";
elseif ~isinteger(val) && ~all(round(val)==val)    
    eidTypeSuffix = "invalidItemIDs";
    msgType = "Must specify BOT item object(s) to create with either a numeric vector of valid ID values or a valid Item information table";
end


% Throw error 
if strlength(msgType) > 0
    throwAsCaller(MException(eidTypePrefix + eidTypeSuffix,msgType));
end
