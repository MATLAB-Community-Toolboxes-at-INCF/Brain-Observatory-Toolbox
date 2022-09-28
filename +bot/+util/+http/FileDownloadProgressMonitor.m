classdef FileDownloadProgressMonitor < matlab.net.http.ProgressMonitor
    
    properties
        DisplayMode = 'Dialog Window';  % 'Dialog Window' or 'Command Window'
        Direction matlab.net.http.MessageType
        Value uint64
        NewDir matlab.net.http.MessageType = matlab.net.http.MessageType.Request
    end

    properties (Dependent)
        FileSizeMb
        DownloadedMb
        PercentDownloaded
    end

    properties (Access = private)
        StartTime
        WaitbarHandle
    end
    
    methods
        function obj = FileDownloadProgressMonitor
            obj.Interval = 1;
            obj.StartTime = tic;
        end
        
        function done(obj)
            obj.closeit();
        end
        
        function delete(obj)
            obj.closeit();
        end
        
        function set.Direction(obj, dir)
            obj.Direction = dir;
            obj.changeDir();
        end
        
        function set.Value(obj, value)
            obj.Value = value;
            obj.update();
        end

        function fileSizeMb = get.FileSizeMb(obj)
            fileSizeMb = round( double(obj.Max) / 1024 / 1024 );
        end

        function downloadedMb = get.DownloadedMb(obj)
            downloadedMb = round( double(obj.Value) / 1024 / 1024 );
        end

        function percentDownloaded = get.PercentDownloaded(obj)
            percentDownloaded = double(obj.Value)/double(obj.Max)*100;
        end

    end
    
    methods (Access = private)
        function update(obj,~)
            % called when Value is set
            import matlab.net.http.*
            
            if ~isempty(obj.Value)
                msg = '';

                if isempty(obj.Max)
                    % no maximum means we don't know length, so message 
                    % changes on every call
                    progressValue = 0;
                    if obj.Direction == MessageType.Request
                        msg = sprintf('Sent %d bytes...', obj.Value);
                    else
                        msg = sprintf('Received %d bytes...', obj.Value);
                    end
                else
                    % maximum known, update proportional value
                    progressValue = obj.PercentDownloaded / 100;
                    if obj.NewDir == MessageType.Request
                    
                        if obj.Direction == MessageType.Request
                            msg = 'Sending...';
                        else
                            msg = obj.getProgressMessage();
                        end
                    else
                        msg = obj.getProgressMessage();
                    end
                end

                if isempty(obj.WaitbarHandle)
                    % if we don't have a progress bar, display it for first time
                    obj.WaitbarHandle = ...
                        waitbar(progressValue, msg, 'CreateCancelBtn', ...
                            @(~,~)cancelAndClose(obj));
                    obj.NewDir = MessageType.Response;
                    
                elseif obj.NewDir == MessageType.Request || isempty(obj.Max)
                    % on change of direction or if no maximum known, change message
                    waitbar(progressValue, obj.WaitbarHandle, msg);
                    obj.NewDir = MessageType.Response;
                else
                    % no direction change else just update proportional value
                    waitbar(progressValue, obj.WaitbarHandle, msg);
                end
            end
            
            function cancelAndClose(obj)
                % Call the required CancelFcn and then close our progress bar. 
                % This is called when user clicks cancel or closes the window.
                obj.CancelFcn();
                obj.closeit();
            end
        end
        
        function changeDir(obj,~)
            % Called when Direction is set or changed.  Leave the progress 
            % bar displayed.
            obj.NewDir = matlab.net.http.MessageType.Request;
        end
    end
    
    methods (Access = private)
        function closeit(obj)
            % Close the progress bar by deleting the handle so 
            % CloseRequestFcn isn't called, because waitbar calls 
            % cancelAndClose(), which would cause recursion.
            if ~isempty(obj.WaitbarHandle)
                delete(obj.WaitbarHandle);
                obj.WaitbarHandle = [];
            end
        end
    end


    methods (Access = private)
        
        function strMessage = getProgressMessage(obj)
        %getProgressMessage Get message showing progress.
            strMessage = sprintf('Downloaded %d MB/%d MB...', ...
                            obj.DownloadedMb, obj.FileSizeMb);

            strRemainingTime = obj.getRemainingTimeEstimate();
            if ~isempty(strRemainingTime)
                strMessage = strrep(strMessage, '...', '.');
                strMessage = sprintf('%s %s', strMessage, strRemainingTime);
            end
        end

        function str = getRemainingTimeEstimate(obj)
                     
            tElapsed = seconds( toc(obj.StartTime) );
            tRemaining = round( (tElapsed ./ obj.PercentDownloaded) .* (100-obj.PercentDownloaded) );
    
            if seconds(tElapsed) > 10
                if hours(tRemaining) > 1
                    str = sprintf('Estimated time remaining: %d hours...', round(hours(tRemaining)));
                elseif minutes(tRemaining) > 1
                    str = sprintf('Estimated time remaining: %d minutes...', round(minutes(tRemaining)));
                else
                    str = sprintf('Estimated time remaining: %d seconds...', seconds(tRemaining));
                end
            else
                str = '';
            end
        end
    end

end