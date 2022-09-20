function fileSizeBytes = getWebFileSize(webFileUrl)

    import matlab.net.URI;
    import matlab.net.http.RequestMessage;
    
    uri = URI(webFileUrl);
    req = RequestMessage('HEAD');
    response = req.send(uri);
    contentLengthField = response.getFields("Content-Length");
    
    fileSizeBytes = str2double(contentLengthField.Value);

end