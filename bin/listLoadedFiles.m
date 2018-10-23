function  [RawData,FilePaths,SelectionMade] = listLoadedFiles(RawData,FilePaths)


str = FilePaths.Files;
message = sprintf('Folder:%s',FilePaths.Path);
[RemovedFiles,SelectionMade] = listdlg('PromptString',message,'ListSize',[500 500],...
                'SelectionMode','multiple','OKString','Remove',...
                'ListString',str);
              
if SelectionMade   
   for Index = 1:length(RemovedFiles)
   FilePaths.Files{RemovedFiles(Index)} = {};
   RawData{RemovedFiles(Index)} = {};
   end
   
   FilePaths.Files(cellfun('isempty', FilePaths.Files)) = [];
   RawData(cellfun('isempty', RawData)) = [];

end