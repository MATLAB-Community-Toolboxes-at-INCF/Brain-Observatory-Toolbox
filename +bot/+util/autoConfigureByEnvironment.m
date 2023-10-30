function autoConfigureByEnvironment()
    
    currentUsername = getUserName();

    if string(currentUsername) == "mluser"
        scratchDirectoryPath = "/Data/BOT_Cache_Temp";
        initializeScratchDirectory(scratchDirectoryPath)
        %cleanupObject = onCleanup(@teardownScratchDirectory);
    end
end

function currentUsername = getUserName()
    [~, currentUsername] = system('whoami');
    currentUsername = strtrim(currentUsername);
end

function initializeScratchDirectory(directoryPath)

    % Create folder for scratch directory if it does not exist
    if ~isfolder(directoryPath); mkdir(directoryPath); end
    
    % Add value to preferences
    prefs = bot.util.getPreferences();
    prefs.ScratchDirectory = directoryPath;
end

function teardownScratchDirectory() %#ok<DEFNU>
    prefs = bot.internal.Preferences();
    prefs.ScratchDirectory = "";
end