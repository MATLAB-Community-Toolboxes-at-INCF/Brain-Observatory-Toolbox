function prefs = getPreferences(preferenceName)
%getPreferences Get preferences for the Brain Observatory Toolbox
%
%   prefs = getPreferences() returns an instance of the Preferences for the
%   Brain Observatory Toolbox. 
%
%   prefs = getPreferences(preferenceName) returns the preference value for
%   the given preference name.
%
%   See also <a href="matlab:help bot.internal.Preferences" style="font-weight:bold">BOT Preferences</a>


    prefs = bot.internal.Preferences.getSingleton();
    
    if nargin && ~isempty(preferenceName)
        if isprop(prefs, preferenceName)
            prefs = prefs.(preferenceName);
        else
            error('There is no preferences with name "%s" in the preferences for the Brain Observatory Toolbox', preferenceName)
        end
    end
end