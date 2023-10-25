classdef S3Bucket < bot.internal.abstract.FileResource
%S3Bucket Builder of URIs for files that are part of the ABO S3 bucket
%
%   This class implements methods for retrieving URIs for data files and 
%   item tables from the Allen Brain Observatory S3 Bucket.
%
%   The class is implemented as a singleton

% Todo: Use the manifest.json in the ABO S3 root dataset folder to map
% variables to filenames / file expressions

    properties (Constant, Abstract)
        % Name of AWS S3 bucket
        BucketName

        % Region code of AWS S3 bucket
        RegionCode
    end

    properties (Dependent)

        % Base URI for the Allen Brain Observatory S3 Bucket (s3 protocol)
        S3BaseUri

        % Base URL for the Allen Brain Observatory S3 Bucket (https protocol)
        S3BaseUrl
        
        % Directory path if S3 bucket is mounted as a local file system     % Todo: Should this be a preference instead?
        S3LocalMount
    end

    properties (Abstract, Access = protected)
        % Folder in the S3 bucket for ephys data or ophys
        S3DataFolder

        % Filenames for item manifest tables 
        ItemTableFileNames
    end

    properties (Access = private)
        InternalName = 's3-abo-vbo' % Allen brain observatory, visual behavior ophys
    end

    properties (Dependent) % Todo: Access = protected
        PreferredScheme
    end

    methods (Access = protected) % Constructor
        function obj = S3Bucket()
            % Constructor is protected in order to implement as singleton
        end
    end

    methods % Dependent property get methods
        function baseUri = get.S3BaseUri(obj)
            baseUri = sprintf("s3://%s", obj.BucketName);
        end

        function baseUrl = get.S3BaseUrl(obj)
            baseUrl = sprintf("https://%s.s3.%s.amazonaws.com", obj.BucketName, obj.RegionCode);
        end
                   
        function pathStr = get.S3LocalMount(obj)
            pathStr = fullfile("/home", "ubuntu", obj.InternalName); % Todo: Should get from preferences
        end
    end


    methods % Public methods
        function tf = isMounted(~)
        %isMounted Determine if s3 bucket is mounted as local file system
            tf = bot.internal.Preferences.getPreferenceValue('UseLocalS3Mount') && ...
                isfolder( bot.internal.Preferences.getPreferenceValue('S3MountDirectory') );
        end

        function strURI = getDataFileURI(obj, itemObject, fileNickname, varargin)
        %getDataFileURI Get URI for a data file (file belonging to item)
            filename = obj.getRelativeFileUriPath(itemObject, fileNickname, varargin{:});
            baseURI = obj.getDataFolderUri(itemObject.getDatasetType);
            strURI = uriJoin(baseURI, filename);
        end

        function strURI = getItemTableURI(obj, datasetType, itemType)
        %getItemTableURI Get URI for item table

            datasetType = validatestring(datasetType, ["Ephys", "Ophys"]);
            itemType = validatestring(itemType, ["Experiment", "Session", "Channel", "Probe", "Unit", "Cell"]);

            filename = obj.ItemTableFileNames.(datasetType).(itemType);
            baseURI = obj.getDataFolderUri(datasetType);
            strURI = uriJoin(baseURI, filename);
        end
    end

    methods % Set /get
        
        function preferredScheme = get.PreferredScheme(obj)
            if obj.isMounted() && ~obj.useCloudCacher()
                preferredScheme = "file";
            else
                preferredScheme = "https";
            end

            if obj.useS3Protocol() % Todo
                preferredScheme = 's3';
            end

            % Note. The s3 scheme is currently not in use, but might be
            % relevant if a mode is implemented where on demand properties
            % are retrieved from a file on the s3 instead of a local file.
        end
        
    end

    methods % Could be methods of a potential abstract S3Bucket class
        function baseUrl = getVirtualHostedStyleBaseUrl(obj)
        %getVirtualHostedStyleBaseUrl Get base url in virtual-hosted–style

        %   Amazon S3 virtual-hosted–style URLs use the following format:
        %       https://bucket-name.s3.region-code.amazonaws.com/key-name

            baseUrl = sprintf('https://%s.s3.%s.amazonaws.com', ...
                obj.BucketName, obj.RegionCode);
        end

        function baseUrl = getS3SchemeBaseUrl(obj)
        %getS3SchemeBaseUrl Get base url in s3 scheme format
        %
        %   A url using the S3 scheme has the following format:
        %       S3://bucket-name/key-name
            
            baseUrl = sprintf('s3://%s', obj.BucketName);
        end
    end

    methods (Hidden, Access = protected)

        function tf = retrieveFileFromS3Bucket(~)
            tf = bot.internal.Preferences.getPreferenceValue('DownloadFrom') == "S3";
        end
        
        function tf = useCloudCacher(~)
            tf = bot.internal.Preferences.getPreferenceValue('UseCacheWithS3Mount');
        end

        function tf = useS3Protocol(~)
            try
                tf = strcmp( bot.internal.Preferences.getPreferenceValue('DownloadMode'), 'Variable'); %#ok<UNRCH> 
            catch
                tf = false;
            end
        end
    end

    methods (Access = protected)
        
        function folderURI = getDataFolderUri(obj, datasetType, currentScheme)
            arguments
                obj bot.internal.fileresource.abstract.S3Bucket % Object of this class
                datasetType string {mustBeMember(datasetType, ["Ephys", "Ophys"])}
                currentScheme string {mustBeMember(currentScheme, ["s3", "https", "file", ""])} = ""
            end
            
            if currentScheme == ""
                currentScheme = obj.PreferredScheme;
            end

            switch lower(currentScheme)
                case 's3'
                    baseURI = obj.S3BaseUri;
                case 'https'
                    baseURI = obj.S3BaseUrl;
                case 'file'
                    baseURI = "file://" + obj.S3LocalMount;
            end

            folderURI = uriJoin( baseURI, obj.S3DataFolder.(datasetType) );
        end
    
        function relativePathURI = getRelativeFileUriPath(obj, itemObject, fileNickname, varargin) %#ok<INUSL> 
            
            itemClassName = class(itemObject);
            itemClassNameSplit = strsplit(itemClassName, '.');

            filenameLookupFcn = str2func(sprintf('%s.get%sFileRelativePath', class(obj), itemClassNameSplit{end}));

            relativePathURI = filenameLookupFcn(itemObject, fileNickname, varargin{:});
        end

    end

    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
        
            arguments
                clearResource (1,1) logical = false
            end

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = bot.internal.fileresource.abstract.S3Bucket();
            end
            
            % - Return the instance
            fileResource = FILE_RESOURCE;
            
            % - Clear the fle resource if requested
            if clearResource
                FILE_RESOURCE = [];
                clear fileResource;
            end
        end
    end

    methods (Static)
    
        function relativeFilePath = getEphysSessionFileRelativePath(itemObject, nickname)%, varargin)
        %getS3BranchPath Get subfolders and filename for file given nickname
        %
        % Bucket Organization for neuropixels data :
        % 
        % visual-coding-neuropixels
        % +-- ecephys-cache                  # packaged processed ExtraCellular Electrophysiology data
        % ¦   +-- manifest.json              # used by AllenSDK to look up file paths
        % ¦   +-- sessions.csv               # metadata for each experiment session
        % ¦   +-- probes.csv                 # metadata for each experiment probe
        % ¦   +-- channels.csv               # metadata for each location on a probe
        % ¦   +-- units.csv                  # metadata for each recorded signal
        % ¦   +-- brain_observatory_1.1_analysis_metrics.csv         # pre-computed metrics for brain observatory stimulus set
        % ¦   +-- functional_connectivity_analysis_metrics.csv       # pre-computed metrics for functional connectivity stimulus set
        % ¦   +-- session_<experiment_id>
        % ¦   ¦   +-- session_<experiment_id>.nwb                    # experiment session nwb
        % ¦   ¦   +-- probe_<probe_id>_lfp.nwb                       # probe lfp nwb
        % ¦   ¦   +-- session_<experiment_id>_analysis_metrics.csv   # pre-computed metrics for experiment
        % ¦   +-- ...
        % ¦   +-- natural_movie_templates
        % ¦   ¦   +-- natural_movie_1.h5                    # stimulus movie
        % ¦   ¦   +-- natural_movie_3.h5                    # stimulus movie
        % ¦   +-- natural_scene_templates
        % ¦   ¦   +-- natural_scene_<image_id>.tiff         # stimulus image
        % ¦   ¦   +-- ...
        % +-- raw-data                       # Sorted spike recordings and unprocessed data streams
        % ¦   +-- <experiment_id>
        % ¦   ¦   +-- sync.h5                # Information describing the synchronization of experiment data streams
        % ¦   ¦   +-- <probe_id>
        % ¦   ¦   ¦ +-- channel_states.npy   #
        % ¦   ¦   ¦ +-- event_timestamps.npy #
        % ¦   ¦   ¦ +-- lfp_band.dat         # Local field potential data
        % ¦   ¦   ¦ +-- spike_band.dat       # Spike data
        % ¦   ¦   +-- ...
        % ¦   +-- ...

            arguments
                itemObject             % Class object
                nickname char          % One of: SessNWB
                %probeId = 1 % Todo
                %movieNumber = 1 % Todo
                %sceneNumber = 1 % Todo
            end
            
            %assert(strcmp(nickname, 'SessNWB') || strcmp(nickname, 'StimTemplatesGroup'), ...
            %    'Currently only supports files with nickname SessNWB')

            experimentId = num2str(itemObject.id);

            % Hardcoded awaiting implementation 
            probeId = 1;
            movieNumber = 1;
            sceneNumber = 2;

            switch nickname

                case 'SessNWB'
                    folderPath = fullfile('ecephys-cache', sprintf('session_%s', experimentId));
                    fileName = sprintf('session_%s.nwb', experimentId);
        
                case 'StimTemplatesGroup'
                    relativeFilePath = obj.getS3BranchPath('StimMovie'); return
                    
                case 'StimMovie'
                    folderPath = fullfile('ecephys-cache', 'natural_movie_templates');
                    fileName = sprintf('natural_movie_%d.h5', movieNumber);
        
                case 'StimScene'
                    folderPath = fullfile('ecephys-cache', 'natural_scene_templates');
                    fileName = sprintf('natural_scene_%d.tiff', sceneNumber);
        
                case 'SyncH5'
                    folderPath = fullfile('raw_data', experimentId, probeId);
                    fileName = 'sync.h5';
                
                case 'ChStatesNpy'
                    folderPath = fullfile('raw_data', experimentId, probeId);
                    fileName = 'channel_states.npy';
                
                case 'EventTsNpy'
                    folderPath = fullfile('raw_data', experimentId, probeId);
                    fileName = 'event_timestamps.npy';
        
                case 'LFPDAT'
                    folderPath = fullfile('raw_data', experimentId, probeId);
                    fileName = 'lfp_band.dat';
        
                case 'SPKDAT'
                    folderPath = fullfile('raw_data', experimentId, probeId);
                    fileName = 'spike_band.dat';
            end
            relativeFilePath = fullfile(folderPath, fileName);
        end
        
        function relativeFilePath = getOphysSessionFileRelativePath(itemObject, nickname)
        %getS3BranchPath Get subfolders and filename for file given nickname
        %
        % Bucket Organization for 2-photon data :
        % 
        % visual-coding-2p
        % +-- ophys_experiment_data       # traces, running speed, etc per experiment session
        % ¦   +-- <experiment_id>.nwb
        % ¦   +-- ...
        % +-- ophys_experiment_analysis   # analysis files per experiment session
        % ¦   +-- <experiment_id>_<session_name>.h5 (*)
        % ¦   +-- ...
        % +-- ophys_movies                # motion-corrected video per experiment session
        % ¦   +-- ophys_experiment_<experiment_id>.h5
        % ¦   +-- ...
        % +-- ophys_experiment_events     # neuron activity modeled as discrete events
        % ¦   +-- <experiment_id>_events.npz
        % ¦   +-- ...
        % +-- ophys_eye_gaze_mapping      # subject eye position over the course of the experiment
        % ¦   +-- <experiment_id>_<session_id>_eyetracking_dlc_to_screen_mapping.h5
        % ¦   +-- ...
        %
        % Notes:
        %  * Analysis files are named <experiment_id>_<session_name>_analysis.h5

            arguments
                itemObject      % Item object
                nickname char   % One of : SessNWB
            end
            
            assert(strcmp(nickname, 'SessNWB'), ...
                'Currently only supports files with nickname SessNWB')
            
            experimentId = num2str(itemObject.id);
            sessionName = itemObject.session_type;
        
            switch nickname
        
                case 'SessNWB'       
                    folderPath = 'ophys_experiment_data';
                    fileName = sprintf('%s.nwb', experimentId);
        
                case 'AnalH5' 
                    folderPath = 'ophys_experiment_analysis';
                    fileName = sprintf('%s_%s_analysis.h5', experimentId, sessionName);
        
                case 'Movie'
                    folderPath = 'ophys_movies';
                    fileName = sprintf('ophys_experiment_%s.h5', experimentId);
        
                case 'Events'
                    folderPath = 'ophys_experiment_events';
                    fileName = sprintf('%s_events.npz', experimentId);
                
                case 'EyeH5'
                    error('File is not available')
                    folderPath = 'ophys_eye_gaze_mapping';
                    fileName = sprintf('%s_%s_eyetracking_dlc_to_screen_mapping.h5', experimentId, itemObject.sessionId);
            end
            relativeFilePath = fullfile(folderPath, fileName);
        end

        function relativeFilePath = getProbeFileRelativePath(itemObject, nickname)
        %getProbeFileRelativePath Get subfolders and filename for file given nickname
        %
        % See bot.internal.fileresource.abstract.S3Bucket/getEphysSessionFileRelativePath 
        % for details on the internal S3 bucket folder hierarchy.

            arguments
                itemObject      % Class object
                nickname char   % One of: LFPNWB
            end

            assert(strcmp(nickname, 'LFPNWB'), ...
                'Currently only supports files with nickname LFPNWB')

            experimentId = num2str(itemObject.session.id);
            probeId = num2str(itemObject.id);
        
            switch nickname
        
                case 'LFPNWB' % probe objects..
                    folderPath = fullfile('ecephys-cache', sprintf('session_%s', experimentId));
                    fileName = sprintf('probe_%s_lfp.nwb', probeId);
        
                otherwise
                    error('BOT:S3Bucket', '%s is not a valid nickname for linked files of a probe', nickname)
            end
            relativeFilePath = fullfile(folderPath, fileName);
        end
    end

    methods (Static)
    end
end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    if isa(varargin{1}, 'string')
        listOfStrings = [varargin{:}];
        strURI = join(listOfStrings, "/");
    elseif isa(varargin{1}, 'char')
        listOfStrings = varargin;
        strURI = strjoin(listOfStrings, '/');
    end
end

