classdef WebApi < bot.internal.abstract.FileResource

    properties (Constant)
        API = bot.internal.BrainObservatoryAPI
    end

    properties (Hidden)
        CellIdMappingId = '590985414' 
        %ecephys_product_id = 714914585;
    end

    properties (Access = private)
        % Filenames for item manifest tables 
        ItemTableModelName = struct(...
            'Ephys', struct(   'Session', "EcephysSession",...
                                 'Probe', "EcephysProbe", ...
                               'Channel', "EcephysChannel", ...
                                  'Unit', "EcephysUnit"), ...
            'Ophys', struct('Experiment', "ExperimentContainer", ...
                               'Session', "OphysExperiment", ...
                                  'Cell', "ApiCamCellMetric") )

        ItemQueryString = struct(...
            'Ephys', struct(   'Session', "rma::include,specimen(donor(age)),well_known_files(well_known_file_type)",...
                                 'Probe', "", ...
                               'Channel', "rma::include,structure,rma::options[tabular$eq'ecephys_channels.id,ecephys_probe_id as ephys_probe_id,local_index,probe_horizontal_position,probe_vertical_position,anterior_posterior_ccf_coordinate,dorsal_ventral_ccf_coordinate,left_right_ccf_coordinate,structures.id as ephys_structure_id,structures.acronym as ephys_structure_acronym']", ...
                                  'Unit', ""), ...
            'Ophys', struct('Experiment', "rma::include,ophys_experiments,isi_experiment,specimen(donor(conditions,age,transgenic_lines)),targeted_structure", ...
                               'Session', "rma::include,experiment_container,well_known_files(well_known_file_type),targeted_structure,specimen(donor(age,transgenic_lines))", ...
                                  'Cell', "") )    

    end

    methods (Access = private) % Constructor
        function obj = WebApi()
        end
    end

    methods
        function tf = isMounted(~) %#ok<STOUT> 
            error('BOT:NotSupported', ...
                'Web API can not be mounted as local file system.');
        end

        function strURI = getDataFileURI(obj, itemObject, fileNickname, varargin)
            error('Not implemented yet')
            % Todo: 
            % Get linked file path (or well known file info) from itemObject
        end

        function strURI = getItemTableURI(obj, datasetType, itemType)
             
            % - Validate inputs
            datasetType = validatestring(datasetType, ["Ephys", "Ophys"]);
            itemType = validatestring(itemType, ["Experiment", "Session", "Channel", "Probe", "Unit", "Cell"]);

            % - Build the URL for an item table query using the web api    
            baseURL = obj.API.RmaServiceUrl;

            modelName = obj.ItemTableModelName.(datasetType).(itemType);
            queryCriteria = obj.API.getRMACriteriaModel(modelName);

            apiURL = baseURL + "?" + queryCriteria;

            extraQueryParams = obj.ItemQueryString.(datasetType).(itemType);

            if extraQueryParams ~= ""
                apiURL = apiURL + "," + extraQueryParams;
            end

            strURI = apiURL;
        end

    end

    methods (Static)
        function fileResource = instance(clearResource)

            arguments
                clearResource (1,1) logical = false
            end

            persistent FILE_RESOURCE
            
            % - Construct the file resource if instance is not present
            if isempty(FILE_RESOURCE)
                FILE_RESOURCE = bot.internal.fileresource.WebApi();
            end
            
            % - Return the instance
            fileResource = FILE_RESOURCE;
            
            % - Clear the file resource if requested
            if clearResource
                FILE_RESOURCE = [];
                clear fileResource;
            end
        end
    end

end