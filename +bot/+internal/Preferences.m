classdef Preferences < matlab.mixin.CustomDisplay & handle
    %Preferences for the Brain Observatory Toolbox
    %
    %       Preference name                 Description
    %       -----------------------------   ---------------------------------------
    %       DownloadFrom        (string)  : Where to download data from. 'S3' (default) or 'API', i.e AWS S3 bucket or web API
    %       CacheDirectory      (string)  : Path to folder for storing cached (downloaded) data
    %       UseLocalS3Mount     (logical) : Whether S3 bucket is mounted as a local file system
    %       S3MountDirectory    (string)  : Path to directory where S3 bucket is mounted locally
    %       UseCacheWithS3Mount (logical) : Whether to use cache if working on an AWS cloud computer
    %       DialogMode          (string)  : How to show dialogs with user. 'Dialog Box' (default) or 'Command Window'
    %       AutoDownloadNwb     (logical) : Whether to automatically download files when creating item (session) objects

    %       Suggestions for new preferences (Todo)
    %       DownloadMode        (string)  : Download file or variable

    properties (SetObservable)
        % Where to download data from, i.e web api or S3 bucket (AWS)
        DownloadFrom        (1,1) string ...
            {mustBeMember(DownloadFrom, ["API" "S3"])} = "S3"

        % Directory for local caching of downloaded data and files
        CacheDirectory      (1,1) string = ""

        % Whether S3 bucket is mounted as a local file system
        UseLocalS3Mount     (1,1) logical = false

        % Path to directory where S3 bucket is mounted locally
        S3MountDirectory    (1,1) string  = ""

        % Whether to use cache if working on an AWS cloud computer
        UseCacheWithS3Mount (1,1) logical = true

        % How to show dialogs with user. Options: Dialog Box or Command Window
        DialogMode          (1,1) string ...
            {mustBeMember(DialogMode, ["Dialog Box" "Command Window"])} = "Dialog Box"

        % Whether to automatically download nwb files when creating session objects
        AutoDownloadNwb     (1,1) logical = true
    end

    properties (SetObservable, Hidden)
        % A temporary directory for storing files when cache directory is
        % suboptimal.
        ScratchDirectory    (1,1) string = ""
    end

        % %         Suggestions for new preferences (Todo):
        % %
        % %         % Download file or variable (Work in progress).
        % %         DownloadMode        (1,1) string ...
        % %             {mustBeMember(DownloadMode, ["File" "Variable"])} = "File"

    properties (Constant, Access = private)
        Filename = fullfile(prefdir, 'BrainObservatoryToolboxPreferences.mat')
    end

    methods
        function uisetCacheDirectory(obj)
            newDirectory = uigetdir();
            if isequal(newDirectory, 0)
                return
            end

            obj.CacheDirectory = newDirectory;
            msg = sprintf('Cache folder changed to: %s', obj.CacheDirectory);
            fprintf('%s\n', msg)
            obj.save()
        end
    end


    methods (Access = private) % Constructor

        function obj = Preferences()
            
            if isfile(obj.Filename)
                try
                    S = load(obj.Filename);
                    obj = S.obj;
                catch
                    warning('Could not load preferences, using defaults')
                end
            end

            obj.addListeners()
        end

        function save(obj)
            save(obj.Filename, 'obj');
        end
    end

    methods (Hidden)
        function reset(obj)
            mc = metaclass(obj);

            propertyList = mc.PropertyList( ~[mc.PropertyList.Constant] );
            propertyNames = string( {propertyList.Name} );
            propertyDefaultValues = {propertyList.DefaultValue};

            for i = 1:numel(propertyNames)
                obj.(propertyNames(i)) = propertyDefaultValues{i};
            end

            obj.save()
        end
    end

    methods (Sealed, Hidden) % Overrides subsref

        function varargout = subsasgn(obj, s, value)
            %subsasgn Override subsasgn to save preferences when they change

            numOutputs = nargout;
            varargout = cell(1, numOutputs);

            isPropertyAssigned = strcmp(s(1).type, '.') && ...
                any( strcmp(properties(obj), s(1).subs) );

            % Use the builtin subsref with appropriate number of outputs
            if numOutputs > 0
                [varargout{:}] = builtin('subsasgn', obj, s, value);
            else
                builtin('subsasgn', obj, s)
            end

            if isPropertyAssigned
                obj.save()
            end
        end

        function n = numArgumentsFromSubscript(obj, s, indexingContext)
            n = builtin('numArgumentsFromSubscript', obj, s, indexingContext);
        end
    end

    methods (Access = protected) % Overrides CustomDisplay methods

        function str = getHeader(obj)
            helpLink = sprintf('<a href="matlab:help bot.internal.Preferences" style="font-weight:bold">%s</a>', 'Preferences');
            str = sprintf('%s for the Brain Observatory Toolbox:\n', helpLink);
        end

        function groups = getPropertyGroups(obj)
            propNames = obj.getActivePreferenceGroup();

            s = struct();
            for i = 1:numel(propNames)
                s.(propNames{i}) = obj.(propNames{i});
            end

            groups = matlab.mixin.util.PropertyGroup(s);
        end
    end

    methods (Access = private)
        
        function addListeners(obj)
        %createListeners Create listeners for some preferences

            addlistener(obj, 'CacheDirectory', 'PostSet', ...
                @(s,e) obj.onCacheDirectorySet);

            addlistener(obj, 'ScratchDirectory', 'PostSet', ...
                @(s,e) obj.onScratchDirectorySet);
        end

        function propertyNames = getActivePreferenceGroup(obj)
            %getCurrentPreferenceGroup Get current preference group
            %
            %   This method returns a cell array of names of preferences that
            %   are currently active. Some preference values are dependent on
            %   the values of other preferences, and will sometimes not have an
            %   effect.
            %
            %   This method is used by the getPropertyGroups that in turn
            %   determines how the preference object will be displayed. The
            %   effect is that dependent preferences are hidden when they are
            %   not active.

            propertyNames = properties(obj);

            namesToHide = {};
            % Todo: Find hidden property names
            %namesToHide = {'ScratchDirectory'};


            if ~obj.UseLocalS3Mount
                namesToHide = [namesToHide, {'S3MountDirectory', 'UseCacheWithS3Mount'}];
            end

            if ~isequal(obj.DownloadFrom, "S3")
                namesToHide = [namesToHide, {'DownloadMode'}];
            end

            propertyNames = setdiff(propertyNames, namesToHide, 'stable');
        end

        function onCacheDirectorySet(~)
            %onCacheDirectorySet Callback to execute if CacheDirectory changes
            %
            %   Need to reset the in-memory cache if this value is updated.
            botCache = bot.internal.Cache.instance();
            botCache.changeCacheDirectory(obj.CacheDirectory)

            bot.internal.Cache.clearInMemoryCache(true)
        end

        function onScratchDirectorySet(~)
            %onCacheDirectorySet Callback to execute if CacheDirectory changes
            %
            %   Need to reset the in-memory cache if this value is updated.
            
            botCache = bot.internal.Cache.instance();
            if obj.ScratchDirectory == ""
                botCache.resetScratchDirectory()
            else
                botCache.changeScratchDirectory(obj.ScratchDirectory)
            end
        end

    end

    %% STATIC METHODS
    methods (Static, Hidden)

        function obj = getSingleton()
            %getSingleton Get singleton instance of class
            persistent objStore

            if isempty(objStore)
                objStore = bot.internal.Preferences();
            end

            obj = objStore;
        end
    end

    methods (Static)

        function prefValue = getPreferenceValue(preferenceName)
            %getPreferenceValue Get value for a preference
            %
            %   prefs = getPreferenceValue(preferenceName) returns the preference value
            %   for the given preference name.
            %
            %   See also <a href="matlab:help bot.internal.Preferences" style="font-weight:bold">BOT Preferences</a>

            arguments
                preferenceName (1,1) string
            end

            preferences = bot.internal.Preferences.getSingleton();

            if isprop(preferences, preferenceName)
                prefValue = preferences.(preferenceName);
            else
                error('There is no preferences with name "%s" in the preferences for the Brain Observatory Toolbox', preferenceName)
            end
        end

    end


end
