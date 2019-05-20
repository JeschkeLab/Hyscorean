function saveHyscorean(handles)
%==========================================================================
% Hyscorean Save&Report Protocol
%==========================================================================
% This function is responsible for the generation and execution of the
% saving functionality of the main Hyscorean GUI. The function takes care
% of the following saves:
%     -> A .m file with the current processing settings
%     -> A .m file with the raw and processed signal and spectra
%     -> A copy of the main display window in .fig and .pdf format
%     -> A .m file with the data necessary to launch the fitting module
%     -> A automatically generated processing report with all information
%
% NOTE: If the export_fig package is installed on MATLAB the exported PDF 
% figure will be exported in high-defintion. Otherwise the standard MATLAB 
% print function is employed.
% (See the Hyscorean manual for further details) 
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Inform user that saving process has started
set(handles.ProcessingInfo, 'String', 'Status: Saving session'); drawnow;

%Initiallize some variables
CrashFlag = false;
SaveHyscoreanSettings = handles.SaveHyscoreanSettings;
GraphicalSettings = handles.GraphicalSettings;

%==========================================================================
% Prepare saving directory and path
%==========================================================================

%Load default/predefined save path
SavePath = getpref('hyscorean','savepath');
% Prepare saving procedures
DateFormatOut = 'yyyymmdd';
Date = datestr(date,DateFormatOut);
%Get file identifier
Identifier = SaveHyscoreanSettings.IdentifierName;
%Get file path
SaveDirectory = sprintf('%s_%s',Date,Identifier);
FullPath = fullfile(SavePath,SaveDirectory);
% If directory does not exist create it
if ~exist(FullPath,'dir') 
    mkdir(FullPath)
end

%==========================================================================
% Save current settings
%==========================================================================

%Get current processing settings from the GUI
Settings = getSettings(handles);
%Send settings structure to base workspace for save to work
assignin('base', 'Settings', Settings);
%Format savename until it is different from the rest in the folder
SaveName = sprintf('%s_%s_settings.mat',Date,Identifier);
CopyIndex = 1;
while true
  %If name is different stop
  if ~exist(fullfile(FullPath,SaveName),'file')
    break
  end
  %Otherwise just increase the counter number and add to name
  CopyIndex = CopyIndex + 1;
  CrashFlag = true;
  SaveName = sprintf('%s_%s_settings_%i.mat',Date,Identifier,CopyIndex);
end
%Save settings to file
save(fullfile(FullPath,SaveName),'Settings');
%Now remove the variable from the base workspace
evalin( 'base', 'clear Settings' )
%Inform the user of succesful step
set(handles.ProcessingInfo, 'String', 'Status: Saving session 20%'); drawnow;

%==========================================================================  
% Save data
%========================================================================== 

%Get spectrum and frequency axis
Spectrum = handles.Processed.spectrum;
FrequencyAxis1 = handles.Processed.axis1;
FrequencyAxis2 = handles.Processed.axis2;
%Get raw and processed signal and time axes
ProcessedSignal = handles.Processed.Signal;
RawSignal = handles.Data.Integral;
TimeAxis1 = handles.Processed.TimeAxis1;
TimeAxis2 = handles.Processed.TimeAxis2;
%Use the same formatting in name as before to avoid filename clash
SaveName = sprintf('%s_%s_OutputData.mat',Date,Identifier);
if CrashFlag
  SaveName = sprintf('%s_%s_OutputData_%i.mat',Date,Identifier,CopyIndex);
end
%Save data to file
save(fullfile(FullPath,SaveName),'Spectrum','ProcessedSignal','RawSignal','TimeAxis1','TimeAxis1','TimeAxis2','FrequencyAxis1','FrequencyAxis2');
%Inform user of succesful completed step
set(handles.ProcessingInfo, 'String', 'Status: Saving session 40%'); drawnow;

%==========================================================================
% Save main figure
%==========================================================================  

%Open a ghost figure, invisible to the user
GhostFigure = figure('Visible','off','Units','pixels','Position',[100 100 776 415]);
%Copy the main display exactly as it is...
AxesHandles = copyobj(handles.mainPlot,GhostFigure);
%... and just format a bit the size and its relative position in the new figure
set(AxesHandles,'Position',[0.07 0.12 0.9 0.85]);
%Use the same formatting in name as before to avoid filename clash
  SaveName = sprintf('%s_%s_spectrum',Date,Identifier);  
  if CrashFlag
      SaveName = sprintf('%s_%s_spectrum_%i',Date,Identifier,CopyIndex);
  end

