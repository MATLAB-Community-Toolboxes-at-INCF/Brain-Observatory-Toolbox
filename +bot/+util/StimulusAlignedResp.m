function mfAlignedResp = StimulusAlignedResp(tStimulus, mfResp, fhMetric, vnFluoresenceTimeIndices, bPermitUnclean)

% StimulusAlignedResp - FUNCTION Return a matrix of responses, aligned over a set of stimulus presentations
%
% Usage: mfAlignedResp = StimulusAlignedResp(tStimulus, mfResp <, fhMetric, vnFluoresenceTimeIndices, bPermitUnclean>)
%
% This function accepts a matrix `mfResp` of calcium responses (or inferred
% spikes), and computes the average response for a set of stimulus
% presentations defined in `tStimulus`.
%
% `mfResp` is a matrix [TxN], each column of which contains the response
% over time for a single ROI (N ROIs and T time bins in total). `tStimulus`
% is a table as returned by the `bot.session.get_stimulus_table()` method,
% with stimulus presentation periods defined by columns 'start_frame' and
% 'end_frame'. These indices refer to fluorescence frame indices, as
% returned by the `bot.session.get_fluorescence_timestamps()` method.
%
% The response frames corresponding to a single stimulus presentation are
% collated, and processed with the function `fhMetric`. By default
% `fhMetric` is `nanmean`. An alternative metric can be provided as a
% function handle with the signature `vfStimResp = fhMetric(mfRawResp)`.
% The metric function must accept a [UxN] matrix `mfRawResp`, where N is
% the number of ROIs as above, and U is an arbitrary number of frames. It
% must return an [Nx1] vector `vfStimResp`, containing the stimulus
% response for each ROI.
%
% The optional argument `vnFluoresenceTimeIndices` can be used to specify
% which fluorescence time indices correspond to each row in `mfResp`. By
% default, this is simply 1:size(mfResp, 1). This argument can be used if
% `mfResp` contains only a temporal subset of the full session responses.
%
% The optional argument `bPermitUnclean` can be used to control whether
% only clean response frames are returned. "Clean" frames are responses
% frames that only correspond to a single stimulus presentation.
% "Non-clean" frames are response frames that span multiple stimulus
% presenatations. By default (bPermitUnclean = false), non-clean response
% frames are replaced with NaNs.
%
% `mfAlignedResp` will be a [VxN] matrix, where N is the number of ROIs and
% V is the number of stimulus presentations.

% - Set defaults, check arguments
if ~exist('fhMetric', 'var') || isempty(fhMetric)
   fhMetric = @(x)nanmean(x, 1);
end

if ~exist('vnFluoresenceTimeIndices', 'var') || isempty(vnFluoresenceTimeIndices)
   vnFluoresenceTimeIndices = 1:size(mfResp, 1);
end

if ~exist('bPermitUnclean', 'var') || isempty(bPermitUnclean)
   bPermitUnclean = false;
end

if numel(vnFluoresenceTimeIndices) ~= size(mfResp, 1)
   error('BOT:Usage', ...
         'The number of frames in `vnFluoresenceTimeIndices` must match the number of rows in `mfResp`.');
end

% - Which flourescence frames are dirty? i.e. fluorescence frame overlaps
% multiple stimuli

if bPermitUnclean
   vbDirtyEnd = false(size(tStimulus, 1)-1, 1);
else
   vbDirtyEnd = tStimulus{1:end-1, 'end_frame'} == tStimulus{2:end, 'start_frame'};
end

vbDirtyStart = [false; vbDirtyEnd(1:end)];
vbDirtyEnd = [vbDirtyEnd; false];

% - Helper function for finding "clean" response frames (where the stimulus
% did not change mid-frame)
   function vnFluorFrames = clean_frames(nStart, nEnd, bDirtyStart, bDirtyEnd)
      [~, vnFluorFrames] = ismember((double(nStart) + double(bDirtyStart)):(double(nEnd) - double(bDirtyEnd)), vnFluoresenceTimeIndices);
   end

% - Get lists of clean fluorescence frames for each stimulus presentation period
cvnFluorFrameInds = arrayfun(@clean_frames, tStimulus.('start_frame'), tStimulus.('end_frame'), vbDirtyStart, vbDirtyEnd, 'UniformOutput', false);

% - Helper function for computing the stimulus response metric over a set
% of frames
   function vfThisResp = stim_metric(vnFrameInds)
      [~, vnRespInds] = ismember(vnFrameInds, vnFluoresenceTimeIndices);
      vfThisResp = fhMetric(mfResp(vnRespInds, :));
   end

% - Process lists of fluorescence frames and compute metric
cmfAlignedResp = cellfun(@stim_metric, cvnFluorFrameInds, 'UniformOutput', false);
mfAlignedResp = cell2mat(cmfAlignedResp);

end

% --- END of StimulusAlignedResp.m ---
