function prefValue = getPreferenceValue(preferenceName)
%getPreferenceValue Get value for a preference
%
%   prefs = getPreferenceValue(preferenceName) returns the preference value 
%   for the given preference name.
%
%   See also <a href="matlab:help bot.internal.Preferences" style="font-weight:bold">BOT Preferences</a>

    arguments
        preferenceName (1,1) string
    end

    preferences = bot.internal.Preferences.getSingleton();
    
    if isprop(preferences, preferenceName)
        prefValue = preferences.(preferenceName);
    else
        error('There is no preferences with name "%s" in the preferences for the Brain Observatory Toolbox', preferenceName)
    end
end

