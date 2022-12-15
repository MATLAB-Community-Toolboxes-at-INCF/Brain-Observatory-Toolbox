function reset(mode)
    arguments
        % Extra layer of precaution
        mode (1,1) string = "ask" % "ask" || "force"
    end
    bot.internal.cache.resetCache(mode)
    prefs = bot.getPreferences;
    prefs.reset()
end