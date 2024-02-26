classdef VCOphysS3Bucket < bot.internal.fileresource.abstract.S3Bucket
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
        RootFolderName = "visual-coding-2p"
    end

    properties (Access = protected)
        % Filenames for item manifest tables 
        ItemTableFileNames = dictionary(...
               'Experiment', "experiment_containers.json", ...
                  'Session', "ophys_experiments.json", ...
                     'Cell', "cell_specimens.json")
    end


    % Dataset attributes.
    properties (Constant, Access = protected, Hidden)
        DATASET = bot.item.internal.enum.Dataset("VisualCoding")
        DATASET_TYPE = bot.item.internal.enum.DatasetType.Ophys;
    end

    properties (Access = protected)
        InternalName = 's3-allen' % Allen brain observatory (visual coding)
    end
    
    methods (Access = private) % Constructor
        function obj = VCOphysS3Bucket()
            % Constructor is private in order to implement as singleton
        end
    end
    
    methods (Static) % Static method for retrieving singleton instance
        function fileResource = instance(clearResource)
        %instance Get a singleton instance of the S3Bucket class
            
            arguments
                clearResource (1,1) logical = false
            end

            import bot.internal.fileresource.visualcoding.VCOphysS3Bucket

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = VCOphysS3Bucket();
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
                options.ExperimentID = []
            end

            if ~isempty(itemObject)
                experimentId = num2str(itemObject.id);
                sessionName = itemObject.session_type;
            end

            if isempty(itemObject) && ~isempty(options.ExperimentID)
                experimentId = string( options.ExperimentID );
            end
        
            switch nickname
        
                case {'OphysNWB', 'SessNWB'}
                    folderPath = 'ophys_experiment_data';
                    fileName = sprintf('%s.nwb', experimentId);
        
                case 'AnalysisH5'
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
    end

end

function strURI = uriJoin(varargin)
%uriJoin Join segments of a URI using the forward slash (/)
    strURI = bot.internal.util.uriJoin(varargin{:});
end
