status = system('which s3fs');
if status ~= 0
    system('sudo apt-get update');
    system('sudo apt-get install s3fs');
end
system('mkdir ~/s3-allen');
[status,cmdout] = system('s3fs -o public_bucket=1 -o umask=0022 allen-brain-observatory ~/s3-allen');