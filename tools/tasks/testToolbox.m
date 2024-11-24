function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = bottools.projectdir();
    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end
