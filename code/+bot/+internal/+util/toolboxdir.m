function toolboxFolderPath = toolboxdir()

    thisFolderPath = fileparts( mfilename('fullpath') );
    splitFolderPath = strsplit(thisFolderPath, filesep);
    
    % Move 3 folders up:
    toolboxFolderPath = fullfile( splitFolderPath{1:end-3} );
end
