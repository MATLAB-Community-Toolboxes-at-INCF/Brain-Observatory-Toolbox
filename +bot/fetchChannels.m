% fetchChannels - FUNCTION Return the table of recorded channels
%
% Usage: channels = fetchChannels()
%
% `channels` will be the manifest table of EPhys channels.

function channels = fetchChannels(~)
   manifest = bot.internal.manifest.instance('ephys');
   channels = manifest.ephys_channels;
end