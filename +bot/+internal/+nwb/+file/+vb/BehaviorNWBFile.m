classdef BehaviorNWBFile < bot.internal.nwb.LLNWBData
% BehaviorNWBFile - Provides the data from a Visual Behavior session
%
%   A selection of the data from the NWB file of a Visual Behavior session 
%   is available as on demand properties of this class. 


%   Todo: 
%   [ ] Verify that it can be used for both neuropixels and ophys
%       behavior-only sessions.

    properties %(SetAccess = private, Transient)
        
        % Metadata:
        Metadata bot.internal.OnDemandProperty = ...
            bot.internal.OnDemandProperty([1,1], 'struct')

        SubjectDetails bot.internal.OnDemandProperty = ...
            bot.internal.OnDemandProperty([1,1], 'struct')

        TaskParameters bot.internal.OnDemandProperty = ...
            bot.internal.OnDemandProperty([1,1], 'struct')

        EyeTrackingRigGeometry bot.internal.OnDemandProperty = ...
            bot.internal.OnDemandProperty([1,1], 'struct')

        % Behavioral data:
        Licks = bot.internal.OnDemandProperty([nan,1], 'timetable')
        Rewards = bot.internal.OnDemandProperty([nan,2], 'timetable')
        EyeTracking = bot.internal.OnDemandProperty([nan,15], 'timetable')
        RunningSpeed = bot.internal.OnDemandProperty([nan,1], 'timetable')
        
        % Interval data:
        StimulusTimes = bot.internal.OnDemandProperty([nan,1], 'duration')
        StimulusPresentation = bot.internal.OnDemandProperty([nan,1], 'timetable')
        StimulusTemplates = bot.internal.OnDemandProperty([nan,2], 'table')
        Trials = bot.internal.OnDemandProperty([nan,22], 'table')
    end

    properties (Hidden) % Properties that are not shown to users.
        StimulusNames bot.internal.OnDemandProperty
        StimulusTemplatesWarped bot.internal.OnDemandProperty
    end

    properties (Access = protected)
        PropertyToDatasetMap = dictionary(...
                              'Metadata', '/general/experiment_description', ...
                        'SubjectDetails', '/general/subject/subject_id', ...
                        'TaskParameters', '/general/task_parameters/stimulus', ...
                'EyeTrackingRigGeometry', '/processing/eye_tracking_rig_metadata/eye_tracking_rig_metadata/camera_position', ...
                                 'Licks', '/processing/licking/licks/data', ...
                               'Rewards', '/processing/rewards/autorewarded/data', ...
                           'EyeTracking', '/acquisition/EyeTracking/pupil_tracking/data', ...
                          'RunningSpeed', '/processing/running/speed/data', ...
                         'StimulusTimes', '/processing/stimulus/timestamps/data', ...
                  'StimulusPresentation', '/stimulus/presentation/.*/data', ...
                     'StimulusTemplates', '/stimulus/templates/.*/unwarped', ...
               'StimulusTemplatesWarped', '/stimulus/templates/.*/data', ...
                         'StimulusNames', '/stimulus/templates/.*/control_description', ...
                                'Trials', '/intervals/trials/start_time' )

        PropertyProcessingFcnMap = dictionary(...
                              'Metadata', 'readNwbMetadata', ...
                        'SubjectDetails', 'readSubjectDetails', ...
                        'TaskParameters', 'readTaskParameters', ...
                'EyeTrackingRigGeometry', 'readEyetrackingMetadata', ...
                                 'Licks', 'postProcessLicks', ...
                          'RunningSpeed', 'postProcessRunningSpeed', ...
                               'Rewards', 'readRewardsTimeTable', ...
                           'EyeTracking', 'readEyeTrackingTimeTable', ...
                         'StimulusTimes', 'postProcessStimulusTimes', ...
                  'StimulusPresentation', 'postProcessStimulusPresentation', ...
                     'StimulusTemplates', 'postProcessStimulusTemplates', ...
                                'Trials', 'readTrialsTable' )
    end
    
    methods (Access = ?bot.internal.nwb.LLNWBData)
            
        function metadata = readNwbMetadata(obj, ~)
            metadata = bot.internal.nwb.reader.readGeneralMetadata(obj.FilePath);
        end

        function taskParameters = readTaskParameters(obj, ~)
            taskParameters = bot.internal.nwb.reader.readTaskMetadata(obj.FilePath);
        end

        function subjectDetails = readSubjectDetails(obj, ~)
            subjectDetails = bot.internal.nwb.reader.readSubjectMetadata(obj.FilePath);
        end
        
        function data = readEyetrackingMetadata(obj, ~)
            data = bot.internal.nwb.reader.readRigMetadata(obj.FilePath);
        end

        function data = readRewardsTimeTable(obj, ~)
            data = bot.internal.nwb.reader.vb.read_rewards_timetable(obj.FilePath);
        end

        function data = readEyeTrackingTimeTable(obj, ~) 
            data = bot.internal.nwb.reader.vb.read_eyetracking_timetable(obj.FilePath);
        end

        function data = postProcessLicks(~, data)
            data.Properties.VariableNames = {'frame'};
        end
           
        function data = postProcessRunningSpeed(~, data)
            data.Properties.VariableNames = {'speed'};
        end

        function data = postProcessStimulusPresentation(obj, data)
            names = obj.fetchData("StimulusNames");
            uniqueValues = unique(data.StimulusPresentation);
            data.StimulusPresentation = categorical(data.StimulusPresentation,uniqueValues,names);
        end

        function data = readTrialsTable(obj, ~)
            data = bot.internal.nwb.reader.vb.read_trials_timetable(obj.FilePath);
        end

        function data = postProcessStimulusTimes(~, data)
            data = data.timestamps;
        end

        function data = postProcessStimulusTemplates(obj, data)
        % postProcessStimulusTemplates - Add warped templates and create table
            imageNames = obj.fetchData("StimulusNames");
            warped = obj.fetchData("StimulusTemplatesWarped");
            
            data = uint8(data);
            data = permute(data, [2,1,3]);
            warped = permute(warped, [2,1,3]);

            imageSize = size(data);

            unwarpedImages = mat2cell(data, imageSize(1), imageSize(2), ones(imageSize(3),1));
            warpedImages = mat2cell(warped, imageSize(1), imageSize(2), ones(imageSize(3),1));

            data = table(squeeze(unwarpedImages), squeeze(warpedImages), ...
                'VariableNames', {'unwarped', 'warped'}, 'RowNames', imageNames);
        end
    end

    methods (Access = {?bot.internal.behavior.mixin.HasLinkedFile, ?bot.internal.behavior.LinkedFile})
        function propertyGroups = getPropertyGroups(obj)
        % getPropertyGroups - Get property groups for display of properties
        %
        %   Based on preferences, either the properties of this linked file
        %   will be grouped according to "data modality", i.e behavior or
        %   physiology, or they will be provided as one group.

            import matlab.mixin.util.PropertyGroup

            prefs = bot.util.getPreferences();
            if prefs.GroupNwbProperties

                propertyGroups = matlab.mixin.util.PropertyGroup.empty;
    
                grouping = obj.getPropertyGroupingMap();
                groupNames = grouping.keys()';
    
                for groupName = groupNames
                    propList = struct;
    
                    propertyNames = grouping{groupName};
    
                    for j = 1:numel(propertyNames)
                        thisPropName = propertyNames{j};
                        thisPropValue = obj.(thisPropName);
    
                        % Customize the property display if the value is empty.
                        if isempty(thisPropValue)
                            if obj.isInitialized()
                                thisPropValue = categorical({'<unknown>  (unavailable)'});
                            else
                                thisPropValue = categorical({'<unknown>  (download required)'});
                            end
                        end
    
                        propList.(thisPropName) = thisPropValue;
                    end
    
                    %displayName = obj.DisplayName;
                    groupTitle = "Linked NWB Data (" + groupName + ")";
                    %groupTitle = sprintf('<strong>%s:</strong>', groupTitle);
                    propertyGroups(end+1) = PropertyGroup(propList, groupTitle); %#ok<AGROW>
                end
            else
                propertyGroups = getPropertyGroups@bot.internal.nwb.LLNWBData(obj);
            end
        end
    end

    methods (Access = protected)

        function map = getPropertyGroupingMap(~)
            map = dictionary(...
                'NWB Metadata', {{'Metadata', 'SubjectDetails', 'TaskParameters', 'EyeTrackingRigGeometry'}}, ...
                    'Behavior', {{'Licks', 'Rewards', 'EyeTracking', 'RunningSpeed'}}, ...
                   'Intervals', {{'StimulusTimes', 'StimulusPresentation', 'Trials'}}, ...
                    'Stimulus', {{'StimulusTemplates'}} );
        end
    end

end