% Open Getting Started live script

if batchStartupOptionUsed
    disp("Getting started live script not available in batch mode.")
else
    open(fullfile('.',filesep,'GettingStarted.mlx'));
end