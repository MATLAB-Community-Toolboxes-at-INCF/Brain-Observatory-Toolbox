classdef VBEphysS3Bucket < bot.internal.fileresource.abstract.S3Bucket
%S3Bucket Builder of URIs for files that are part of the ABO S3 bucket
%
%   This class implements methods for retrieving URIs for data files and 
%   item tables from the Allen Brain Observatory S3 Bucket.
%
%   The class is implemented as a singleton

% Todo: Use the manifest.json in the ABO S3 root dataset folder to map
% variables to filenames / file expressions

    properties (Constant)
        BucketName = "visual-behavior-neuropixels-data"
        RegionCode = "us-west-2"
        RootFolderName = "visual-behavior-neuropixels"
    end

    properties (Access = protected)
        % Filenames for item manifest tables 
        ItemTableFileNames = dictionary(...
            'BehaviorSession', uriJoin("project_metadata", "behavior_sessions.csv"), ...
               'EphysSession', uriJoin("project_metadata", "ecephys_sessions.csv"), ...
                      'Probe', uriJoin("project_metadata", "probes.csv"), ...
                    'Channel', uriJoin("project_metadata", "channels.csv"), ...
                       'Unit', uriJoin("project_metadata", "units.csv") )
    end
    
    % Dataset attributes.
    properties (Constant, Access = protected, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualBehavior")
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
    end

    properties (Access = protected)
        InternalName = 's3-abo-vbe' % Allen brain observatory, visual behavior ephys
    end

    methods (Access = private) % Constructor
        function obj = VBEphysS3Bucket()
            % Constructor is private in order to implement as singleton
        end
    end

    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
        
            arguments
                clearResource (1,1) logical = false
            end

            import bot.internal.fileresource.visualbehavior.VBEphysS3Bucket
            
            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = VBEphysS3Bucket();
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
    
        function relativeFilePath = getRelativeFileUriPath(itemObject, nickname, options)
        %getRelativeFileUriPath Get subfolders and filename for file given nickname
        %
        % Bucket Organization for neuropixels data :
        %   EphysNwb
        %   ProbeNwb
        %   BehaviorNWB

            arguments
                itemObject      % Item object
                nickname char {mustBeMember(nickname, ["SessNWB", "EphysNWB", "BehaviorNWB", "ProbeNWB", "LFPNWB"])}
                options.ephysSessionId (1,1) string = ""
                options.behaviorSessionId (1,1) string = ""
                options.probeName = ""
            end
            
            if ~isempty(itemObject)
                exp_id = itemObject.info.ephys_session_id; %??
                ephysSessionId = string(exp_id);
                if isa(itemObject, 'bot.behavior.item.Probe') || isa(itemObject, 'bot.item.Probe')
                    probeName = itemObject.info.name;
                end
            end

            if options.ephysSessionId ~= ""
                ephysSessionId = options.ephysSessionId;
            end

            if options.behaviorSessionId ~= ""
                behaviorSessionId = options.behaviorSessionId;
            end

            if options.probeName ~= ""
                probeName = options.probeName;
            end

            switch nickname
        
                case 'SessNWB'    
                    folderPath = fullfile('behavior_ecephys_sessions', ephysSessionId);
                    fileName = sprintf('ecephys_session_%s.nwb', ...
                        ephysSessionId);
                
                case 'EphysNWB' % valid?
                    folderPath = 'behavior_ecephys_sessions';
                    fileName = sprintf('ecephys_session_%s.nwb', ...
                        ephysSessionId);

                case 'BehaviorNWB'
                    if ~isempty(itemObject)
                        behaviorSessionId = string(itemObject.id);
                    end
                    folderPath = fullfile('behavior_only_sessions', behaviorSessionId);
                    fileName = sprintf('behavior_session_%s.nwb', behaviorSessionId);

                case {'LFPNWB', 'ProbeNWB'}     
                    folderPath = fullfile('behavior_ecephys_sessions', ephysSessionId);
                    fileName = sprintf('probe_%s_lfp.nwb', probeName);
            end

            relativeFilePath = fullfile(folderPath, fileName);
        end
    end

end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    strURI = bot.internal.util.uriJoin(varargin{:});
end
