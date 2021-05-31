classdef Session < handle & bot.item.abstract.LinkedFilesItem
    % Abstract class for Session objects of all dataset types
        
    
    %% PROPERTIES - HIDDEN                     
            
    % SUBCLASS INTERFACE        
    properties (Abstract, Hidden, Constant)
        %DATASET_TYPE(1,1) bot.item.internal.enum.DatasetType; 
        NWB_WELL_KNOWN_FILE_PREFIX(1,1) string
    end
    
    properties (Abstract, Hidden, Dependent, Access=protected)
        nwbLocal; % NWB file access prop, useful for some property access fcns TODO: eliminate or at least harmonize output type across session subclasses (currently variable)
    end
    
    
    % SUPERCLASS IMPLEMENTATION (bot.item.abstract.Item)
    properties (Hidden, Access = protected, Constant)
        MANIFEST_TABLE_NAME = lower(string(mfilename())) + "s"; 
    end


    % SUPERCLASS IMPLEMENTATION (bot.item.abstract.LinkedFilesItem)
    properties (Hidden, SetAccess = protected)
        LINKED_FILE_AUTO_DOWNLOAD = struct("SessNWB",true);
    end    
    
    % SUSPECTED CRUFT
    %     properties (Access = private)
    %         bot_cache = bot.internal.cache();                            % Private handle to the BOT Cache
    %         ophys_manifest = bot.internal.ophysmanifest.instance();              % Private handle to the OPhys data manifest
    %         ephys_manifest = bot.internal.ephysmanifest.instance();              % Private handle to the EPhys data manifest
    %     end
    

    
    %% LIFECYCLE
   
   % CONSTRUCTOR
   methods
      function obj = Session(itemIDSpec)                
          
          obj = obj@bot.item.abstract.LinkedFilesItem(itemIDSpec);                                                            

      end                 
   end    
   
   % INITIALIZER
   methods (Access=protected)
       function initSession(obj)
           % Superclass initialization (bot.item.abstract.LinkedFilesItem)
           nwbIdx = find(contains(string({obj.info.well_known_files.path}),"nwb",'IgnoreCase',true));
           assert(isscalar(nwbIdx),"Expected to find exactly one NWB file ");
           obj.insertLinkedFileInfo("SessNWB",obj.info.well_known_files(nwbIdx));
       end
   end

end