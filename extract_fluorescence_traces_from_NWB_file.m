
function  [raw,demixed,neuropil_corrected,DfOverF] = extract_fluorescence_traces_from_NWB_file(nwb_directory_name, session_id)
tic
nwb_name = [num2str(session_id) '.nwb'];
addpath(genpath(nwb_directory_name))
% k dimensions of cells by n dimesions of sampling points h5read table
% imported as n dimesions of sampling points by k dimensions of cells matlab matrix
raw = h5read(nwb_name,'/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/data');
neuropil = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/neuropil_traces');
demixed = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1_demixed_signal/data');
contamination_ratio = h5read(nwb_name, '/processing/brain_observatory_pipeline/Fluorescence/imaging_plane_1/r');

% apparently nonsense but worked on 2017a
% contamination_ratio_matrix = contamination_ratio .* eye (size(contamination_ratio,1));
% neuropil_matrix = neuropil * contamination_ratio_matrix;
neuropil_matrix = neuropil .* repmat(contamination_ratio', [size(neuropil,1),1]);

neuropil_corrected = demixed - neuropil_matrix;
DfOverF = h5read(nwb_name,'/processing/brain_observatory_pipeline/DfOverF/imaging_plane_1/data');
toc
end