%Get the handles to the contour plot  
ContourHandle = findobj(GhostFigure,'Type','contour');
%Create a new ghost figure to hold the false contour plot 
GhostFigure2 = figure('Visible','off','Position',[100 100 776 415]); % Invisible figure
set(GhostFigure2.Children,'Position',[0.07 0.12 0.9 0.85]);
%Convert heavy contour plot to light false-contour plot
contour2lineplot_hyscorean(ContourHandle,1,GraphicalSettings.ColormapName,GraphicalSettings.LineWidth);
%Delete the ghost figure containing the heavy contour plot
delete(GhostFigure);
%Format the new axis of the remaining ghost figure to be as before
Limits = str2double(get(handles.XUpperLimit,'string'));
xlim([-Limits Limits])
ylim([0 Limits])
xlabel('\nu_1 [MHz]')
ylabel('\nu_2 [MHz]')
grid on
hold on
box on
plot(handles.Processed.axis1,abs(handles.Processed.axis1),'k-.')
plot(zeros(length(handles.Processed.axis1)),handles.Processed.axis1,'k')
currentXTicks = xticks(GhostFigure2.Children);
yticks(GhostFigure2.Children,currentXTicks(currentXTicks>=0))
set(GhostFigure2.Children,'yticklabel',currentXTicks(currentXTicks>=0),'xticklabel',currentXTicks)

%Define a create function for ghost figure, so that when it is later opened by user, it dislplays normally
set(GhostFigure2,'CreateFcn','set(gcbf,''Visible'',''on'')');
%Save as Matlab figure (.fig)
savefig(GhostFigure2,fullfile(FullPath,[SaveName '.fig']), 'compact');
%Save as high-definition or normal PDF figure (.pdf)
if exist('export_fig','file')
export_fig(fullfile(FullPath,SaveName),'-pdf','-transparent',GhostFigure2)
else
print(GhostFigure2,fullfile(FullPath,SaveName),'-dpdf')
end
%Delete the ghost figure
delete(GhostFigure2);

%Inform user of succesfull step
set(handles.ProcessingInfo, 'String', 'Status: Saving session 60%'); drawnow;

%==========================================================================
% Create report
%==========================================================================  

