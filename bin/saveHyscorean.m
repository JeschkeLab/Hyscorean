function saveHyscorean(handles)

set(handles.ProcessingInfo, 'String', 'Status: Saving session'); drawnow;
CrushFlag = false;
SaveHyscoreanSettings = handles.SaveHyscoreanSettings;
% Prepare saving directory and path
%----------------------------------------------------------------------

%Load default/predefined save path
SavePath = getpref('hyscorean','savepath');
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

  set(handles.ProcessingInfo, 'String', 'Status: Saving session 20%'); drawnow;

  
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

  set(handles.ProcessingInfo, 'String', 'Status: Saving session 40%'); drawnow;

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

set(handles.ProcessingInfo, 'String', 'Status: Saving session 60%'); drawnow;


% Create report
%----------------------------------------------------------------------  

if getpref('hyscorean','reportlicense')
reportdata = Settings;
%Load data into report structure
reportdata.Processed = handles.Processed;
reportdata.GraphicalSettings = handles.GraphicalSettings;
reportdata.Data = handles.Data;
reportdata.TauValues = handles.Data.TauValues;
reportdata.TimeStep1 = handles.Data.TimeStep1;
reportdata.TimeStep2 = handles.Data.TimeStep2;
Offset = get(handles.FieldOffset,'string');
reportdata.FieldOffset = str2double(Offset);
reportdata.currentTaus = handles.currentTaus;
reportdata.L2GActive = get(handles.Lorentz2GaussCheck,'Value');
reportdata.mainPlotHandle = handles.mainPlot;
BackgroundAxis = linspace(min(reportdata.Data.CorrectedTimeAxis1),max(reportdata.Data.CorrectedTimeAxis1),length(reportdata.Data.Background1));      
reportdata.BackgroundStart1 = round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex1),0);
reportdata.BackgroundStart2 = round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex2),0);
reportdata.MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));

%Bruker-spectrometer specific parameters
if isfield(handles.Data,'BrukerParameters')
BrukerParameters = handles.Data.BrukerParameters;
%Extract pulse lengths
PulseSpelText = BrukerParameters.PlsSPELGlbTxt;
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
reportdata.MW_Frequency = BrukerParameters.MWFQ/1e9;
reportdata.ShotRepTime = str2double(BrukerParameters.ShotRepTime(1:strfind(BrukerParameters.ShotRepTime,' ')));
reportdata.ShotsPerLoop = BrukerParameters.ShotsPLoop;
reportdata.NbScansDone = BrukerParameters.NbScansDone;
reportdata.CenterField = str2double(BrukerParameters.CenterField(1:strfind(BrukerParameters.CenterField,' ')));
reportdata.XDimension = BrukerParameters.XPTS;
reportdata.YDimension = BrukerParameters.YPTS;
reportdata.VideoGain = str2double(BrukerParameters.VideoGain(1:strfind(BrukerParameters.VideoGain,' ')));
reportdata.VideoBandwidth = str2double(BrukerParameters.VideoBW(1:strfind(BrukerParameters.VideoBW,' ')));
end

%AWG-spectrometer specific parameters
if isfield(handles.Data,'AWG_Parameters')
AWG_Parameters = handles.Data.AWG_Parameters;
reportdata.Pulse90Length  = AWG_Parameters.events{1}.pulsedef.tp;
reportdata.Pulse180Length  = AWG_Parameters.events{3}.pulsedef.tp;
reportdata.MW_Frequency = AWG_Parameters.LO + AWG_Parameters.nu_obs;
reportdata.ShotRepTime = AWG_Parameters.reptime/1e6;
reportdata.ShotsPerLoop = AWG_Parameters.shots;
reportdata.NbScansDone = AWG_Parameters.store_avgs;
reportdata.CenterField = round(AWG_Parameters.B,0);
reportdata.XDimension = AWG_Parameters.hyscore_t1.dim;
reportdata.YDimension = AWG_Parameters.hyscore_t2.dim;
reportdata.VideoGain = NaN;
reportdata.VideoBandwidth = NaN;
end

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
  if  isfield(handles.Data,'AWG_Parameters')
    reportdata.OriginalFileName = sprintf('%i files',length(handles.FilePaths.Files));
  else
    reportdata.OriginalFileName = handles.FilePaths.Files;
  end
    reportdata.OriginalFilePath = handles.FilePaths.Path;
  HyscoreanPath = which('Hyscorean');
  HyscoreanPath = HyscoreanPath(1:end-11);
reportdata.ProcessingReport_logo_Path = [HyscoreanPath 'bin/ProcessingReport_logo.png'];
%Send structure to workspace
assignin('base', 'reportdata', reportdata);

%Generate report
 report Hyscorean_report -fpdf ;
 
else
  warning('MATLAB report generator not installed or license not found. Report generation was skipped.')
end
 set(handles.ProcessingInfo, 'String', 'Status: Saving session 80%'); drawnow;

 
% Save data for Easyspin fitting
%----------------------------------------------------------------------  
DataForFitting.Spectrum = handles.Processed.spectrum;
reportdata.Data = handles.Data;
DataForFitting.TauValues = handles.Data.TauValues/1000; %us
DataForFitting.TimeStep1 = handles.Data.TimeStep1;  %us
DataForFitting.TimeStep2 = handles.Data.TimeStep2;  %us
Offset = get(handles.FieldOffset,'string');
DataForFitting.FieldOffset = 0.1*str2double(Offset); %mT
DataForFitting.currentTaus = handles.currentTaus;
DataForFitting.Lorentz2GaussCheck = get(handles.Lorentz2GaussCheck,'Value');
DataForFitting.BackgroundStart1 = round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex1),0);
DataForFitting.BackgroundStart2 =round(1000*BackgroundAxis(reportdata.Data.BackgroundStartIndex2),0);
if isfield(handles.Data,'BrukerParameters')
  DataForFitting.Field = 0.1*str2double(handles.Data.BrukerParameters.CenterField(1:6)); %mT
elseif isfield(handles.Data,'AWG_Parameters')
  DataForFitting.Field =  0.1*handles.Data.AWG_Parameters.B;%mT
end
DataForFitting.nPoints = length(handles.Data.PreProcessedSignal);
DataForFitting.ZeroFillFactor = length(handles.Processed.Signal)/length(handles.Data.PreProcessedSignal);
DataForFitting.FreqLim = str2double(get(handles.XUpperLimit,'string'));
DataForFitting.WindowType = handles.WindowTypeString;
DataForFitting.WindowDecay = str2double(get(handles.Hammingedit,'string'));
DataForFitting.L2GParameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
DataForFitting.L2GParameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
DataForFitting.L2GParameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
DataForFitting.L2GParameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));


%Send settings structure to base workspace
assignin('base', 'DataForFitting', DataForFitting);
%Format savename so until it is different from the rest in the folder
SaveName = sprintf('%s_%s_DataForFitting.mat',Date,Identifier);
CopyIndex = 1;
while true
  if ~exist(fullfile(FullPath,SaveName),'file')
    break
  end
  CopyIndex = CopyIndex + 1;
  CrushFlag = true;
  SaveName = sprintf('%s_%s_DataForFitting_%i.mat',Date,Identifier,CopyIndex);
end
save(fullfile(FullPath,SaveName),'DataForFitting');

 set(handles.ProcessingInfo, 'String', 'Status: Session saved'); drawnow;

 
 