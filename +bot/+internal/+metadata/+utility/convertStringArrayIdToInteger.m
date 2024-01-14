function X = convertStringArrayIdToInteger(X)
% convertStringArrayIdToInteger - Convert string array to integer array
%
%   Note: A few id variables in the Visual Behavior item tables are
%   sometimes numeric and sometimes cell arrays where each cell is a 
%   character array representation of a numeric vector of ids. 
%   This converter uses the appropriate method to convert to integer based
%   on the type of the provided id variable

if iscell(X)
    isEmpty = cellfun( @(c) isempty(c), X);
    X(isEmpty) = deal({'[]'});
    X = cellfun( @(c) uint32(eval(c)), X, 'uni', 0);
elseif isnumeric(X)
    X = uint32(X);
else
    error('Unknown/unhandled case.')
end
