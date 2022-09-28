function [resp, req, hist] = downloadfile(strLocalFilename, strURLFilename)
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

%   Todo: Add optional arguments
%       progressDisplayMode

    opt = matlab.net.http.HTTPOptions(...
        'ProgressMonitorFcn',@bot.util.http.FileDownloadProgressMonitor,...
        'UseProgressMonitor',true);
    
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