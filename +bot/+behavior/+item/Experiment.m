classdef Experiment < bot.behavior.item.internal.abstract.Item & ...
                        bot.behavior.internal.mixin.HasLinkedFile
% An experiment refers to a single imaging plane acquired in a single session

% Note: An experiment of the Visual Behavior Dataset is defined very
% differently from an experiment of the Visual Coding Dataset

% Todo:
%   [ ] Rename to OphysExperiment?
%   [ ] SessionType should be dependent

    % Direct Item Values
    properties (SetAccess = private)
        % SessionType - Type of experimental session (i.e. set of stimuli)
        SessionType
        
        % Container - A set of experiments (imaging planes) recorded in the
        % same location as the current experiment, but during different
        % sessions
        Container
        
        % Session - Session this experiment is part of
        Session

        % Cells - Table of cells in this session  
        Cells
    end

    properties (Access = protected)
        LinkedFileTypes = dictionary(...
            'SessNWB', @bot.internal.nwb.file.vb.OphysNWBFile)
    end

    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Constant, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualBehavior")
        DATASET_TYPE = bot.item.internal.enum.DatasetType("Ophys");
        ITEM_TYPE = bot.item.internal.enum.ItemType.Experiment;
    end

    properties (Hidden, SetAccess = protected)
        CORE_PROPERTIES = ["SessionType", "LinkedFilesInfo"];
        LINKED_ITEM_PROPERTIES = ["Container", "Session", "Cells"]
    end

    methods

        function obj = Experiment(varargin)               
            
            % Superclass construction
            obj = obj@bot.behavior.item.internal.abstract.Item(varargin{:});
            obj = obj@bot.behavior.internal.mixin.HasLinkedFile()

            if ~isempty(varargin)
                itemIDSpec = varargin{1};
            else
                return
            end

            % Only process attributes if we are constructing a scalar object
            if obj.isItemIDSpecScalar( itemIDSpec ) % todo: remove...
                %obj.initLinkedFiles(); Called from superclass constructor
                %obj.initLinkedItems(); Called from superclass constructor
            end
        end
    
    end

    methods 
        function session_type = get.SessionType(obj)
            % get.session_type - GETTER Return the name for the stimulus set used in this session
            %
            % Usage: strSessionType = bos.session_type
            session_type = obj.info.session_type;
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
        function initLinkedFiles(obj)
        % initLinkedFiles - Initialize linked files for item
            
            % Todo: move to HasLinkedFiles, although need to redefine 
            % AutoDownloadNwb from preferences for generality?

            % Check preferences if file should be downloaded
            prefs = bot.util.getPreferences();
            autoDownload = prefs.AutoDownloadNwb;
            
            fileNickName = obj.LinkedFileTypes.keys;

            % Get filepath from cache.
            datasetCache = bot.behavior.internal.Cache.instance();
            filePath = datasetCache.getPathForFile(fileNickName, obj, ...
                'AutoDownload', autoDownload);

            linkedFileFcn = obj.LinkedFileTypes(fileNickName);
            obj.LinkedFiles = linkedFileFcn(filePath, fileNickName);
        end

        function initLinkedItems(obj)
        % initLinkedItems - Initialize the linked item properties.

            % Get all experiments belonging to the same container:
            containerId = uint32( obj.info.ophys_container_id );
            expList = bot.behavior.listExperiments();
            expList = expList(expList.ophys_container_id == containerId & expList.id~=obj.id,:);
            obj.Container = expList;

            % Get the session for the session this experiment is a
            % part of. Note: This is assigned as a table entry, not an
            % item, because creating an OphysSession item will create items
            % for each associated experiment and thus there will be an
            % infinite recursion issue.
            sessions = bot.listSessions('Ophys', 'Dataset', 'VisualBehavior', 'Id', obj.info.ophys_session_id);
            obj.Session = sessions;
        
            % Get cells associated with the experiment
            cells = bot.behavior.listCells();
            obj.Cells = cells(cells.ophys_experiment_id == obj.id, :);
            obj.Cells = sortrows(obj.Cells, 'cell_roi_id');
        end
    end

    methods (Access = ?bot.behavior.item.OphysSession)
        function setLinkedSession(obj, sessionItem)
        % setLinkedSession - Set the Session (linked item) property
        %
        %   Provides an access point for setting the Session property from
        %   the OphysSession class.
            obj.Session = sessionItem;
        end
    end
end
    