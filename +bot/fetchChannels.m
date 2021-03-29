% fetchChannels - FUNCTION Return the table of recorded channels
%
% Usage: channels = fetchChannels()
%
% `channels` will be the manifest table of EPhys channels.

function channels = fetchChannels(~)
   tbl = bot.internal.manifest('ephys').ephys_channels;
   channels = bot.internal.manifest2item(tbl);

end