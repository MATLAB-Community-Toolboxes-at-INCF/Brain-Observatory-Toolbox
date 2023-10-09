function reset(mode)
    arguments
        % Extra layer of precaution
        mode (1,1) string = "ask" % "ask" || "force"
    end
    bot.internal.Cache.resetCache(mode)
    prefs = bot.util.getPreferences();
    prefs.reset()
end