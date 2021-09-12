classdef (Abstract) Metrics < handle
   properties (SetAccess = private)
       metrics struct = struct();
   end

   properties (Abstract, Constant)
       METRIC_PROPERTIES;
   end
   
   properties (Abstract, Hidden)
       CORE_PROPERTIES;
   end
    
   properties (Abstract)
       info;
       id;
   end
   
   methods
       function init_metrics(self)
           % - Loop over metrics for this Item
           for metric = self.METRIC_PROPERTIES %#ok<*MCNPN>
               % - Does this metric exist?
               if isfield(self.info, metric)
                   % - Move the field over
                   self.metrics.(metric) = self.info.(metric);
                   self.info = rmfield(self.info, metric);
               end
           end
           
           % - Add 'metrics' to the core properties
           self.CORE_PROPERTIES = [self.CORE_PROPERTIES "metrics"];
       end
   end
end