function saveHyscorean(handles)

set(handles.ProcessingInfo, 'String', 'Status: Saving session'); drawnow;
CrushFlag = false;
SaveHyscoreanSettings = handles.SaveHyscoreanSettings;
% Prepare saving directory and path
%----------------------------------------------------------------------

%Load default/predefined save path
load Hyscorean_default_savepath.mat

% Prepare saving procedures
DateFormatOut = 'yyyymmdd';
Date = datestr(date,DateFormatOut);

%Get file identifier
Identifier = SaveHyscoreanSettings.IdentifierName;

SaveDirectory = sprintf('%s_%s',Date,Identifier);
FullPath = fullfile(SavePath,SaveDirectory);

% If directory does not exist create it
if ~exist(FullPath,'dir') 
    mkdir(FullPath)
end


% Save current settings
%----------------------------------------------------------------------
  Settings = getSettings(handles);
  %Send settings structure to base workspace
  assignin('base', 'Settings', Settings);
  %Format savename so until it is different from the rest in the folder
  SaveName = sprintf('%s_%s_settings.mat',Date,Identifier);
  CopyIndex = 1;
  while true
    if ~exist(fullfile(FullPath,SaveName),'file')
      break
    end
    CopyIndex = CopyIndex + 1;
    CrushFlag = true;
    SaveName = sprintf('%s_%s_settings_%i.mat',Date,Identifier,CopyIndex);
    
  end
  save(fullfile(FullPath,SaveName),'Settings');

  set(handles.ProcessingInfo, 'String', 'Status: Saving session 25%'); drawnow;

  
% Save data
%----------------------------------------------------------------------  
Spectrum = handles.Processed.spectrum;
ProcessedSignal = handles.Processed.Signal;
RawSignal = handles.Data.Integral;
TimeAxis1 = handles.Processed.TimeAxis1;
TimeAxis2 = handles.Processed.TimeAxis2;
FrequencyAxis1 = handles.Processed.axis1;
FrequencyAxis2 = handles.Processed.axis2;
%Format savename so until it is different from the rest in the folder
  SaveName = sprintf('%s_%s_OutputData.mat',Date,Identifier);
  if CrushFlag
      SaveName = sprintf('%s_%s_OutputData_%i.mat',Date,Identifier,CopyIndex);
  end
  save(fullfile(FullPath,SaveName),'Spectrum','ProcessedSignal','RawSignal','TimeAxis1','TimeAxis1','FrequencyAxis1','FrequencyAxis2');

  set(handles.ProcessingInfo, 'String', 'Status: Saving session 50%'); drawnow;

% Save main figure
%----------------------------------------------------------------------  
GhostFigure = figure('Visible','off','Position',[100 100 790 450]); % Invisible figure
copyobj(handles.mainPlot,GhostFigure)

set(GhostFigure,'CreateFcn','set(gcbf,''Visible'',''on'')'); % Make it visible upon loading
%Format savename so until it is different from the rest in the folder
  SaveName = sprintf('%s_%s_spectrum',Date,Identifier);  
  if CrushFlag
      SaveName = sprintf('%s_%s_spectrum_%i',Date,Identifier,CopyIndex);
  end

%Save as Matlab figure (.fig)
savefig(GhostFigure,fullfile(FullPath,[SaveName '.fig']), 'compact');
%Export as PDF (.pdf)
% export_fig(fullfile(FullPath,SaveName),'-pdf','-transparent')
print(GhostFigure,fullfile(FullPath,SaveName),'-dpdf')
%Delete the ghost figure
delete(GhostFigure);

set(handles.ProcessingInfo, 'String', 'Status: Saving session 75%'); drawnow;


% Create report
%----------------------------------------------------------------------  
reportdata = Settings;
%Load data into report structure
reportdata.Processed = handles.Processed;
reportdata.GraphicalSettings = handles.GraphicalSettings;
%Add experimental parameters if they have been processed
if isfield(handles,'ExperimentParameters')
  reportdata.ExperimentParameters = handles.ExperimentParameters;
  reportdata.PlotPulses= handles.PlotPulses;