%Check if license exists and continue if so
if getpref('hyscorean','reportlicense')
  
  %Get generic parameters or variables needed for report
  reportdata = Settings;
  reportdata.Processed = handles.Processed;
  reportdata.GraphicalSettings = GraphicalSettings;
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
  %Store apodization window
  WindowDecay1 = str2double(get(handles.WindowLength1,'string'));
  WindowDecay2 = str2double(get(handles.WindowLength2,'string'));
  WindowType = handles.WindowTypeString;
  [~,Window1,Window2] = apodizationWin(handles.Processed.Signal,WindowType,WindowDecay1,WindowDecay2);
  TimeAxis1 = handles.Processed.TimeAxis1(1:length(handles.Processed.TimeAxis1)-str2double(get(handles.ZeroFilling1,'String')));
  TimeAxis2 = handles.Processed.TimeAxis2(1:length(handles.Processed.TimeAxis2)-str2double(get(handles.ZeroFilling2,'String')));
  Window2 = Window2/max(Window2);
  Window1 = Window1/max(Window1);
  Window1 = Window1';
  Window1 = Window2';
  if WindowDecay1>=length(TimeAxis1)
    Window1=Window1(1:length(TimeAxis1));
  else
    Window1=[Window1 zeros(1,length(TimeAxis1)-WindowDecay1)];
  end
  if WindowDecay2>=length(TimeAxis2)
    Window2=Window2(1:length(TimeAxis2));
  else
    Window2=[Window2 zeros(1,length(TimeAxis2)-WindowDecay2)];
  end
  reportdata.WindowType = WindowType;
  reportdata.ApodizationWindow1 = Window1;
  reportdata.ApodizationWindow2 = Window2;
  reportdata.WindowLength1 = WindowDecay1;
  reportdata.WindowLength2 = WindowDecay2;
  strings = get(handles.Symmetrization_ListBox,'string');
  reportdata.Symmetrization = strings(get(handles.Symmetrization_ListBox,'Value'));
  
  %Get BRUKER spectrometer-specific parameters and variables
  if isfield(handles.Data,'BrukerParameters')
    BrukerParameters = handles.Data.BrukerParameters;
    if isfield(BrukerParameters,'PlsSPELGlbTxt')
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
      reportdata.VideoGain = str2double(BrukerParameters.VideoGain(1:strfind(BrukerParameters.VideoGain,' ')));
      reportdata.VideoBandwidth = str2double(BrukerParameters.VideoBW(1:strfind(BrukerParameters.VideoBW,' ')));
    else
      reportdata.Pulse90Length  = NaN;
      reportdata.Pulse180Length  = NaN;
      reportdata.MW_Frequency = NaN;
      reportdata.ShotRepTime = NaN;
      reportdata.ShotsPerLoop = NaN;
      reportdata.NbScansDone = NaN;
      reportdata.CenterField = NaN;
      reportdata.VideoGain = NaN;
      reportdata.VideoBandwidth = NaN;

    end
    if handles.Data.NUSflag
      reportdata.XDimension = handles.Data.NUS.Dimension1;
      reportdata.YDimension = handles.Data.NUS.Dimension2;
      reportdata.NUSflag = true;
    else
      reportdata.XDimension = BrukerParameters.XPTS;
      reportdata.YDimension = BrukerParameters.YPTS;
      reportdata.NUSflag = false;
    end

  end
  
  %Get AWG spectrometer-specific parameters and variables
  if isfield(handles.Data,'AWG_Parameters')
    AWG_Parameters = handles.Data.AWG_Parameters;
    if ~isfield(AWG_Parameters,'NUS_flag')
      AWG_Parameters.NUS_flag = false;
    end
    reportdata.NUSflag  = AWG_Parameters.NUS_flag;
    reportdata.Pulse90Length  = AWG_Parameters.events{1}.pulsedef.tp;
    reportdata.Pulse180Length  = AWG_Parameters.events{3}.pulsedef.tp;
    reportdata.MW_Frequency = AWG_Parameters.LO + AWG_Parameters.nu_obs;
    reportdata.ShotRepTime = AWG_Parameters.reptime/1e6;
    reportdata.ShotsPerLoop = AWG_Parameters.shots;
    reportdata.NbScansDone = AWG_Parameters.store_avgs;
    reportdata.CenterField = round(AWG_Parameters.B,0);
    if AWG_Parameters.NUS_flag
      reportdata.XDimension = AWG_Parameters.NUS.Dimension1;
      reportdata.YDimension = AWG_Parameters.NUS.Dimension2;
      reportdata.NUSgrid = AWG_Parameters.NUS.SamplingGrid;
    else
      reportdata.XDimension = AWG_Parameters.hyscore_t1.dim;
      reportdata.YDimension = AWG_Parameters.hyscore_t2.dim;
    end
    reportdata.VideoGain = NaN;
    reportdata.VideoBandwidth = NaN;
  end
  
  %Get NUS-specific parameters and variables
  if reportdata.NUSflag
    switch get(handles.ReconstructionAlgorithm,'Value')
      case 1 %Constant-lambda CAMERA Reconstruction
        reportdata.ReconstructionMethod = 'Constant-aim CAMERA';
      case 2 %CAMERA
        reportdata.ReconstructionMethod = 'CAMERA';
      case 3 %FFM-CG
        reportdata.ReconstructionMethod = 'FFM-CG';
      case 4 %FFM-GD
        reportdata.ReconstructionMethod = 'FFM-GD';
      case 5 %IST-S Reconstruction
        reportdata.ReconstructionMethod = 'IST-S';
      case 6 %IST-D Reconstruction
        reportdata.ReconstructionMethod = 'IST-D';
    end
    reportdata.BackgroundParameter = str2double(get(handles.MaxEntBackgroundParameter,'string'));
    reportdata.LagrangeMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));
    reportdata.ReconstructionFunctional = handles.Data.ReconstructionConvergence;
    SampledPoints = length(find(reportdata.Data.NUSgrid==1));
    FullSampling = reportdata.XDimension*reportdata.YDimension;
    reportdata.SamplingDensity = sprintf('%.2f%%',round(100*SampledPoints/FullSampling,2));
  end
  
  %Use the same formatting in name as before to avoid filename clash
  ReportName = sprintf('%s_%s_report',Date,Identifier);
  if CrashFlag
    ReportName = sprintf('%s_%s_report_%i',Date,Identifier,CopyIndex);
  end
  reportdata.filename = ReportName;
  reportdata.path = FullPath;
  
  %Add name and path of the original experimental data file(s)
  if  isfield(handles.Data,'AWG_Parameters')
    reportdata.OriginalFileName = sprintf('%i files',length(handles.FilePaths.Files));
  else
    reportdata.OriginalFileName = handles.FilePaths.Files;
  end
  reportdata.OriginalFilePath = handles.FilePaths.Path;
  
  %Get the location of the processing report logo
  HyscoreanPath = which('Hyscorean');
  HyscoreanPath = HyscoreanPath(1:end-11);
  reportdata.ProcessingReport_logo_Path = fullfile(HyscoreanPath,'bin','ProcessingReport_logo.png');
  
  %Send structure to workspace
  assignin('base', 'reportdata', reportdata);
  %Generate report
  report Hyscorean_report -fpdf ;
  %Remove structure from workspace
  evalin('base', 'clear reportdata');

