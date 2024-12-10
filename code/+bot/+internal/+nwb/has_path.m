function bHasPath = has_path(strNWBFile, strNWBPath)

try
   h5info(strNWBFile, strNWBPath);
   bHasPath = true;
catch
   bHasPath = false;
end