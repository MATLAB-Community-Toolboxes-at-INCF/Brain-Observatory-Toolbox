classdef LinkedFilesItem < bot.item.internal.abstract.Item & bot.item.internal.mixin.OnDemandProps
   %LINKEDFILES Handles linked files for this BOT Item

    % Todo: Consider whether to add s3 path info to the linkedFilesInfo table...

   %% PROPERTIES - VISIBLE
   
   properties (SetAccess = private)
      % Table containing local file paths for linked files
      linkedFiles table = table('Size', [0 1], 'VariableTypes', "string", 'VariableNames', "LocalFile");
   end
   
   %% PROPERTIES - HIDDEN

   properties (Hidden, SetAccess = protected)
      % Struct for storing response tables from linkedFile fetch ops, where applicable
      linkedFileRespTables (1,1) struct
      
      % String array of properties whose linked file has been downloaded
      downloadedFileProps (1,:) string
   end
   
   properties (Hidden, SetAccess = private)
      % Boolean flag, whether linked files info have been initialized
      initState = false
      
      %linkedFilesInfo struct = struct('Nickname',{},'LocalFile',{},'URL',{},'FileInfo',{});
      linkedFilesInfo table = table(  'Size',[0 4],... %TODO: add a "MATLAB file info" variable that specifies fcn for checking if a file is valid (iss#94)
         'VariableTypes',["string" "logical" "string" "string"], ...
         'VariableNames',["nickname" "autoDownload" "path" "download_link" ]);
   end
   
   %% PROPERTIES - HIDDEN IMMUTABLES
   
   properties (SetAccess = immutable, Hidden)
      prop2LinkedFileMap % Handle to containers.Map
   end
   
   properties (Abstract, SetAccess=protected, Hidden)
      % TODO: refactor this into a single "linkedFilesConfiguration" table
      LINKED_FILE_PROP_BINDINGS (1,1) struct % Structure of form s.<linked file nickname> = <property name string array>
      LINKED_FILE_AUTO_DOWNLOAD (1,1) struct % Structure of form s.<linked file nickname> = <logical>
   end
   
   %% PROPERTIES - CONSTANT (S3 bucket url/path definitions)
   
   properties (Constant, Hidden)
      % Path if ABO S3 bucket is mounted on AWS EC2 (cloud computer) 
      S3_ROOT_PATH = fullfile('/home', 'ubuntu', 's3-allen')
      
      % Web URL for the ABO S3 bucket
      S3_BASE_URL = "https://allen-brain-observatory.s3.us-west-2.amazonaws.com"
   end

   properties (Abstract, Constant, Hidden)
      % Primary data folder is the name of the folder containing either 
      % EPhys or OPhys data. Subclass must implement
      S3_PRIMARY_DATA_FOLDER
   end
   
   
   %% METHODS - HIDDEN
   
   % SUBCLASS API
   methods (Hidden, Access = protected)
      function downloadLinkedFile(obj,fileNickname)
      %downloadLinkedFile Retrieve a linked file (from cache or api/s3)
      %
      %  This method will retrieve a file using different strategies which
      %  depends on preference selections. 
      %
      %    1) If an Allen Brain Observatory S3 bucket is mounted locally
      %    and the preferences is set to download from S3, the file is
      %    copied from the bucket to the local cache
      %
      %    2) If an S3 bucket is not mounted locally, and the preference is
      %    set to download from S3, the file will be downloaded from the
      %    bucket using the https protocol.
      %
      %    3) If an S3 bucket is not mounted locally, and the preference is
      %    set to download from API, the file will be downloaded from the
      %    Allen Brain Observatory API
      
         fileInfo = obj.linkedFilesInfo(fileNickname,:); %table row
         
         boc = bot.internal.cache;
         strApiUrl = boc.strABOBaseUrl + fileInfo.download_link;
         assert(~boc.IsURLInCache(strApiUrl), "File has already been downloaded");
         %assert(ismissing(obj.linkedFiles{fileNickname,"LocalFile"}),"File has already been downloaded");
         
         try % Retrieve file based on current strategy
             if obj.isS3BucketMounted() && obj.retrieveFileFromS3Bucket()
                action = "Copy";
             else
                action = "Download";
             end
             
             if obj.retrieveFileFromS3Bucket()
                strS3Filepath = obj.getS3Filepath(fileNickname, action=="Copy");
                strSourcePath = strS3Filepath;
             else
                strS3Filepath = "";
                strSourcePath = strApiUrl;
             end
             
             disp( action+"ing file: [" + strSourcePath + "]" + newline + ...
                   "to cache location: " + fileInfo.path + "..." )
             localFilename = boc.CacheFile(strApiUrl, fileInfo.path, ...
                     strS3Filepath, 'RetrievalMode', action);
             disp( strjoin([action, "complete."]) )

         catch ME
            % TODO: handle caching errors
            ME.rethrow();
         end
         
         obj.downloadedFileProps = [obj.downloadedFileProps obj.LINKED_FILE_PROP_BINDINGS.(fileNickname)];
         
         assert(ismissing(obj.linkedFiles{fileNickname,"LocalFile"}));
         obj.linkedFiles{fileNickname,"LocalFile"} = string(localFilename);
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
   methods (Hidden, Access = protected)
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
            
            % Check if the Allen S3 bucket is mounted on the local file system
            if obj.isS3BucketMounted() && ~obj.useCloudCacher() % Download-free mode
                % Generate filename from nickname and use this for local
                % file to bypass download through api and subsequent caching
                filepath = obj.getS3Filepath(nickname, true);
                obj.linkedFiles{nickname,"LocalFile"} = string(filepath);
                obj.downloadedFileProps = [obj.downloadedFileProps obj.LINKED_FILE_PROP_BINDINGS.(nickname)];
                continue
            end

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

   %% METHODS - S3 FILE RETRIEVAL
   
   methods (Hidden, Access = protected)
      function tf = isS3BucketMounted(obj)
         tf = isfolder( obj.S3_ROOT_PATH );
      end

      function tf = retrieveFileFromS3Bucket(~)
          tf = strcmp( bot.Preferences.get('DownloadFrom'), 'S3');
      end

      function tf = useCloudCacher(~)
         tf = bot.Preferences.get('UseCacheOnCloud');
      end

      function s3Filepath = getS3Filepath(obj, nickname, localMount)
      %getS3Filepath Get filepath of file in s3 bucket given nickname
         
         arguments
            obj                             % An object of the LinkedFilesItem class
            nickname (1,1) string           % Nickname of file to get filepath for
            localMount (1,1) logical = true % Action used for retrieving file. Options: "Copy" or "Download"
         end

         if localMount % S3 bucket is mounted.
            rootPath = obj.S3_ROOT_PATH;
         else
            rootPath = obj.S3_BASE_URL; % Use S3 web 
         end
         
         % Build the full filepath for the file
         s3TrunkPath = fullfile(rootPath, obj.S3_PRIMARY_DATA_FOLDER);
         s3BranchPath = obj.getS3BranchPath(nickname);
         s3Filepath = fullfile(s3TrunkPath, s3BranchPath);

         % Ensure the url protocol is correct (fullfile removes double //)
         if strncmp(s3Filepath, 'https', 5)
             if ispc
                % On windows, fix from file system slach to url slash
                s3Filepath = replace(s3Filepath, '\', '/');
             end
             s3Filepath = replace(s3Filepath, 'https:/', 'https://');
         end
      end

      function [] = getS3BranchPath(obj, varargin)
      %getS3BranchPath Get subfolders and and filename for file in s3 bucket
         error('Linked files in S3 bucket is not implemented for item of type "%s"', class(obj))
      end
   end
end
