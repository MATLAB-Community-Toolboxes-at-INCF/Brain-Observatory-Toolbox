classdef LinkedFilesItem < bot.item.internal.abstract.Item & bot.item.internal.mixin.OnDemandProps
   %LINKEDFILES Handles linked files for this BOT Item
   
   %% PROPERTIES - VISIBLE
   properties (SetAccess = private)
      linkedFiles table = table('Size',[0 1],'VariableTypes',"string",'VariableNames',"LocalFile");
   end
   
   %% PROPERTIES - HIDDEN
   
   
   properties (SetAccess = protected, Hidden)
      linkedFileRespTables (1,1) struct; % Struct for storing response tables from linkedFile fetch ops, where applicable
      
      downloadedFileProps (1,:) string; % string array of properties whose linked file has been downloaded
   end
   
   properties (SetAccess = private, Hidden)
      initState = false;
      
      %linkedFilesInfo struct = struct('Nickname',{},'LocalFile',{},'URL',{},'FileInfo',{});
      linkedFilesInfo table = table(  'Size',[0 4],... %TODO: add a "MATLAB file info" variable that specifies fcn for checking if a file is valid (iss#94)
         'VariableTypes',["string" "logical" "string" "string"], ...
         'VariableNames',["nickname" "autoDownload" "path" "download_link" ]);
   end
   
   %% PROPERTIES - HIDDEN IMMUTABLES
   
   properties (SetAccess = immutable, Hidden)
      prop2LinkedFileMap; % handle to containers.Map
   end
   
   
   properties (Abstract, SetAccess=protected, Hidden)
      % TODO: refactor this into a single "linkedFilesConfiguration" table
      LINKED_FILE_PROP_BINDINGS (1,1) struct; % structure of form s.<linked file nickname> = <property name string array>
      LINKED_FILE_AUTO_DOWNLOAD (1,1) struct; % structure of form s.<linked file nickname> = <logical>
   end
   
   
   
   %% METHODS - HIDDEN
   
   % SUBCLASS API
   methods (Hidden, Access = protected)
      function downloadLinkedFile(obj,fileNickname)
         
         fileInfo = obj.linkedFilesInfo(fileNickname,:); %table row
         
         boc = bot.internal.cache;
         url = boc.strABOBaseUrl + fileInfo.download_link;
         assert(~boc.IsURLInCache(url),"File has already been downloaded");
         %assert(ismissing(obj.linkedFiles{fileNickname,"LocalFile"}),"File has already been downloaded");
         
         try
            disp(   "Downloading URL: [" + url + "]" + newline + ...
               "to cache location: " + fileInfo.path + "...");
            lclFilename = boc.CacheFile(url, fileInfo.path);
            disp("Download complete.");
         catch ME
            % TODO: handle caching errors
            ME.rethrow();
         end
         
         obj.downloadedFileProps = [obj.downloadedFileProps obj.LINKED_FILE_PROP_BINDINGS.(fileNickname)];
         
         assert(ismissing(obj.linkedFiles{fileNickname,"LocalFile"}));
         obj.linkedFiles{fileNickname,"LocalFile"} = string(lclFilename);
         
      end
      
      function ensurePropFileDownloaded(obj,propName)
         if ~ismember(propName,obj.downloadedFileProps)
            obj.downloadLinkedFile(obj.prop2LinkedFileMap(propName));
         end
      end
      
      function lclFilename = whichPropFile(obj,propName)
         fileNickname = obj.prop2LinkedFileMap(propName);
         if ismember(propName,obj.downloadedFileProps)
            lclFilename = obj.linkedFiles{fileNickname,"LocalFile"};
         else
            lclFilename = missing;
         end
      end
      
   end
   
   % SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
   methods (Hidden, Access = protected)
      function groups = getPropertyGroups(obj)
         if ~isscalar(obj)
            groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
         else
            groups = getPropertyGroups@bot.item.internal.abstract.Item(obj);
            
            
            for nickname = string(obj.linkedFiles.Row)'
               
               propListing = obj.getOnDemandPropListing(obj.LINKED_FILE_PROP_BINDINGS.(nickname));
               
               if ~isempty(propListing)
                  lclFile = obj.linkedFiles{nickname,"LocalFile"};
                  if ismissing(lclFile)
                     for odProp = string(fieldnames(propListing))'
                        propListing.(odProp) = '[download required]';
                     end
                  end
                  
                  % TODO: break this up into two groups for direct and derived values (most likely separated by a newline gap, rather than additional group headings)
                  groups(end+1) = matlab.mixin.util.PropertyGroup(propListing, "Linked File Values ('" + nickname + "')"); %#ok<AGROW>
               end
            end
         end
      end
   end
   
   
   %% CONSTRUCTOR/INITIALIZER
   
   methods
      function obj = LinkedFilesItem(itemIDSpec)
         
         % Superclass Construction
         obj = obj@bot.item.internal.abstract.Item(itemIDSpec);
         
         % Only process attributes if we are constructing a scalar object
         if numel(itemIDSpec) == 1 || (istable(itemIDSpec) && size(itemIDSpec, 1) == 1)
            % On-demand property identification
            obj.prop2LinkedFileMap = containers.Map;
            
            for fileNickname = string(fieldnames(obj.LINKED_FILE_PROP_BINDINGS))'
               
               % Compute reverse map of props to linked files
               propNames = obj.LINKED_FILE_PROP_BINDINGS.(fileNickname);
               for propName = propNames
                  obj.prop2LinkedFileMap(propName) = fileNickname;
               end
               
               % Mark linked file properties as on-demand properties
               obj.ON_DEMAND_PROPERTIES = [obj.ON_DEMAND_PROPERTIES obj.LINKED_FILE_PROP_BINDINGS.(fileNickname)];
            end
            
            
            % Add linkedFile prop to Item core property display
            obj.CORE_PROPERTIES = [obj.CORE_PROPERTIES "linkedFiles"];
         end
      end
      
   end
   
   % SUBCLASS CONSTRUCTOR API
   % Methods to populate linkedFileInfo table
   methods (Hidden, Access = protected)
      
      % Call API to fetch linkedFileInfo
      function apiRespTbl = fetchLinkedFileInfo(obj,nickname,apiReqStr,storeRespTbl)
         
         arguments
            obj
            nickname (1,1) string
            apiReqStr (1,1) string
            storeRespTbl (1,1) logical = false
         end
         
         assert(~obj.initState);
         
         % Call API to get info about linked file or linked file group
         boc = bot.internal.cache;
         apiRespTbl = boc.CachedAPICall('criteria=model::WellKnownFile', apiReqStr);
         
         fileInfo.nickname = nickname;
         fileInfo.autoDownload = obj.LINKED_FILE_AUTO_DOWNLOAD.(nickname);
         fileInfo.path = join(string(apiRespTbl.path)',";");
         fileInfo.download_link = join(string(apiRespTbl.download_link)',";");
         
         obj.linkedFilesInfo(end+1,:) = struct2table(fileInfo,'AsArray',true);
         
         % Does client require API response table? Then: store it locally for any future use
         if nargout > 0 || storeRespTbl
            obj.linkedFileRespTables.(nickname) = apiRespTbl;
         end
      end
      
      % Insert already-stored info into linkedFileInfo
      function insertLinkedFileInfo(obj,nickname,wellKnownFileInfo)
         arguments
            obj
            nickname (1,1) string
            wellKnownFileInfo (1,1) struct
         end
         
         assert(isscalar(string(wellKnownFileInfo.path))); % No known case of a linked file array within a well_known_file struct
         
         fileInfo.nickname = nickname;
         fileInfo.autoDownload = obj.LINKED_FILE_AUTO_DOWNLOAD.(nickname);
         fileInfo.path = wellKnownFileInfo.path;
         fileInfo.download_link = wellKnownFileInfo.download_link;
         
         obj.linkedFilesInfo(end+1,:) = struct2table(fileInfo);
         
      end
   end
   
   % SUBCLASS INITIALIZER
   % Mandatory initialization step prior to object use
   methods  (Hidden, Access = protected)
      
      function initLinkedFiles(obj)
         
         % Make linkedFilesInfo easier to access
         nicknames = obj.linkedFilesInfo.nickname;
         obj.linkedFilesInfo.Properties.RowNames = nicknames;
         obj.linkedFilesInfo.nickname = [];
         
         % Create display version of linkedFiles
         obj.linkedFiles{height(obj.linkedFilesInfo),"LocalFile"} = missing; % grow table to match height of linkedFilesInfo
         obj.linkedFiles.Properties.RowNames = nicknames;
         
         % Update display for linkedFile groups
         for nickname = nicknames'
            if numel(split(obj.linkedFilesInfo{nickname,"path"},";")) > 1
               assert(endsWith(nickname,"group",'IgnoreCase',true),"Nicknames for linkedFile groups must end with 'Group'");
               obj.linkedFiles{nickname,"LocalFile"} = "N/A";
            end
         end
         
         % Reflect/revise linkedFiles download states
         boc = bot.internal.cache;
         
         for nickname = nicknames'
            fileInfo = obj.linkedFilesInfo(nickname,:); %table row
            url = boc.strABOBaseUrl + fileInfo.download_link;
            
            % Determine which linkedFiles have been downloaded
            if boc.IsURLInCache(url)
               obj.linkedFiles{nickname,"LocalFile"} = string(boc.ccCache.CachedFileForURL(url));
               obj.downloadedFileProps = [obj.downloadedFileProps obj.LINKED_FILE_PROP_BINDINGS.(nickname)];
            else
               % Automatically download linkedFiles where needed
               if obj.linkedFilesInfo{nickname,"autoDownload"}
                  obj.downloadLinkedFile(nickname);
               end
            end
         end
         
         obj.initState = true;
      end
   end
end




