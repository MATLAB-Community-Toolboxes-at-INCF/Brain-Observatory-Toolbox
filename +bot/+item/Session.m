classdef Session < handle & bot.item.internal.abstract.LinkedFilesItem
    % Abstract class for Session objects of all dataset types
    
    
    %% PROPERTIES - HIDDEN
    
    % SUBCLASS INTERFACE
    
    properties (Abstract, Hidden, Dependent, Access=protected)
        nwbLocal; % NWB file access prop, useful for some property access fcns TODO: eliminate or at least harmonize output type across session subclasses (currently variable)
    end
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        ITEM_TYPE = bot.item.internal.enum.ItemType.Session;
    end
    
    % SUPERCLASS IMPLEMENTATION (bot.item.internal.abstract.LinkedFilesItem)
    properties (Hidden, SetAccess = protected)
        LINKED_FILE_AUTO_DOWNLOAD = struct("SessNWB",true);
    end
    
    % SUSPECTED CRUFT
    %     properties (Access = private)
    %         bot_cache = bot.internal.Cache.instance();                            % Private handle to the BOT Cache
    %         ophys_manifest = bot.item.internal.OphysManifest.instance();              % Private handle to the OPhys data manifest
    %         ephys_manifest = bot.item.internal.EphysManifest.instance();              % Private handle to the EPhys data manifest
    %     end
    
    
    
    %% LIFECYCLE
    
    % CONSTRUCTOR
    methods
        function obj = Session(itemIDSpec)
            obj = obj@bot.item.internal.abstract.LinkedFilesItem(itemIDSpec);
        end
    end
    
    % INITIALIZER
    methods (Access=protected)
        function initSession(obj)
            % Superclass initialization (bot.item.internal.abstract.LinkedFilesItem)
            obj.LINKED_FILE_AUTO_DOWNLOAD = struct("SessNWB", ...
                bot.internal.Preferences.getPreferenceValue('AutoDownloadNwb'));

            nwbIdx = find(contains(string({obj.info.well_known_files.path}),"nwb",'IgnoreCase',true));
            assert(isscalar(nwbIdx),"Expected to find exactly one NWB file ");
            obj.insertLinkedFileInfo("SessNWB",obj.info.well_known_files(nwbIdx));
        end
    end
    
end