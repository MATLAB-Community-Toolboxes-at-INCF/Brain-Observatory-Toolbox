classdef VBOphysS3Bucket < bot.internal.fileresource.abstract.S3Bucket
%S3Bucket Builder of URIs for files that are part of the ABO S3 bucket
%
%   This class implements methods for retrieving URIs for data files and 
%   item tables from the Allen Brain Observatory S3 Bucket.
%
%   The class is implemented as a singleton

% Todo: Use the manifest.json in the ABO S3 root dataset folder to map
% variables to filenames / file expressions

    properties (Constant) % Define S3 bucket constants
        BucketName = "visual-behavior-ophys-data"
        RegionCode = "us-west-2"
        RootFolderName = "visual-behavior-ophys"
    end

    properties (Access = protected)
        % Filenames for item manifest tables 
        ItemTableFileNames = dictionary(...
                'BehaviorSession', uriJoin("project_metadata", "behavior_session_table.csv"), ...
                'OphysExperiment', uriJoin("project_metadata", "ophys_experiment_table.csv"), ...
                   'OphysSession', uriJoin("project_metadata", "ophys_session_table.csv"), ...
                      'OphysCell', uriJoin("project_metadata", "ophys_cells_table.csv") )
    end

    % Dataset attributes.
    properties (Constant, Access = protected, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualBehavior")
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
    end

    properties (Access = protected)
        InternalName = 's3-abo-vbo' % Allen brain observatory, visual behavior ophys
    end

    methods (Access = private) % Constructor
        function obj = VBOphysS3Bucket()
            % Constructor is private in order to implement as singleton
        end
    end
    
    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
            
            arguments
                clearResource (1,1) logical = false
            end

            import bot.internal.fileresource.visualbehavior.VBOphysS3Bucket

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = VBOphysS3Bucket();
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
        % Bucket Organization for 2-photon data : todo

        % 
            arguments
                itemObject      % Item object
                nickname char {mustBeMember(nickname, ["SessNWB", "OphysNWB", "BehaviorNWB"])}
                options.ophysExperimentId (1,1) string = ""
                options.behaviorSessionId (1,1) string = ""
            end
            
            if ~isempty(itemObject)
                if isfield(itemObject.info, 'ophys_experiment_id')
                       
                    if isempty(itemObject.info.ophys_experiment_id)
                        %pass
                    elseif isnumeric(itemObject.info.ophys_experiment_id)
                        ophysExperimentId = string(itemObject.info.ophys_experiment_id);
                    else
                        exp_id = eval(itemObject.info.ophys_experiment_id); % For session items, this is a character vector represending a list of ids
                        ophysExperimentId = string(exp_id(1));

                    end
                else
                    error('Not available')
                end
            end

            if options.ophysExperimentId ~= ""
                ophysExperimentId = options.ophysExperimentId;
            end

            if options.behaviorSessionId ~= ""
                behaviorSessionId = options.behaviorSessionId;
            end

            switch nickname

                case {'OphysNWB', 'SessNWB'} % OphysNWB      
                    folderPath = 'behavior_ophys_experiments';
                    fileName = sprintf('behavior_ophys_experiment_%s.nwb', ...
                        ophysExperimentId);
                
                case 'BehaviorNWB'
                    if ~isempty(itemObject)
                        behaviorSessionId = string(itemObject.id);
                    end
                    folderPath = 'behavior_sessions';
                    fileName = sprintf('behavior_session_%s.nwb', behaviorSessionId);
            end

            relativeFilePath = fullfile(folderPath, fileName);
        end
    end
end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    strURI = bot.internal.util.uriJoin(varargin{:});
end
