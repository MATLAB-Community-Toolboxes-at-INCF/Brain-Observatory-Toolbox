function codecheckToolbox()
    installMatBox()
    projectRootDirectory = bottools.projectdir();
    matbox.tasks.codecheckToolbox(projectRootDirectory)
end
