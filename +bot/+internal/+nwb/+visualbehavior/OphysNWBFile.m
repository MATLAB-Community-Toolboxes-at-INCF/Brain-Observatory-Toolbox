classdef OphysNWBFile < bot.internal.nwb.NWBData

        
        % Maximum intensity image
        % Average intensity image
        % Segmentation masks and ROI metadata
        % dF/F traces (baseline corrected, normalized fluorescence traces)
        % Corrected fluorescence traces (neuropil subtracted and demixed, but not normalized)
        % Events (detected with an L0 event detection algorithm)
        % Pupil position, diameter, and area
        % Running speed (in cm/second)
        % Lick times
        % Reward times
        % Stimulus presentation times
        % Behavioral trial information
        % Mouse metadata (age, sex, genotype, etc)

    % h5read
    % h5readatt

    % Todo:
    % Rois (image segmentation)
    % Events
    % Eye tracking
    % Motion correction combine x and y in timetable
    % rewards
    % stimulus


    properties (Hidden)
        Name = 'SessNWB'
    end

    properties %(SetAccess = private, Transient)
        AverageFovImage
        MaximumFovImage
        CorrectedFluorescence
        Dff
        Licks bot.internal.OnDemandProperty
        RunningSpeed
        StimulusTimes
        StimulusPresentation
        StimulusTemplates
    end

    properties (Access = protected)
        PropertyGroupMapping = struct(...
                            'Licks', '/processing/licking/licks', ...
            'CorrectedFluorescence', '/processing/ophys/corrected_fluorescence/traces', ...
                              'Dff', '/processing/ophys/dff/traces', ...
                  'AverageFovImage', {{'/processing/ophys/images', 'average_image'}}, ...
                  'MaximumFovImage', {{'/processing/ophys/images', 'max_projection'}}, ...
                     'RunningSpeed', '/processing/running/speed', ...
                    'StimulusTimes', '/processing/stimulus/timestamps', ...
             'StimulusPresentation', '/stimulus/presentation/Natural_Images_Lum_Matched_set*', ...
                'StimulusTemplates', {{'/stimulus/templates/Natural_Images_Lum_Matched_set*', 'unwarped'}})
    end
end