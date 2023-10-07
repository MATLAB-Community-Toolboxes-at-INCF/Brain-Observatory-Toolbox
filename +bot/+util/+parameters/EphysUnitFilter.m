classdef EphysUnitFilter

    properties
        AmplitudeCutoffMaximum (1,1) double = 0.1 % Add validation... 0-1?
        PresenceRatioMinimum (1,1) double = 0.95 
        IsiViolationsMaxmimum (1,1) double = 0.5
    end

    properties (Dependent, Hidden)
        amplitude_cutoff_maximum
        presence_ratio_minimum
        isi_violations_maximum
    end

    methods % Constructor
        function obj = EphysUnitFilter(parameters)

            arguments
                parameters.AmplitudeCutoffMaximum = []
                parameters.PresenceRatioMinimum = []
                parameters.IsiViolationsMaxmimum = []
            end

            parameterNames = fieldnames(parameters);

            for i = 1:numel(parameterNames)
                parameterValue = parameters.(parameterNames{i});
                if ~isempty(parameterValue)
                    obj.(parameterNames{i}) = parameterValue;
                end
            end
        end
    end

    methods 
        function hashedValue = hash(obj)
            
            % Adapted from fex DataHash:
            % https://se.mathworks.com/matlabcentral/fileexchange/31272-datahash?s_tid=srchtitle
            
            try
                Engine = java.security.MessageDigest.getInstance('MD5');
            catch ME  % Handle errors during initializing the engine:
                if ~usejava('jvm')
                    error('BOT:hash:needJava', 'DataHash needs Java.');
                end
                error('Something went wrong')
            end

            params = [obj.AmplitudeCutoffMaximum, ...
                obj.PresenceRatioMinimum, ...
                obj.IsiViolationsMaxmimum];

            Engine.update(typecast(params(:), 'uint8'));
            hashedValue = typecast(Engine.digest, 'uint8');

            hashedValue = sprintf('%.2x', double(hashedValue));
            %hashedValue = fBase64_enc(double(hashedValue), 0);
        end
    end
    
    methods
        function obj = set.amplitude_cutoff_maximum(obj, value)
            obj.AmplitudeCutoffMaximum = value;
        end

        function value = get.amplitude_cutoff_maximum(obj)
            value = obj.AmplitudeCutoffMaximum;
        end

        function obj = set.presence_ratio_minimum(obj, value)
            obj.PresenceRatioMinimum = value;
        end

        function value = get.presence_ratio_minimum(obj)
            value = obj.PresenceRatioMinimum;
        end

        function obj = set.isi_violations_maximum(obj, value)
            obj.IsiViolationsMaxmimum = value;
        end

        function value = get.isi_violations_maximum(obj)
            value = obj.IsiViolationsMaxmimum;
        end
    end
 
end


function Out = fBase64_enc(In, doPad)
    % Encode numeric vector of UINT8 values to base64 string.
    B64 = org.apache.commons.codec.binary.Base64;
    Out = char(B64.encode(In)).';
    if ~doPad
       Out(Out == '=') = [];
    end
end
