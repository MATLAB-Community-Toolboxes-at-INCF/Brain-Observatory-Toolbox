function folderPath = botProjectdir()
% projectdir - Get project root directory for a matlab toolbox code repository
    folderPath = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end
