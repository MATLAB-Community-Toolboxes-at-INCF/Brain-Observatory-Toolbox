% channel — Return a channel object from the Allen Brain Observatory EPhys data set
%
% Usage: new_channel = channel(channel_id)
%
% `channel_id` is a channel ID from the Allen Brain Observatory EPhys data
% set.  A lightweight channel ojbect `new_channel` is returned, containing
% metadata about the data recorded from the corresponding channel in the
% experiment.

function new_channel = channel(channel_id)
new_channel = bot.item.ephyschannel(channel_id);
