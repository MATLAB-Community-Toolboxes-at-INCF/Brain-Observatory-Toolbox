%
% Represent direct, linked, and derived data for a Visual Behavior 2P 
% dataset [1] experimental session.
%
% [1] Copyright 2016 Allen Institute for Brain Science. Visual Behavior 2P
% dataset.
%

% NOTE: A session does not have associated data, only an experiment does.
% A session should instead have linked experiments, one or many....


classdef OphysSession < bot.behavior.item.internal.abstract.Item & ...
                        bot.internal.behavior.mixin.HasLinkedFile
    
    % Direct Item Values
    properties (SetAccess = private)
        % SessionType - Type of experimental session (i.e. set of stimuli)
        SessionType (1,1) string % Todo: dependent.
        
        % Experiment - Experiments contained in this session. This will be
        % a scalar or a list of Experiment items.
        Experiment (1,:) bot.behavior.item.Experiment

        % Cells - Table of cells in this session  
        Cells table
    end

    properties (Access = protected)
        LinkedFileTypes = dictionary(...
            "SessNWB", @bot.internal.nwb.file.vb.BehaviorNWBFile)
    end

    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Constant, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualBehavior")
        DATASET_TYPE = bot.item.internal.enum.DatasetType("Ophys");
        ITEM_TYPE = bot.item.internal.enum.ItemType.Session;
    end
    
    properties (SetAccess = protected, Hidden)
        CORE_PROPERTIES = ["SessionType", "LinkedFilesInfo"];
        LINKED_ITEM_PROPERTIES = ["Experiment", "Cells"] % ["experiment", "cells"];
    end

    methods % CONSTRUCTOR
        function obj = OphysSession(varargin)
        % bot.behavior.item.VisualBehaviorOphysSession - Construct an object containing an experimental session from an Allen Brain Observatory dataset
        %
        % Usage: vbsObj = bot.behavior.item.VisualBehaviorOphysSession(id)
        %        vbsObj = bot.behavior.item.VisualBehaviorOphysSession(vids)
        %        vbsObj = bot.behavior.item.VisualBehaviorOphysSession(tSessionRow)
            
            % Superclass construction
            obj = obj@bot.behavior.item.internal.abstract.Item(varargin{:});
            obj = obj@bot.internal.behavior.mixin.HasLinkedFile()

            if ~isempty(varargin)
                itemIDSpec = varargin{1};
            else
                return
            end
            
            % Only process attributes if we are constructing a scalar object
            if obj.isItemIDSpecScalar( itemIDSpec )
                %obj.initLinkedFiles(); Called from superclass constructor
                %obj.initLinkedItems(); Called from superclass constructor
            end
        end
    end

    methods % Set/get methods
        function SessionType = get.SessionType(obj)
            % get.SessionType - GETTER Return the name for the stimulus set used in this session
            %
            % Usage: strSessionType = obj.SessionType
            SessionType = obj.info.session_type;
        end
    end
    
    % SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
    methods (Hidden, Access = protected)
        function groups = getPropertyGroups(obj)

            groups = getPropertyGroups@bot.behavior.item.internal.abstract.Item(obj);
    
            linkedFileGroups = obj.getLinkedFilePropertyGroups();
            groups = [groups, linkedFileGroups];
        end
    end

    methods (Access = protected)

        function filePath = getLinkedFilePath(obj, fileNickName, autoDownload)
            % Get filepath from cache.
            datasetCache = bot.internal.behavior.Cache.instance();
            if fileNickName == "SessNWB"
                % Note: As an ophys session can have one or multiple
                % experiments associated with it, the NWB file of the first
                % experiment is used by default (the behavior data content
                % should be the same across all experiments).
                filePath = datasetCache.getPathForFile(fileNickName, obj.Experiment(1), ...
                    'AutoDownload', autoDownload);
            else
                error('Unsupported file nickname for Visual Behavior ophys session')
            end
        end

        function initLinkedFiles(obj)
        % initLinkedFiles - Initialize linked files for item
            
            % Todo: move to HasLinkedFiles, although need to redefine 
            % AutoDownloadNwb from preferences.

            % Check preferences if file should be downloaded
            prefs = bot.util.getPreferences();
            autoDownload = prefs.AutoDownloadNwb;
            
            fileNickName = obj.LinkedFileTypes.keys;
            
            % Get the filepath for the linked file
            filePath = obj.getLinkedFilePath(fileNickName, autoDownload);

            % Note: If autodownload is false and the file does not exist in
            % the cache, the filePath will be empty.

            linkedFileFcn = obj.LinkedFileTypes(fileNickName);
            obj.LinkedFiles = linkedFileFcn(filePath, fileNickName);
        end
        
        function initLinkedItems(obj)
        % initLinkedItems - Initialize the linked item properties.

            % Get list of experiments for this ophys session
            experimentIds = obj.getExperimentIDs();

            expList = bot.behavior.listExperiments();
            expList = expList(ismember(expList.id, experimentIds),:);

            % Create experiment items
            obj.Experiment = bot.behavior.getExperiments(expList);
            for i = 1:numel(obj.Experiment)
                obj.Experiment(i).setLinkedSession(obj);
            end
    
            % Get cells for experiments of session
            cells = bot.behavior.listCells();
            obj.Cells = cells(ismember(cells.ophys_experiment_id, uint64(experimentIds)), :);
            obj.Cells = sortrows(obj.Cells, 'cell_roi_id');
        end
    end

    methods (Access = private)
        function experimentIDs = getExperimentIDs(obj)
        % getExperimentIDs - Get experiment ids from info struct
            experimentIDs = obj.info.ophys_experiment_id;
        end
    end
end
