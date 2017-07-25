% A tutorial of transforming dfOverFData stimulated by static
% gratings or drifting gratings into a raster format to be further analyzed by neural decoding
% toolbox, see http://www.readout.info/toolbox-design/data-formats/raster-format/

%% Example: parse dfOverFData of a subexperiment: drifting_gratings from session 527745328

% set your base_directory 
base_dir_name = '/om/user/xf15/Brain-Observatory-Toolbox/';

% If you have run data_access_tutorial, you should have 527745328.nwb in
% the following directory
addpath ([base_dir_name, 'nwb_files/'])

% add path to sdk
addpath ([base_dir_name,'/sdk/data_analysis/'])

% create raster formats for all cells recoreded in session 527745328 in
% response to drifting gratings, and store them in the directory 'raster/'

raster_directory_name = [base_dir_name, 'raster/'];
transform_dfOverFData_into_raster_format('527745328.nwb', 'drifting_gratings',raster_directory_name)