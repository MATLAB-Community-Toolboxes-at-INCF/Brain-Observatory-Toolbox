% A tutorial of transforming dfOverFData stimulated by static
% gratings or drifting gratings into a raster format to be further analyzed by neural decoding
% toolbox, see http://www.readout.info/toolbox-design/data-formats/raster-format/

% If you have run data_access_tutorial, you should have 527745328.nwb in
% the following directory

addpath ('~/Brain-Observatory-Toolbox/data_access/nwb_files')

% add path for transform_dfOverFData_into_raster_format.m
addpath('~/Brain-Observatory-Toolbox/data_analysis')

% parse dfOverFData of subexperiment: drifting_gratings
transform_dfOverFData_into_raster_format('527745328.nwb', 'drifting_gratings')