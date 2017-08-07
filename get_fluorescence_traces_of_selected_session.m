
function  [raw,demixed,neuropil_corrected,DfOverF] = get_fluorescence_traces_of_selected_session (session_id)
tic
nwb_name = [num2str(session_id) '.nwb'];

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
toc
end


