classdef FileDownloadProgressMonitor < matlab.net.http.ProgressMonitor
%FileDownloadProgressMonitor Updates a progress monitor for file downloads.
%
%   Create a function handle to provide to matlab.net.http.HTTPOptions:
%
%       progressMonitorFcn = @bot.util.http.FileDownloadProgressMonitor;
%
%   Create a function handle to provide to matlab.net.http.HTTPOptions
%   while specifying custom options for the monitor:
%
%   monitorOptions = {'DisplayMode', 'Command Window'};
%   progressMonitorFcn = @(varargin) bot.util.http.FileDownloadProgressMonitor(monitorOptions{:})
%
%   Supported options:
%       DisplayMode     : Where to display progress. Options: 'Dialog Box' (default) or 'Command Window'
%       UpdateInterval  : Interval (in seconds) for updating progress. Default = 1 second.


    properties (SetAccess = private) % Monitor user settings
        DisplayMode = 'Dialog Box';  % Where to display progress.
        UpdateInterval = 1           % Interval (in seconds) for updating progress.
    end

    properties % Implement superclass properties (matlab.net.http.ProgressMonitor)
        Direction matlab.net.http.MessageType
        Value uint64
    end

    properties (Dependent)
        FileSizeMb
        DownloadedMb
        PercentDownloaded
        UseWaitbarDialog
        UseCommandWindow
    end

    properties (Access = private)
        StartTime
        LastUpdateTime
        HasDownloadStarted = false
        WaitbarHandle
        PreviousMessage = ''
    end
    
    methods
        function obj = FileDownloadProgressMonitor(varargin)
            
            % Parse optional inputs and assign as property values
            [names, values] = obj.parseVarargin(varargin);
            for i = 1:numel(names)
                if isprop(obj, names{i})
                    obj.(names{i}) = values{i};
                end
            end
            
            obj.Interval = 1;
            [obj.StartTime, obj.LastUpdateTime] = deal( tic );
        end
        
        function done(obj)
            obj.closeWaitbar();
        end
        
        function delete(obj)
            obj.closeWaitbar();
        end
        
        function set.Direction(obj, dir)
            obj.Direction = dir;
            %fprintf('Direction set: %s\n', obj.Direction)
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

        function tf = get.UseWaitbarDialog(obj)
            tf = strcmpi(obj.DisplayMode, 'Dialog Box');
        end

        function tf = get.UseCommandWindow(obj)
            tf = strcmpi(obj.DisplayMode, 'Command Window');
        end
    end
    
    methods (Access = private)

        function update(obj, ~)
        %update Called when Value is set, handles monitor updating

            import matlab.net.http.*
            
            doUpdate = toc(obj.LastUpdateTime) > obj.UpdateInterval;

            if ~isempty(obj.Value) && doUpdate
                
                if isempty(obj.Max)
                    % Maxmimum (size of request/response) is not known, 
                    % file download did not start yet.
                    progressValue = 0;
                    msg = 'Waiting for download to start...';
                else
                    % Maximum known, update proportional value
                    progressValue = obj.PercentDownloaded / 100;
                    if obj.Direction == MessageType.Request
                        msg = 'Receiving...';
                    else
                        if ~obj.HasDownloadStarted
                            obj.HasDownloadStarted = true;
                        end
                        msg = obj.getProgressMessage();
                    end
                end

                if isempty(obj.WaitbarHandle) && obj.UseWaitbarDialog
                    % If we don't have a progress bar, display it for first time
                    obj.WaitbarHandle = waitbar(progressValue, msg, ...
                        'CreateCancelBtn', @(~,~) cancelAndClose(obj));
                elseif isempty(obj.PreviousMessage) && obj.UseCommandWindow
                    obj.updateCommandWindowMessage(msg)
                end

                if obj.HasDownloadStarted
                    if obj.UseWaitbarDialog
                        waitbar(progressValue, obj.WaitbarHandle, msg);
                    else
                        obj.updateCommandWindowMessage(msg)
                    end
                end

                obj.LastUpdateTime = tic;
            end
            
            function cancelAndClose(obj)
                % Call the required CancelFcn and then close our progress bar. 
                % This is called when user clicks cancel or closes the window.
                obj.CancelFcn();
                obj.closeit();
            end
        end
        
        function updateCommandWindowMessage(obj, msgStr)
            
            if ~isempty(obj.PreviousMessage)
                fprintf(char(8*ones(1, length(obj.PreviousMessage)+1)));
            end
            % Print on new line to prevent messy output in case users enter
            % input on the command window.
            fprintf('\n%s', msgStr);
            obj.PreviousMessage = msgStr;
        end

    end
    
    methods (Access = private)
        function closeWaitbar(obj)
            % Close the progress waitbar by deleting the handle so 
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
        %getProgressMessage Get message with information about progress
            strMessage = sprintf('Downloaded %d MB/%d MB (%d%%)...', ...
                            obj.DownloadedMb, obj.FileSizeMb, round(obj.PercentDownloaded));

            strRemainingTime = obj.getRemainingTimeEstimate();
            if ~isempty(strRemainingTime)
                strMessage = replace(strMessage, '...', '.');
                strMessage = sprintf('%s %s', strMessage, strRemainingTime);
            end
            
            % "Animate" ellipsis
            if isempty(obj.PreviousMessage)
                % Skip
            elseif strcmp( obj.PreviousMessage(end-2:end), '...')
                strMessage(end-1:end) = []; % Remove two dots, one remaining
            elseif strcmp( obj.PreviousMessage(end-1:end), '..')
                % Keep three dots.
            else
                strMessage(end) = []; % Remove last dot, two remaining
            end
        end

        function str = getRemainingTimeEstimate(obj)
        %getRemainingTimeEstimate Get string with estimated time remaining        
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

    methods (Static)
        
        function [names, values] = parseVarargin(vararginCellArray)
        %parseVarargin Parse varargin (split names and values)
            [names, values] = deal({});
            
            if isempty(vararginCellArray)
                return
            elseif numel(vararginCellArray) == 1 && isstruct(vararginCellArray{1})
                names = fieldnames(vararginCellArray{1});
                values = struct2cell(vararginCellArray{1});
            else
                names = vararginCellArray(1:2:end);
                values = vararginCellArray(2:2:end);
            end
        end
    end
end