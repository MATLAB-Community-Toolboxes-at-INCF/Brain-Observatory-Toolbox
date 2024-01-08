function [versionStr, versionNumber] = getToolboxVersion()
    
    [~, toolboxFolderName] = fileparts( bot.internal.util.toolboxdir );

    S = ver(toolboxFolderName);
    versionStr = S.Version;
    versionNumber = cellfun(@(c) str2double(c), strsplit(S.Version, '.'));
    if nargout < 2
        clear versionNumber
    end
end