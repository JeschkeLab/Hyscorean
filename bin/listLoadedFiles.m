function  [RawData,FilePaths,SelectionMade] = listLoadedFiles(RawData,FilePaths)
%==========================================================================
% List Loaded Files
%==========================================================================
% This function Gets a list of the different data files loaded into the
% system and displays them in a GUI window. The user can then manually
% remove some of them instead of reloading all files.
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

FileList = FilePaths.Files;
FolderString = sprintf('Folder:%s',FilePaths.Path);
[RemovedFiles,SelectionMade] = listdlg('PromptString',FolderString,'ListSize',[500 500],...
  'SelectionMode','multiple','OKString','Remove',...
  'ListString',FileList);

%If something has been changed then adapt the loaded files accordingly
if SelectionMade
  for Index = 1:length(RemovedFiles)
    FilePaths.Files{RemovedFiles(Index)} = {};
    RawData{RemovedFiles(Index)} = {};
  end
  FilePaths.Files(cellfun('isempty', FilePaths.Files)) = [];
  RawData(cellfun('isempty', RawData)) = [];
end

return