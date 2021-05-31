classdef OnDemandState 
%   A class which encodes internal state for on-demand property values
       
    enumeration
        %OnDemand       % <currently do not encode the initialized "on-demand" state of these properties since this is encoded by key absence within property cache>
        
        Unavailable     % an error occurred when trying to compute/access the data previously
    end
end

