function toolboxFolderPath = toolboxdir()

    thisFolderPath = fileparts( mfilename('fullpath') );
    filesepLoc = regexp(thisFolderPath, filesep);
        
    % Get path of folder 3 levels up:
    toolboxFolderPath = extractBefore(thisFolderPath, filesepLoc(end-2));
end
