classdef LinkedFiles < bot.item.abstract.Item & bot.item.mixin.OnDemandProps
    %LINKEDFILES Handles linked files for this BOT Item
        
    %% PROPERTIES - USER
    properties (SetAccess = private)
        linkedFiles table = table('Size',[0 1],'VariableTypes',"string",'VariableNames',"LocalFile");
    end            
    
    %% PROPERTIES - HIDDEN
    
%     properties (SetAccess = private, Hidden)
%         linkedFiles_ table; % local storage for linkedFiles property
%     end    
            
        
    properties (SetAccess = protected, Hidden)
        downloadedFileProps (1,:) string; % string array of properties whose linked file has been downloaded
        
        %linkedFilesInfo struct = struct('Nickname',{},'LocalFile',{},'URL',{},'FileInfo',{});
        linkedFilesInfo table = table(  'Size',[0 3],...
                                        'VariableTypes',["string" "string" "string"], ...
                                        'VariableNames',["nickname" "path" "download_link" ]);                                                                                                                                                     
    end
    
    properties (SetAccess = private, Hidden)
        linkedFilesInitialized = false;
    end
    
    %% PROPERTIES - HIDDEN IMMUTABLES
    
    properties (SetAccess = immutable, Hidden)
        prop2LinkedFileMap; % handle to containers.Map
    end
    
    
    properties (Abstract, SetAccess=protected, Hidden)
        LINKED_FILE_PROP_BINDINGS (1,1) struct; % structure of form s.<linked file nickname> = <property name string array>
    end
          
    
    
    %% PROPERTY ACCESS METHODS    
    %     methods
    %         function tbl = get.linkedFiles(obj)
    %
    %             if isempty(obj.linkedFiles_)
    %                 %TODO: 1) complete local file path & URL, 2) userify the variable names
    %             else
    %                 %tbl = obj.linkedFiles_; %TODO: use this
    %                 tbl = obj.linkedFilesInfo; % TEMP
    %             end
    %
    %
    %         end
    %
    %     end
   
        
    %% METHODS - HIDDEN
    
    methods 
       function downloadLinkedFile(obj,fileNickname)            
            
                        
            fileInfo = obj.linkedFilesInfo(fileNickname,:); %table row

            boc = bot.internal.cache;
            url = boc.strABOBaseUrl + fileInfo.download_link;
            assert(~boc.IsURLInCache(url),"File has already been downloaded");
            %assert(ismissing(obj.linkedFiles{fileNickname,"LocalFile"}),"File has already been downloaded");
            
            try 
                disp("Downloading URL: [" + url + "]...");
                lclFilename = boc.CacheFile(url, fileInfo.path);
            catch ME
                % TODO: handle caching errors
                ME.rethrow();
            end
            
            obj.downloadedFileProps(end+1) = obj.LINKED_FILE_PROP_BINDINGS.(fileNickname);
            
            assert(ismissing(obj.linkedFiles{fileNickName,"LocalFile"}));
            obj.linkedFiles{fileNickName,"LocalFile"} = lclFilename;
                
       end        
        
        function ensurePropDownloaded(obj,propName)
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
        
        function fetchLinkedFileInfo(obj,nickname,apiReqStr)                        
            %fileInfo = obj.linkedFilesInfo(nickname,:); %table row
            
            boc = bot.internal.cache;
            allFileInfo = boc.CachedAPICall('criteria=model::WellKnownFile', apiReqStr);
            
            fileInfo.nickname = nickname;
            fileInfo.download_link = allFileInfo.download_link;
            fileInfo.path = allFileInfo.path;
            
             obj.linkedFilesInfo(end+1,:) = struct2table(fileInfo);
        end
        
    end    
        
    % SUPERCLASS OVERRIDES (matlab.mixin.CustomDisplay)
    
    methods (Access = protected)
        function groups = getPropertyGroups(obj)
            if ~isscalar(obj)
                groups = getPropertyGroups@matlab.mixin.CustomDisplay(obj);
            else
                groups = getPropertyGroups@bot.item.abstract.Item(obj);
                
                
                for nickname = string(obj.linkedFiles.Row)'
                    
                    propListing = obj.getOnDemandPropListing(obj.LINKED_FILE_PROP_BINDINGS.(nickname));
                       
                    lclFile = obj.linkedFiles{nickname,"LocalFile"};
                    if ismissing(lclFile)
                        for odProp = string(fieldnames(propListing))'
                            propListing.(odProp) = '[Download required]';
                        end
                    end
                    
                    [~,stem,ext] = fileparts(obj.linkedFilesInfo{nickname,"download_link"});                                                       
                    groups(end+1) = matlab.mixin.util.PropertyGroup(propListing, "Linked File Values ('" + stem + ext + "')"); %#ok<AGROW>
                    
                end                           
            end
        end
    end
        
       
    %% CONSTRUCTOR/INITIALIZER
    
    methods
        function obj = LinkedFiles()    
            
            % Compute reverse map of props to linked files
            obj.prop2LinkedFileMap = containers.Map;
            for nickname = string(fieldnames(obj.LINKED_FILE_PROP_BINDINGS))
                propNames = obj.LINKED_FILE_PROP_BINDINGS.(nickname);                
                for propName = propNames
                    obj.prop2LinkedFileMap(propName) = nickname;
                end                
            end
            
            % Mark linked file properties as on-demand properties      
            for fileNickname = string(fieldnames(obj.LINKED_FILE_PROP_BINDINGS))'                
                obj.ON_DEMAND_PROPERTIES = [obj.ON_DEMAND_PROPERTIES obj.LINKED_FILE_PROP_BINDINGS.(fileNickname)];
            end
            
            % Include linkedFile prop in Item core props
            obj.CORE_PROPERTIES_EXTENDED = [obj.CORE_PROPERTIES_EXTENDED "linkedFiles"];
        end                              
        
    end
    
    methods  %(Access = protected)
        
        function initLinkedFiles(obj)                         
            
            % Make linkedFilesInfo easier to access
            nicknames = obj.linkedFilesInfo.nickname;
            obj.linkedFilesInfo.Properties.RowNames = nicknames;
            obj.linkedFilesInfo.nickname = [];    
            
            % Create display version of linkedFiles
            obj.linkedFiles{height(obj.linkedFilesInfo),"LocalFile"} = missing; % grow table to match height of linkedFilesInfo
            obj.linkedFiles.Properties.RowNames = nicknames;
            
            % Determine which linkedFiles have been downloaded
            boc = bot.internal.cache;
            
            for nickname = nicknames'
                                       
                fileInfo = obj.linkedFilesInfo(nickname,:); %table row            
                url = boc.strABOBaseUrl + fileInfo.download_link;
                        
                if boc.IsURLInCache(url)
                    obj.linkedFiles{nickname,"LocalFile"} =string(boc.ccCache.CachedFileForURL(url));
                end                
            end
            
            obj.linkedFilesInitialized = true;
        end
    end
    
    
  
    
end




