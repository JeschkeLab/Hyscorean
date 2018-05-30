function handles = saveGUI(handles)

load TierAnalysis_default_savepath.mat

% Prepare saving procedures
DateFormatOut = 'yyyymmdd';
Date = datestr(date,DateFormatOut);

SaveDirectory = sprintf('%s_TrierAnalysis_save',Date);
FullPath = fullfile(SavePath,SaveDirectory);

% If directory does not exist create it
if ~exist(FullPath,'dir')
    mkdir(FullPath)
end

%Remove Extension
File = File(1:length(File)-4);

Extension = '.mat';

%Data to be exported
Processed = handles.Processed;
Data = handles.Data;

handles.filename = File;
handles.path = Path;

handles.savename = fullfile(Path,File);


%save([fullfile(Path,File) Extension],'Processed','Data');

