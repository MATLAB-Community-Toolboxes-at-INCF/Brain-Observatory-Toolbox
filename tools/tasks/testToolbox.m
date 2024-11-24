function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = bottools.projectdir();

    addpath(fullfile(projectRootDirectory, 'code'))
    botPrefs = bot.util.getPreferences();
    if botPrefs.CacheDirectory == "" || ~isfolder(botPrefs.CacheDirectory)
        botPrefs.DialogMode = "Command Window";
        tempCache = fullfile(tempdir, 'bot-cache');
        if ~isfolder(tempCache); mkdir(tempCache); end
        cleanupObj = onCleanup(@(fp) rmdir(tempCache, "s"));
    end

    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end
