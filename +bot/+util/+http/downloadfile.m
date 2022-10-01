function [resp, req, hist] = downloadfile(strLocalFilename, strURLFilename, options)
%downloadfile Download a file from web using http web services.
%
%   downloadfile(strLocalFilename, strURLFilename) downloads the file
%   specified by the url strURLFilename to the local path specified by
%   strLocalFile
%
%   resp = downloadfile(localFilename, strURLFilename) downloads the file
%   and returns a http response object
%
%   This function downloads and saves a file and shows the download
%   progress
%
%   Options for the progress display:
%       DisplayMode     : Where to display progress. Options: 'Dialog Box' (default) or 'Command Window'
%       UpdateInterval  : Interval (in seconds) for updating progress. Default = 1 second.

    arguments
        strLocalFilename       char         {mustBeNonempty}
        strURLFilename         char         {mustBeValidUrl}
        options.displayMode    char         {mustBeValidDisplay} = 'Dialog Box'
        options.updateInterval (1,1) double {mustBePositive}     = 1
        options.useMonitor     logical                           = true
    end
    
    import bot.util.http.FileDownloadProgressMonitor

    monitorOpts = {'DisplayMode', options.displayMode, 'UpdateInterval', options.updateInterval};
    opt = matlab.net.http.HTTPOptions(...
        'ProgressMonitorFcn', @(opts) FileDownloadProgressMonitor(monitorOpts{:}),...
        'UseProgressMonitor', options.useMonitor);
    
    % Create a file consumer for saving the file
    consumer = matlab.net.http.io.FileConsumer(strLocalFilename);
    
    method = matlab.net.http.RequestMethod.GET;
    req = matlab.net.http.RequestMessage(method,[],[]);
    
    strURLFilename = matlab.net.URI(strURLFilename);
    
    [resp, req, hist] = req.send(strURLFilename, opt, consumer);

    if nargout < 1
        clear resp req hist
    elseif nargout == 1
        clear req hist
    elseif nargout == 2
        clear hist
    end
    
end

%% Custom validation functions

function mustBeValidDisplay(displayName)
    mustBeMember(displayName, {'Dialog Box', 'Command Window'})
end

function mustBeValidUrl(urlString)
    try
        matlab.internal.webservices.urlencode(urlString);
    catch ME
        throwAsCaller(ME)
    end
end