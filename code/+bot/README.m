% For BOT users: view gateway live script in interactive MATLAB
% For BOT testers: run gateway live script in batch MATLAB mode

if batchStartupOptionUsed
    bot.internal.README(); % run the code
else
    edit bot.internal.README; % view the live script
end
