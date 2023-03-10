% For BOT users: view gateway live script in interactive MATLAB
% For BOT testers: run gateway live script in batch MATLAB mode

if batchStartupOptionUsed
    bot.internal.README(); 
else
    edit bot.internal.README;
end
