classdef Session < handle & bot.item.abstract.LinkedFilesItem
 

    %% PROPERTIES - HIDDEN                     
    
    % SUBCLASS INTERFACE    
    properties (Abstract, Constant, Hidden)
        NWB_WELL_KNOWN_FILE_PREFIX (1,1) string
    end
    
    properties (Abstract, Dependent, Access=protected)
        nwbLocal; % NWB file access prop, useful for some property access fcns TODO: eliminate or at least harmonize output type across session subclasses (currently variable)
    end
    
    % SUPERCLASS IMPLEMENTATION (bot.item.abstract.LinkedFilesItem)
    properties (SetAccess = protected, Hidden)
        LINKED_FILE_AUTO_DOWNLOAD = struct("SessNWB",true);
    end    
    
    % SUSPECTED CRUFT
    %     properties (Access = private)
    %         bot_cache = bot.internal.cache();                            % Private handle to the BOT Cache
    %         ophys_manifest = bot.internal.ophysmanifest.instance();              % Private handle to the OPhys data manifest
    %         ephys_manifest = bot.internal.ephysmanifest.instance();              % Private handle to the EPhys data manifest
    %     end
    
   %% CONSTRUCTOR       
   
   methods
      function obj = Session()                      
          
      end           
      
   end    
   
   methods (Access=protected)
       function initSession(obj)
           % Superclass initialization (bot.item.abstract.LinkedFilesItem)
           nwbIdx = find(contains(string({obj.info.well_known_files.path}),"nwb",'IgnoreCase',true));
           assert(isscalar(nwbIdx),"Expected to find exactly one NWB file ");
           obj.insertLinkedFileInfo("SessNWB",obj.info.well_known_files(nwbIdx));
       end
   end

end