function testToolbox(varargin)
    installMatBox()
    projectRootDirectory = bottools.projectdir();

    botPrefs = bot.util.getPreferences();
    if isempty(botPrefs.CacheDirectory)
        botPrefs.DialogMode = "Command Window";
        tempCache = fullfile(tempdir, 'bot-cache');
        if ~isfolder(tempCache); mkdir(tempCache); end
        cleanupObj = onCleanup(@(fp) rmdir(tempCache, "s"));
    end

    matbox.tasks.testToolbox(projectRootDirectory, varargin{:})
end
