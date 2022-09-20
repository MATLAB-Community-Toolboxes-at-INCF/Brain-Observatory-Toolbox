function fileSizeBytes = getLocalFileSize(filepath)
    L = dir(filepath);
    fileSizeBytes = L.bytes;
end