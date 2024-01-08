function tf = isVerLessThan(version, referenceVersion)
% isVerLessThan Check if a version string is lower than a reference version string
%
%   Inputs:
%       version             : character vector; example '0.9.3'
%       referenceVersion    : character vector; example '0.9.4'
%
% Adapted from builtin "verLessThan"

    versionParts = getParts(char(version));
    referenceVersionParts = getParts(char(referenceVersion));

    if versionParts(1) ~= referenceVersionParts(1)      % major version
        tf = versionParts(1) < referenceVersionParts(1);
    elseif versionParts(2) ~= referenceVersionParts(2)  % minor version
        tf = versionParts(2) < referenceVersionParts(2);
    else                                                % revision version
        tf = versionParts(3) < referenceVersionParts(3);
    end

    function parts = getParts(V)
        parts = sscanf(V, '%d.%d.%d')';
        if length(parts) < 3
            parts(3) = 0; % zero-fills to 3 elements
        end
    end
end