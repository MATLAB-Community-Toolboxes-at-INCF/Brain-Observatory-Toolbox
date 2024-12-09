classdef OphysNWBFile < bot.internal.nwb.file.vb.BehaviorNWBFile

    properties

        % Physiology data
        TwoPhotonParameters = bot.internal.OnDemandProperty([1,1], 'struct')
        CellSpecimenTable = bot.internal.OnDemandProperty([missing, 13], 'table')
        FovAverageProjection = bot.internal.OnDemandProperty([missing, missing], 'uint8')
        FovMaximumProjection = bot.internal.OnDemandProperty([missing, missing], 'uint8')
        SegmentationMaskImage = bot.internal.OnDemandProperty([missing, missing], 'int64')
        FluorescenceTracesDemixed = bot.internal.OnDemandProperty([missing, 1], 'timetable')
        FluorescenceTracesCorrected = bot.internal.OnDemandProperty([missing, 1], 'timetable')
        FluorescenceTracesDFF = bot.internal.OnDemandProperty([missing, 1], 'timetable')
        FluorescenceTracesNeuropil = bot.internal.OnDemandProperty([missing, 1], 'timetable')
        FluorescenceEvents = bot.internal.OnDemandProperty([missing, 1], 'timetable')     
        MotionCorrection = bot.internal.OnDemandProperty([missing, 2], 'timetable')
    
        % Todo?
        % CellSpecimenIds            % Vector of cell specimen IDs recorded in this session
        % RoiMasks ( They are available in the CellSpecimenTable, but
        % should they be directy accessible?)
    end

    properties (Hidden) % Properties that are not shown to users.
        MotionCorrectionDx bot.internal.OnDemandProperty
        MotionCorrectionDy bot.internal.OnDemandProperty
    end

    methods (Access = protected)
        
        function expandPropertyMaps(obj)
        % expandPropertyMaps - Expand propertymaps with ophys properties
        %
        %   % Expand the property maps defined for the behavior NWB file
        %   with ophys specific properties / data variables.

            rootGroup = "/processing/ophys";
            
            obj.PropertyToDatasetMap("TwoPhotonParameters")         = "/general/optophysiology/imaging_plane_1/description";
            obj.PropertyToDatasetMap("CellSpecimenTable")           = rootGroup + "/image_segmentation/cell_specimen_table/id";
            obj.PropertyToDatasetMap("FovAverageProjection")        = rootGroup + "/images/average_image";
            obj.PropertyToDatasetMap("FovMaximumProjection")        = rootGroup + "/images/max_projection";
            obj.PropertyToDatasetMap("SegmentationMaskImage")       = rootGroup + "/images/segmentation_mask_image";                  
            obj.PropertyToDatasetMap("FluorescenceTracesNeuropil")  = rootGroup + "/neuropil_trace/traces/data";
            obj.PropertyToDatasetMap("FluorescenceTracesCorrected") = rootGroup + "/corrected_fluorescence/traces/data";
            obj.PropertyToDatasetMap("FluorescenceTracesDemixed")   = rootGroup + "/demixed_trace/traces/data";
            obj.PropertyToDatasetMap("FluorescenceTracesDFF")       = rootGroup + "/dff/traces/data";
            obj.PropertyToDatasetMap("FluorescenceEvents")          = rootGroup + "/event_detection/data";
            obj.PropertyToDatasetMap("MotionCorrection")            = rootGroup + "/ophys_motion_correction_x/data";
            obj.PropertyToDatasetMap("MotionCorrectionDx")          = rootGroup + "/ophys_motion_correction_x/data";
            obj.PropertyToDatasetMap("MotionCorrectionDy")          = rootGroup + "/ophys_motion_correction_y/data";

            obj.PropertyProcessingFcnMap("CellSpecimenTable") = "readCellSpecimenTable";
            obj.PropertyProcessingFcnMap("MotionCorrection") = "postprocessMotionCorrection";
            obj.PropertyProcessingFcnMap("TwoPhotonParameters") = "readOphysMetadata";
        end

        function initializeProperties(obj)
            obj.expandPropertyMaps()
            initializeProperties@bot.internal.nwb.file.vb.BehaviorNWBFile(obj)
        end

        function map = getPropertyGroupingMap(obj)
            map = getPropertyGroupingMap@bot.internal.nwb.file.vb.BehaviorNWBFile(obj);
            map{"NWB Metadata"}{end+1} = "TwoPhotonParameters"; 
            map("Physiology") = {{...
                'CellSpecimenTable', ...
                'FovAverageProjection', ...
                'FovMaximumProjection', ...
                'SegmentationMaskImage', ...                
                'FluorescenceTracesNeuropil', ...
                'FluorescenceTracesCorrected', ...
                'FluorescenceTracesDemixed', ...
                'FluorescenceTracesDFF', ...
                'FluorescenceEvents', ...
                'MotionCorrection' ...
                }};
        end
    end
    
    methods (Access = ?bot.internal.nwb.LinkedNWBFile)
        function metadata = readOphysMetadata(obj, ~)
            metadata = bot.internal.nwb.reader.readOphysMetadata(obj.FilePath);
        end

        function data = readCellSpecimenTable(obj, ~)
            data = bot.internal.nwb.reader.vb.read_cell_specimen_table(obj.FilePath);
        end

        function data = postprocessMotionCorrection(obj, data)
            data.Properties.VariableNames = {'x'};
            y = obj.fetchData("MotionCorrectionDy");
            data.y = y.MotionCorrectionDy;
        end
    end
end