end
%Add regularization parameters if they have been employed
if isfield(handles,'RegularizationParameters')
  reportdata.RegularizationParameters = handles.RegularizationParameters;
end
reportdata.Data = handles.Data;
reportdata.TauValues = handles.Data.TauValues;
reportdata.TimeStep1 = handles.Data.TimeStep1;
reportdata.TimeStep2 = handles.Data.TimeStep2;
Offset = get(handles.FieldOffset,'string');
reportdata.FieldOffset = str2double(Offset(1:end-2));
reportdata.currentTaus = handles.currentTaus;
reportdata.BrukerParameters = handles.Data.BrukerParameters;
reportdata.L2GActive = get(handles.Lorentz2GaussCheck,'Value');
reportdata.mainPlotHandle = handles.mainPlot;
BackgroundAxis = linspace(min(reportdata.Data.CorrectedTimeAxis1),max(reportdata.Data.CorrectedTimeAxis1),length(reportdata.Data.Background1));      
reportdata.BackgroundStart1 = round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex1),0);
reportdata.BackgroundStart2 =round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex2),0);
reportdata.MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
%Extract pulse lengths
PulseSpelText = reportdata.BrukerParameters.PlsSPELGlbTxt;
Pulse90DefinitionIndex = strfind(PulseSpelText,'p0   = ');
Pulse180DefinitionIndex = strfind(PulseSpelText,'p1   = ');
Shift = 7;
while ~isspace(PulseSpelText(Pulse90DefinitionIndex + Shift))
  Pulse90String(Shift - 2) =  PulseSpelText(Pulse90DefinitionIndex + Shift);
  Shift = Shift + 1;
end
Shift = 7;
while ~isspace(PulseSpelText(Pulse180DefinitionIndex + Shift))
  Pulse180String(Shift - 2) =  PulseSpelText(Pulse180DefinitionIndex + Shift);
  Shift = Shift + 1;
end
reportdata.Pulse90Length  = str2double(Pulse90String);
reportdata.Pulse180Length  = str2double(Pulse180String);
%Store apodization window 
WindowDecay = str2double(get(handles.Hammingedit,'string'));
    WindowMenuState = get(handles.WindowType,'value');
  switch WindowMenuState
    case 1
     WindowType =  'hamming';
    case 2
     WindowType =  'chebyshev';  
    case 3
     WindowType =  'welch';
    case 4
      WindowType = 'blackman'; 
    case 5
      WindowType = 'bartlett';
    case 6
      WindowType = 'connes';
    case 7
      WindowType = 'cosine';      
  end
  [~,Window] = apodizationWin(handles.Processed.Signal,WindowType,WindowDecay);
TimeAxis1 = handles.Processed.TimeAxis1(1:length(handles.Processed.TimeAxis1)-str2double(get(handles.ZeroFilling1,'String')));
Window = Window/max(Window);
Window = Window';
if WindowDecay>=length(TimeAxis1)
  Window=Window(1:length(TimeAxis1));
end
if WindowDecay<length(TimeAxis1)
  Window=[Window zeros(1,length(TimeAxis1)-WindowDecay)];
end
reportdata.WindowType = WindowType;
reportdata.ApodizationWindow = Window;
%Cosntruct report
%Format savename so until it is different from the rest in the folder
  ReportName = sprintf('%s_%s_report',Date,Identifier);
  if CrushFlag
      ReportName = sprintf('%s_%s_report_%i',Date,Identifier,CopyIndex);
  end
  reportdata.filename = ReportName;
  reportdata.path = FullPath;
  
  %Add name and patyh of the original data file
    reportdata.OriginalFileName = handles.FilePaths.Files;
  reportdata.OriginalFilePath = handles.FilePaths.Path;

%Send structure to workspace
assignin('base', 'reportdata', reportdata);

%Generate report
 report Hyscorean_report -fpdf ;
 
 set(handles.ProcessingInfo, 'String', 'Status: Session saved'); drawnow;
