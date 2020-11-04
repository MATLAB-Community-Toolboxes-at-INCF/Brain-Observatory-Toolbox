%% nwb_probe -

classdef nwb_probe < handle
   properties
      strFile string;                            % Path to the NWB file
      probe_id uint32;
   end
   
   methods
      function self = nwb_probe(strFile)
         self.strFile = strFile;
         
         % - Read probe ID from NWB file
         self.probe_id = uint64(str2num(h5read(self.strFile, '/identifier'))); %#ok<ST2NM>
      end
      
      function [lfp, timestamps] = get_lfp(self)
         % - Read lfp data
         lfp = h5read(self.strFile, ...
            sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/data', self.probe_id, self.probe_id))';
         
         % - Read timestamps
         timestamps = h5read(self.strFile, ...
            sprintf('/acquisition/probe_%d_lfp/probe_%d_lfp_data/timestamps', self.probe_id, self.probe_id));
         
%          % - Convert to table
%          tLFP = array2table(lfp, 'VariableNames', arrayfun(@(e)sprintf('electrode_%d', e), 0:70, 'UniformOutput', false));
%          tLFP.timestamps = timestamps;
      end
      
   
      function [csd, timestamps, virtual_electrode_x_positions, virtual_electrode_y_positions] = get_current_source_density(self)
         % - Read CSD data
         csd = h5read(self.strFile, ...
            '/processing/current_source_density/ecephys_csd/current_source_density/data');
         
         % - Read timestamps
         timestamps = h5read(self.strFile, ...
            '/processing/current_source_density/ecephys_csd/current_source_density/timestamps');
         
         % - Read electrode position
         virtual_electrode_x_positions = h5read(self.strFile, ...
            '/processing/current_source_density/ecephys_csd/virtual_electrode_x_positions');
         virtual_electrode_y_positions = h5read(self.strFile, ...
            '/processing/current_source_density/ecephys_csd/virtual_electrode_y_positions');
      end
   end
end