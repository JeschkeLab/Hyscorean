function [FileNames,FilePaths,CancelFlag]=multiload_mod
%==========================================================================
% Save Settings
%==========================================================================
% Load multiple or single files through GUI and store path and filenames
% into cell array
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2018-2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================
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

