function prefs = getPreferences()
%getPreferences Get preferences for the Brain Observatory Toolbox
%
%   prefs = getPreferences() returns an instance of the Preferences for the
%   Brain Observatory Toolbox. 
%
%   See also <a href="matlab:help bot.internal.Preferences" style="font-weight:bold">BOT Preferences</a>

    prefs = bot.internal.Preferences.getSingleton();
end