function saveSettings(handles)

try
  [File,Path] = uiputfile('TrierAnalysis_settings.mat','Save settings as...');
  
  Settings = getSettings(handles);

  %Send settings structure to base workspace
  assignin('base', 'Settings', Settings);
  
  %Save
  save(fullfile(Path,File),'Settings');
  
catch
  return
end