function fileSizeBytes = getWebFileSize(webFileUrl)
%getWebFileSize Get file size of a file on the web
%
%   fileSizeBytes = getWebFileSize(filepath) returns the filesize in
%   bytes for a file at the specified web url

    import matlab.net.URI
    import matlab.net.http.RequestMessage
    
    uri = URI(webFileUrl);
    req = RequestMessage('HEAD');
    response = req.send(uri);
    contentLengthField = response.getFields("Content-Length");
    
    fileSizeBytes = str2double(contentLengthField.Value);
end