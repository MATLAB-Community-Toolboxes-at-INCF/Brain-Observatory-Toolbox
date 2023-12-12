classdef VCEphysS3Bucket < bot.internal.fileresource.abstract.S3Bucket
%S3Bucket Builder of URIs for files that are part of the ABO S3 bucket
%
%   This class implements methods for retrieving URIs for data files and 
%   item tables from the Allen Brain Observatory S3 Bucket.
%
%   The class is implemented as a singleton

% Todo: Use the manifest.json in the ABO S3 root dataset folder to map
% variables to filenames / file expressions

    properties (Constant) % Define S3 bucket constants
        BucketName = "allen-brain-observatory"
        RegionCode = "us-west-2"
        RootFolderName = "visual-coding-neuropixels"
    end

    properties (Access = protected)
        % Filenames for item manifest tables 
        ItemTableFileNames = dictionary(...
            'Session', "ecephys-cache/sessions.csv",...
              'Probe', "ecephys-cache/probes.csv", ...
            'Channel', "ecephys-cache/channels.csv", ...
               'Unit', "ecephys-cache/units.csv")
    end

    % Dataset attributes.
    properties (Constant, Access = protected, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualCoding")
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ephys;
    end

    methods (Access = private) % Constructor
        function obj = VCEphysS3Bucket()
            % Constructor is private in order to implement as singleton
        end
    end
    
    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
            
            arguments
                clearResource (1,1) logical = false
            end

            import bot.internal.fileresource.visualcoding.VCEphysS3Bucket

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = VCEphysS3Bucket();
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
        
        function relativeFilePath = getRelativeFileUriPath(itemObject, nickname)%, varargin)
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

            if isa(itemObject, 'bot.item.Session')
                experimentId = num2str(itemObject.id);

                % Hardcoded awaiting implementation 
                probeId = 1;
                movieNumber = 1;
                sceneNumber = 2;

            elseif isa(itemObject, 'bot.item.Probe')
                experimentId = num2str(itemObject.session.id);
                probeId = num2str(itemObject.id);
            end

            switch nickname

                case 'SessNWB'
                    folderPath = fullfile('ecephys-cache', sprintf('session_%s', experimentId));
                    fileName = sprintf('session_%s.nwb', experimentId);

                case {'LFPNWB', 'ProbeNWB'} % probe items..
                    folderPath = fullfile('ecephys-cache', sprintf('session_%s', experimentId));
                    fileName = sprintf('probe_%s_lfp.nwb', probeId);
        
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

                otherwise
                    error('BOT:S3Bucket', '"%s" is not a valid nickname for linked files of a Visual Coding dataset item', nickname)
            end
            relativeFilePath = fullfile(folderPath, fileName);
        end
        
    
    end

end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    strURI = bot.internal.util.uriJoin(varargin{:});
end
