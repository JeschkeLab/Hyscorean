function [FileNames,FilePaths,CancelFlag]=multiload_mod
%Load multiple or single files through GUI and store path and filenames
%into cell array
%
%L. Fabregas, Hyscorean 2018

if nargout>3
  error('Too many output arguments');
end
CancelFlag = false;
FileNames = [];
FilePaths = [];
[Files, Path]=uigetfile({'*.*'},'MultiSelect','on');
try
  if Files==0
    CancelFlag = true;
    return;
  else
  end
catch
end
FilePaths.Files = Files;
FilePaths.Path = Path;
NFiles = length(str2double(Files));

FileNames = cell(1,NFiles);
if NFiles > 1
  for iFiles=1:NFiles
    FileNames{iFiles} = fullfile(Path,Files{iFiles});
  end
else
  FileNames{1} = fullfile(Path,Files);
end
end