% fetchChannels - FUNCTION Return the table of recorded channels
%
% Usage: channels = fetchChannels()
%
% `channels` will be the manifest table of EPhys channels.

function channels = fetchChannels(~)
   channels = bot.internal.manifest('ephys').ephys_channels;
end