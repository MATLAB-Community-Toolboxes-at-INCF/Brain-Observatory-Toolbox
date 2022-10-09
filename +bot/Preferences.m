classdef Preferences < matlab.mixin.CustomDisplay
%Preferences Brain Observatory Toolbox preferences 
%
%   Name of available Preferences:
%       CacheDirectory  (char)    : Path to folder for storing cached (downloaded) data.
%       DialogMode      (char)    : How to show dialogs with user. 'Dialog Box' (default) or 'Command Window'.
%       DownloadFrom    (char)    : Where to download data from. 'API' (default) or 'S3', i.e web api or s3 bucket.
%       UseCacheOnCloud (logical) : Whether to use cache if working on an AWS cloud computer
%       
%   Use <a href="matlab:help(''bot.Preferences/get'')">bot.Preferences.get()</a> or <a href="matlab:help(''bot.Preferences/set'')">bot.Preferences.set()</a> to access or modify preferences.
    
%   Developer's note: This was an attempt at making a singleton like
%   preferences class. Preferences are stored in matlab's preference
%   groups.

    properties (Constant, Hidden)
        GroupName = 'BrainObservatoryToolbox' % Group name in MATLAB's preferences
    end
    
    properties (Constant, Access = private) % Default values for preferences 
        CacheDirectory      = ''            % Directory for local caching of downloaded data and files
        DialogMode          = 'Dialog Box'  % How to show dialogs with user. Options: Dialog Box or Command Window
        DownloadFrom        = 'API'         % Where to download data from, i.e web api or s3 bucket
        UseCacheOnCloud     = false         % Whether to use cache if working on a AWS cloud computer
        %UnitFilterParameters = bot.getDefaultParameters()
    end

    properties (Constant, Access = private, Hidden) % Validation of preferences.
        CacheDirectory_     = struct('classes', {{'char', 'string'}}, 'attributes', {{}}, 'values', {{}})
        DialogMode_         = struct('classes', {{'char', 'string'}}, 'attributes', {{}}, 'values', {{'Dialog Box', 'Command Window'}})
        DownloadFrom_       = struct('classes', {{'char', 'string'}}, 'attributes', {{}}, 'values', {{'API', 'S3'}})
        UseCacheOnCloud_    = struct('classes', {'logical'},          'attributes', {{}}, 'values', {{}})
        %UnitFilterParameters_ = struct('classes', {'struct'},         'attributes', {{}}, 'values', {{}})
    end

    methods (Access = protected)
        function str = getHeader(obj)
            className = class(obj);
            helpLink = sprintf('<a href="matlab:help bot.Preferences" style="font-weight:bold">%s</a>', className);
            str = sprintf('%s has the following entries:', helpLink);
        end

        function str = getFooter(~)
            getLink = '<a href="matlab:help(''bot.Preferences/get'')">bot.Preferences.get()</a>';
            setLink = '<a href="matlab:help(''bot.Preferences/set'')">bot.Preferences.set()</a>';
            str = sprintf('Use %s or %s to access or modify preferences\n', getLink, setLink);
        end

        function groups = getPropertyGroups(obj)
            propListing = getpref(obj.GroupName);
            if isempty(propListing)
                propListing = bot.Preferences.getDefaults();
                groups = matlab.mixin.util.PropertyGroup(propListing);
            else
                groups = matlab.mixin.util.PropertyGroup(propListing);
            end
        end
        
    end

    methods (Static)

        function set(preferenceName, value)
        %SET Set value of a specified preference
        %   bot.Preferences.set(prefName, prefValue)

            validationStruct = bot.Preferences.([preferenceName '_']);
            validateattributes(value, validationStruct.classes, validationStruct.attributes);

            if ~isempty(validationStruct.values)
                
                switch class( validationStruct.values{1} )
                    case {'char', 'string'}
                        value = validatestring(value, validationStruct.values);
                    otherwise 
                        error('Not implemented yet')
                end
            end

            if ~ispref(bot.Preferences.GroupName)
                bot.Preferences.initializePreferences()
            end

            setpref(bot.Preferences.GroupName, preferenceName, value)
        end

        function value = get(preferenceName)
        %GET Get value of a specified preference   
        %   prefValue = bot.Preferences.get(prefName)

            if ispref(bot.Preferences.GroupName, preferenceName)
                value = getpref(bot.Preferences.GroupName, preferenceName);
            else
                value = bot.Preferences.(preferenceName);
            end
        end

        function prefStruct = getAll()
            prefStruct = getpref(bot.Preferences.GroupName);
        end

        function tf = isequal(preferenceName, promptValue)
            
            prefValue = bot.Preferences.get(preferenceName);

            switch class(prefValue)
                case 'char'
                    tf = strcmp(prefValue, promptValue);
                    
                otherwise
                    tf = isequal(prefValue, promptValue);
            end
        end

    end

    methods (Static) % Methods to quickly change preferences
        function useApi()
            bot.Preferences.set('DownloadFrom', 'API')
        end

        function useS3()
            bot.Preferences.set('DownloadFrom', 'S3')
        end

        function changeCacheFolder()
            try
                bot.Preferences.set('CacheDirectory', uigetdir)
                msg = sprintf('Cache folder changed to: %s',  bot.Preferences.get('CacheDirectory'));
                fprintf('%s\n', msg)
                %bot.internal.Logger.inform(msg, 'Updated Preferences')
            end
        end
    end

    methods (Static) % Access = private

        function initializePreferences()
            defaultPrefs = bot.Preferences.getDefaults();
            for name = fieldnames(defaultPrefs)'
                setpref(bot.Preferences.GroupName, name{1}, defaultPrefs.(name{1}))
            end
        end

        function defaultPrefs = getDefaults()
            mc = ?bot.Preferences;
            propList = mc.PropertyList;
            propList([propList.Hidden]) = [];

            defaultPrefs = struct;
            for name = {propList.Name}
                defaultPrefs.(name{1}) = bot.Preferences.(name{1});
            end
        end

    end
end

% function mustBeValidStruct()
%         assert(isstruct(sFilterValues), ...
%             'BOT:Usage', ...
%             '`sFilterValues` must be a structure with fields {''amplitude_cutoff_maximum'', ''presence_ratio_minimum'', ''isi_violations_maximum''}.')
% end
