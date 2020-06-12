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
      
   
      function [csd, timestamps, horizontal_position, vertical_position] = get_current_source_density(self)
         % - Read CSD data
         csd = h5read(self.strFile, ...
            '/processing/current_source_density/current_source_density/data');
         
         % - Read timestamps
         timestamps = h5read(self.strFile, ...
            '/processing/current_source_density/current_source_density/timestamps');
         
         % - Read electrode position
         control = h5read(self.strFile, ...
            '/processing/current_source_density/current_source_density/control')';
         horizontal_position = control(:, 1);
         vertical_position = control(:, 2);
      end
   end
end