classdef BrainObservatoryAPI < handle
%BrainObservatoryAPI Wrapper for the Allen Brain Observatory API

% See this page for documentation on the RMA service:
% https://allensdk.readthedocs.io/en/latest/allensdk.api.queries.rma_api.html
%
% See this page for detailed information on the RMA service:
% http://help.brain-map.org/display/api/RESTful+Model+Access+%28RMA%29


    properties (Constant, Hidden)           
        SCHEME = "http";
        HOST = "api.brain-map.org";
        RMA_SERVICE_PATH = "api/v2/data"                      % RMA Service (relative path)
        WKN_SERVICE_PATH = "api/v2/well_known_file_download"  % WKN Service (relative path)
        %API_ENDPOINTS = ["data", "well_known_file_download"]
    end

    properties
        queryFormat = "query.json" % Format of rma query (json, xml or csv)
    end

    properties (Dependent)
        ApiBaseUrl     % Base url for the allen institute api
        RmaServiceUrl  % Base url for the allen rma service
        WknServiceUrl  % Base url for the allen wkn service
    end

    properties (Constant, Hidden)
        % Well known file id for ophys cell id mappings (Used anywhere?)
        CELL_ID_MAPPING_FILE_ID = 590985414     % Well known file id for cell id mapping of ophys experiments
    end
    

    methods
        function apiBaseURL = get.ApiBaseUrl(obj)
            apiBaseURL = obj.SCHEME + "://" + obj.HOST;
        end
                
        function rmaServiceUrl = get.RmaServiceUrl(obj)
            rmaServiceUrl = bot.util.uriJoin( obj.ApiBaseUrl, ...
                 obj.RMA_SERVICE_PATH, obj.queryFormat );
        end

        function wknServiceUrl = get.WknServiceUrl(obj)
            wknServiceUrl = bot.util.uriJoin( obj.ApiBaseUrl, ...
                 obj.WKN_SERVICE_PATH );
        end
    end

    methods 
        function fileUrl = getWellKnownFileUrl(obj, fileID)
            fileUrl = bot.util.uriJoin(obj.WknServiceUrl, string(fileID));
        end
    end

    methods (Static)

        function criteriaModelStr = getRMACriteriaModel(itemType)
            criteriaModelStr = sprintf("criteria=model::%s", itemType);
        end

        function rmaOptionsStr = getRMAPagingOptions(nStartRow, nPageSize, sortName)
        %getRMAPagingOptions Get options for multipage RMA query
            arguments
                nStartRow = 0
                nPageSize = 5000
                sortName = "id"
            end

            startFilter  = "start_row$eq" + nStartRow;
            lengthFilter = "num_rows$eq" + nPageSize;
            orderFilter  = "order$eq'" + sortName + "'";
            
            rmaOptionsStr = sprintf( "rma::options[%s][%s][%s]", ...
                startFilter, lengthFilter, orderFilter);
        end

    end

    methods (Static, Access = private)

        function axisStep = getRMAAxisStep(axisName, axisId)
            axisStep = string(axisName) + "::" + string(axisId);
        end
    
    end
    
end