else
  warning('MATLAB report generator not installed or license not found. Report generation was skipped.')
end

%Inform user of succesful completed step
set(handles.ProcessingInfo, 'String', 'Status: Saving session 80%'); drawnow;

%========================================================================== 
% Save data for Easyspin fitting
%==========================================================================  

try
%Collect necessary data for the fitting module
DataForFitting.Spectrum = handles.Processed.spectrum;
DataForFitting.TauValues = handles.Data.TauValues/1000; 
DataForFitting.TimeStep1 = handles.Data.TimeStep1;
DataForFitting.TimeStep2 = handles.Data.TimeStep2;
DataForFitting.FieldOffset = 0.1*str2double(get(handles.FieldOffset,'string')); %mT
DataForFitting.currentTaus = handles.currentTaus;
DataForFitting.Lorentz2GaussCheck = get(handles.Lorentz2GaussCheck,'Value');
DataForFitting.BackgroundStart1 = round(1000*BackgroundAxis(handles.Data.BackgroundStartIndex1),0);
DataForFitting.BackgroundStart2 = round(1000*BackgroundAxis(handles.Data.BackgroundStartIndex2),0);
if isfield(handles.Data,'BrukerParameters')
  DataForFitting.Field = 0.1*str2double(handles.Data.BrukerParameters.CenterField(1:6));
  DataForFitting.mwFreq = handles.Data.BrukerParameters.MWFQ/1e9;
  FirstPulseLength = str2double(Pulse90String)/1000;
elseif isfield(handles.Data,'AWG_Parameters')
  DataForFitting.Field =  0.1*handles.Data.AWG_Parameters.B;%mT
  DataForFitting.mwFreq = handles.Data.AWG_Parameters.LO + handles.Data.AWG_Parameters.nu_obs;
  FirstPulseLength = handles.Data.AWG_Parameters.events{1}.pulsedef.tp/1000;
end
DataForFitting.ExciteWidth = 1/FirstPulseLength;
DataForFitting.nPoints = length(handles.Data.PreProcessedSignal);
DataForFitting.ZeroFillFactor = length(handles.Processed.Signal)/length(handles.Data.PreProcessedSignal);
DataForFitting.FreqLim = str2double(get(handles.XUpperLimit,'string'));
DataForFitting.WindowType = handles.WindowTypeString;
DataForFitting.WindowLength1 = str2double(get(handles.WindowLength1,'string'));
DataForFitting.WindowLength2 = str2double(get(handles.WindowLength2,'string'));
DataForFitting.L2GParameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
DataForFitting.L2GParameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
DataForFitting.L2GParameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
DataForFitting.L2GParameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
DataForFitting.Symmetrization = handles.SymmetrizationString;

%Send settings structure to base workspace
assignin('base', 'DataForFitting', DataForFitting);

%Use the same formatting in name as before to avoid filename clash
SaveName = sprintf('%s_%s_DataForFitting.mat',Date,Identifier);
if CrashFlag
  SaveName = sprintf('%s_%s_DataForFitting_%i.mat',Date,Identifier,CopyIndex);
end

%Save data to file
save(fullfile(FullPath,SaveName),'DataForFitting');

%Remove structure from base workspace
evalin('base','clear DataForFitting');
catch
  warning('An error ocurred and the data for fitting could not be generated.')
end

%Inform user that saving is finished
 set(handles.ProcessingInfo, 'String', 'Status: Session saved'); drawnow;

 return
 