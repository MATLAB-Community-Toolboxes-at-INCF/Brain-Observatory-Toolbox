function plot_fluorecence_traces(nwb_dir_name, session_id, cell_id)

nwb_name = [nwb_dir_name num2str(session_id) '.nwb'];

% k dimensions of cells by n dimesions of sampling points h5read table
% imported as n dimesions of sampling points by k dimensions of cells matlab matrix
raw = h5read(nwb_name,'/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/data');
neuropil = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/neuropil_traces');
demixed = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1_demixed_signal/data');
contamination_ratio = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/r');
contamination_ratio_matrix = contamination_ratio .* eye (size(contamination_ratio,1));
neuropil_matrix = neuropil * contamination_ratio_matrix;
neuropil_corrected = demixed - neuropil_matrix;
DfOverF = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/data');

new_cell_specimen_ids = h5read(nwb_name, '/processing/brain_observatory_pipeline/ImageSegmentation/cell_specimen_ids');
nth_cell = find(new_cell_specimen_ids == cell_id);

subplot(4,1,1)
plot(raw (:,nth_cell))
title ('raw')

subplot(4,1,2)
plot(demixed (:,nth_cell))
title ('demixed')

subplot(4,1,3)
plot(neuropil_corrected(:,nth_cell))
title ('neuropil\_corrected')

subplot(4,1,4)
plot(DfOverF (:,nth_cell))
title ('DfOverF')


end