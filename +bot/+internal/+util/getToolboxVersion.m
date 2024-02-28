function [versionStr, versionNumber] = getToolboxVersion()
% getToolboxVersion - Get toolbox version for the Brain Observatory Toolbox
%
%   Syntax:
%       versionStr = bot.internal.util.getToolboxVersion() returns the
%           version as a char in the format of '<major>.<minor>.<patch>', 
%           e.g. '0.9.4'
%
%       [versionStr, versionNumber] = bot.internal.util.getToolboxVersion()
%           additionally returns a numeric vector where each element is a
%           version number ([major, minor, patch]), e.g [0, 9, 4];

    % Check if multiple versions of the toolbox is on MATLAB's search path.
    pathList = which(fullfile('+bot', 'getSessions.m'), '-all');
    if numel(pathList) > 1
        pathList = fileparts(fileparts(pathList));
        error('BOT:MultipleVersionsOnPath', ...
            ['Multiple versions of the Brain Observatory Toolbox ', ...
            'was found on the search path:\n%s\n\nPlease make sure ', ...
            'that only one version of the Brain Observatory Toolbox is on ', ...
            'MATLAB''s search path.'], strjoin(strcat({'    '}, pathList), newline))
    end

    [~, toolboxFolderName] = fileparts( bot.internal.util.toolboxdir );
    
    S = ver(toolboxFolderName);
    
    if numel(S) > 1
        error('BOT:MultipleVersionsOnPath', ...
            ['Multiple versions of the Brain Observatory Toolbox ', ...
            'was found on the search path.'])
    elseif isempty(S)
        % The Contents.m file might not be on the search path, locate and
        % read it manually.
        contentsFilePath = fullfile(bot.internal.util.toolboxdir, 'Contents.m');
        contentsStr = fileread(contentsFilePath);
        
        % First try to get a version with a sub-patch version number
        versionStr = regexp(contentsStr, '(?<=Version )\d+\.\d+\.\d+.\d+(?= )', 'match', 'once');
    
        % If not found, get major-minor-patch
        if isempty(versionStr)
            versionStr = regexp(contentsStr, '(?<=Version )\d+\.\d+\.\d+(?= )', 'match', 'once');
        end

        if isempty(versionStr)
            error('BOT:Version:VersionNotFound', ...
                'No version was detected for this Brain Observatory Toolbox installation.')
        end
    else
        versionStr = S.Version;
    end

    versionNumber = cellfun(@(c) str2double(c), strsplit(S.Version, '.'));
    if nargout < 2
        clear versionNumber
    end
end