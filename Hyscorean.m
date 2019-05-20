function varargout = Hyscorean(varargin)
%==========================================================================
% HYSCOREAN (HYSCORE ANALYSIS) - GUI CALLBACKS 
%==========================================================================
% This function is responsible for the generation and execution of the
% fitting module of Hyscorean. This module employs EasySpin for fitting the
% spectra processed via Hyscorean. This function allows the fitting of
% several HYSCORE spectra at the same time e.g. at different field
% positions. The spectra are simulated via the saffron function and then
% processed by the same functions employed by Hyscorean during the
% processing. 
% (See the Hyscorean manual for further details) 
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%==========================================================================

%Check that the license has been accepted, otherwise kill the startup
if ispref('hyscorean','LGPL_license')
    if ~getpref('hyscorean','LGPL_license')
        w  = warndlg('Hyscorean''s GNU LGPL 3.0 license agreement not accepted. Please run setup_hyscorean again and accept the license agreemen.','Warning','modal');
        waitfor(w)
        return
    end
else
    w  = warndlg('Hyscorean''s GNU LGPL 3.0 license agreement not found. Please run setup_hyscorean again and accept the license agreemen.','Warning','modal');
    waitfor(w)
    return
end

GraphicalSettings = getpref('hyscorean','graphicalsettings');
if ~isfield(GraphicalSettings,'ColormapName')
  GraphicalSettings.ColormapName = 'parula';
  setpref('hyscorean','graphicalsettings',GraphicalSettings);
end
%GUIDE-specific startup code
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Hyscorean_OpeningFcn, ...
                   'gui_OutputFcn',  @Hyscorean_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%==========================================================================


%==========================================================================
function Hyscorean_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
%==========================================================================


%==========================================================================
function varargout = Hyscorean_OutputFcn(hObject, eventdata, handles) 

%Plot auxiliary lines on the main display
plot(handles.mainPlot,-50:1:50,abs(-50:1:50),'k-.'),grid(handles.mainPlot,'on')
hold(handles.mainPlot,'on')
plot(handles.mainPlot,zeros(length(0:50),1),abs(0:50),'k-')
hold(handles.mainPlot,'off')
set(handles.mainPlot,'xticklabel',[],'yticklabel',[])

%Load and set the Hyscorean logo
axes(handles.Icon)
Path =  fileparts(which('Hyscorean'));
[matlabImage,~,Alpha] = imread(fullfile(Path, 'bin', 'logo.png'));
image(matlabImage,'AlphaData',Alpha)
axis off
axis image
%Do not give the user acces to this handle
set(handles.Icon,'HandleVisibility','off')

%Get a dummy plot for the signal display
plot(handles.signal_t1,-50:1:50,abs(-50:0.5:0),'k-',-50:1:50,abs(0:0.5:50),'k-')
set(handles.signal_t1,'xticklabel',[],'yticklabel',[])

%Force rendering now
drawnow

varargout{1} = handles.output;
return
%==========================================================================

%==========================================================================
function resetPlots(handles)

%Reset main display plot as in the beginning
plot(handles.mainPlot,-50:1:50,abs(-50:1:50),'k-.'),grid(handles.mainPlot,'on')
hold(handles.mainPlot,'on')
plot(handles.mainPlot,zeros(length(0:50),1),abs(0:50),'k-')
hold(handles.mainPlot,'off')
set(handles.mainPlot,'xticklabel',[],'yticklabel',[])

%Reset signal plot as in the beginning
cla(handles.signal_t1,'reset')
set(handles.signal_t1,'xtick',[],'ytick',[])
hold(handles.mainPlot,'on')
plot(handles.signal_t1,-50:1:50,abs(-50:0.5:0),'k-',-50:1:50,abs(0:0.5:50),'k-')
set(handles.signal_t1,'xticklabel',[],'yticklabel',[])
return
%==========================================================================

%==========================================================================
function LoadButton_Callback(hObject, eventdata, handles)

%Inform the user that loading is under progress
set(handles.LoadedData, 'String', 'Loading...');drawnow;

%ASk the user to load the files via OS window
[handles.FileNames,handles.FilePaths,CancelFlag] = multiload_mod;

%If laoding canceled just break the function
if CancelFlag
  set(handles.LoadedData,'String','Loading canceled');drawnow;
  return;
else
  set(handles.DisplayLoadedFiles,'enable','on')
end

%If data has been reloaded and there exists and old processed spectrum,
%remove all the associated data
if isfield(handles,'Processed')
  handles = rmfield(handles,'Processed');
end

%Reset/Disable graphical handles so that no errors appear if called
set(handles.PreProcessedTrace,'visible','off')
set(handles.ImaginaryTrace,'visible','off')
set(handles.NonCorrectedTrace,'visible','off')
set(handles.PlotApodizationWindow,'visible','off')
set(handles.DetachSignalPlot,'visible','off')
set(handles.ChangeSignalPlotDimension,'visible','off')
set(handles.t1_Slider,'enable','off')
set(handles.ImposeBlindSpots,'enable','off')
set(handles.EasyspinFitButton,'enable','off')
set(handles.AddHelpLine,'enable','off')
set(handles.TransititonType,'enable','off')
set(handles.Validation_Button,'enable','off')
set(handles.AddTagList,'enable','off')
set(handles.ClearTags,'enable','off')
set(handles.FieldOffsetTag,'enable','off')
set(handles.ZoomButton,'visible','off')
set(handles.ZoomOutButton,'visible','off')
set(handles.ProcessButton,'enable','off')
set(handles.SaveReportButton,'enable','off')
set(handles.FieldOffset,'enable','off')
set(findall(handles.GraphicsPanel, '-property', 'enable'), 'enable', 'off')
set(handles.trace2Info,'string','')
handles.TauSelectionSwitch = true;
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
handles.MountDataSwitch  = true;
set(handles.TauSelectionCheck,'visible','off')
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
set(handles.TauSelectionWaiting,'visible','off')
set(handles.BackgroundCorrectionWaiting,'visible','off')
enableDisableGUI(handles,'NUSReconstruction','off')
drawnow

%Inform the user of how many files  have been loaded
set(handles.LoadedData, 'String', sprintf('%d File(s) Loaded',length(handles.FileNames)));drawnow;
%Reset all plots to its startup form and inform 
resetPlots(handles);

%Remove handles of auxiliary tags and lines if exist
if isfield(handles,'AddedLines')
  handles = rmfield(handles,'AddedLines');
 end
 if isfield(handles,'AddedTags')
   handles = rmfield(handles,'AddedTags');
 end

%Mount the data
try
  handles.Data = mountHYSCOREdata(handles.FileNames,handles);
catch Error
  %If something fails then inform the user and return
  f = errordlg(sprintf('Loading failed due to errors: \n\n %s ',Error.message),'Error','modal');
  set(handles.LoadedData, 'String', 'Loading failed');drawnow;
  set(handles.ProcessingInfo, 'String', 'Status: Loading failed');drawnow
  waitfor(f)
  return
end

%Get the tau values found during the mounting
TauValues = handles.Data.TauValues;

%Get all possible combinations
[handles.Selections,handles.Data.Combinations] = getTauCombinations(TauValues);

%Set the combination to the corresponding UI element
set(handles.MultiTauDimensions,'enable','on');
set(handles.MultiTauDimensions,'Value',1)
set(handles.MultiTauDimensions,'String',handles.Selections);

%Set the edit boxes depending on the signal size to the corresponding value
set(handles.ZeroFilling1,'String',size(handles.Data.TauSignals,2));
set(handles.ZeroFilling2,'String',size(handles.Data.TauSignals,3));
set(handles.WindowLength1,'String',size(handles.Data.TauSignals,2));
set(handles.WindowLength2,'String',size(handles.Data.TauSignals,3));

%Check if data is NUS and activate the panels in the GUI
if handles.Data.NUSflag
  enableDisableGUI(handles,'NUSReconstruction','on')
end

%Enable the process button and inform the user
set(handles.ProcessButton,'enable','on')
set(handles.ProcessingInfo, 'String', 'Status: Ready');drawnow

% Save the handles structure.
guidata(hObject,handles)

return
%==========================================================================

%==========================================================================
function ProcessButton_Callback(hObject, eventdata, handles)

%Check if data is loaded (should always be like that just in case)
if ~isfield(handles,'Data')
 set(handles.ProcessingInfo,'String','Error: No data loaded.')
 return
end

%Launch the HYSCORE processing and update the GUI with the results
try
set(handles.ProcessingInfo, 'String', 'Status: Processing...');drawnow;
[handles] = processHYSCORE(handles);
updateHyscoreanGUI(handles,handles.Processed)
catch Error  
  %Should some error occur inform the user and return
  w = errordlg(sprintf('The processing stopped due to an error : \n %s \n Please check your input. If this error persists restart the program.',Error.message),'Error','modal');
  waitfor(w);
  set(handles.ProcessingInfo,'String','Ready')
  return
end

%Enable the post-processing UI elements
set(handles.ImposeBlindSpots,'enable','on')
set(handles.AddHelpLine,'enable','on')
set(handles.TransititonType,'enable','on')
set(handles.AddTagList,'enable','on')
set(handles.ClearTags,'enable','on')
set(handles.FieldOffsetTag,'enable','on')
set(handles.FieldOffset,'enable','on')
set(handles.ZoomButton,'visible','on')
set(handles.ZoomOutButton,'visible','on')
set(handles.Validation_Button,'enable','on')
%Enable the Fitting module only if EasySpin is installed
if getpref('hyscorean','easyspin_installed')
set(handles.EasyspinFitButton,'enable','on')
end
set(findall(handles.GraphicsPanel, '-property', 'enable'), 'enable', 'on')
set(handles.SaveReportButton,'enable','on')

guidata(hObject, handles)
return
%==========================================================================

%==========================================================================
function t1_Slider_Callback(hObject, eventdata, handles)
handles.slider_t1=get(hObject,'Value');
Processed = handles.Processed;
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,Processed)
guidata(hObject,handles)
return
%==========================================================================

%==========================================================================
function SaveReportButton_Callback(hObject, eventdata, handles)

%If there is data to be saved then launch the save and report protocol
if ~isfield(handles,'Processed')
  Window = warndlg('There is no processed data to be saved','Warning');
  return
end
saveHyscorean(handles);
return
%==========================================================================

%==========================================================================
function DisplayLoadedFiles_Callback(hObject, eventdata, handles)

%Display a list with all loaded files in the program
try
  [handles.FileNames,handles.FilePaths,CancelFlag] = listLoadedFiles(handles.FileNames,handles.FilePaths);
  if CancelFlag
    %If data has been reloaded and there exists and old processed spectrum, remove all the associated data
    if isfield(handles,'Processed')
      handles = rmfield(handles,'Processed');
    end
    %Reset/Disable graphical handles so that no errors appear if called
    set(handles.PreProcessedTrace,'visible','off')
    set(handles.NonCorrectedTrace,'visible','off')
    set(handles.PlotApodizationWindow,'visible','off')
    set(handles.DetachSignalPlot,'visible','off')
    set(handles.ChangeSignalPlotDimension,'visible','off')
    set(handles.t1_Slider,'enable','off')
    set(handles.ImposeBlindSpots,'enable','off')
    set(handles.AddHelpLine,'enable','off')
    set(handles.TransititonType,'enable','off')
    set(handles.AddTagList,'enable','off')
    set(handles.ClearTags,'enable','off')
    set(handles.FieldOffsetTag,'enable','off')
    set(handles.FieldOffset,'enable','off')
    set(findall(handles.GraphicsPanel, '-property', 'enable'), 'enable', 'off')
    set(handles.trace2Info,'string','')
    handles.TauSelectionSwitch = true;
    handles.backgroundCorrectionSwitch = true;
    handles.ReconstructionSwitch  = true;
    handles.MountDataSwitch  = true;
    set(handles.TauSelectionCheck,'visible','off')
    set(handles.BackgroundCorrectionCheck,'visible','off')
    set(handles.ReconstructionCheck,'visible','off')
    set(handles.TauSelectionWaiting,'visible','off')
    set(handles.BackgroundCorrectionWaiting,'visible','off')
    enableDisableGUI(handles,'NUSReconstruction','off')
    
    %Reset maind and signal plots to its startup state
    resetPlots(handles);
    
    %Force rendering of the GUI
    drawnow
    
    %Inform the user of the remaining files
    set(handles.LoadedData, 'String', sprintf('%d File(s) Loaded',length(handles.FileNames)));drawnow;
    
    %Mount data again and get tau values
    handles.Data = mountHYSCOREdata(handles.FileNames,handles);
    TauValues = handles.Data.TauValues;
    
    %Get again combinations and set the corresponding UI element values
    [handles.Selections,handles.Data.Combinations] = getTauCombinations(TauValues);
    set(handles.MultiTauDimensions,'enable','on');
    set(handles.MultiTauDimensions,'String',handles.Selections);
    set(handles.ZeroFilling1,'String',2*size(handles.Data.TauSignals,2));
    set(handles.ZeroFilling2,'String',2*size(handles.Data.TauSignals,3));
    set(handles.WindowLength1,'String',size(handles.Data.TauSignals,2));
    set(handles.WindowLength2,'String',size(handles.Data.TauSignals,3));
    
    %Inform the user and return
    set(handles.ProcessingInfo, 'String', 'Status: Ready'); drawnow;
   
  end
catch
end
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function SaveSettingsButton_Callback(hObject, eventdata, handles)
saveSettings(handles)
return
%==========================================================================

%==========================================================================
function LoadSettings_Callback(hObject, eventdata, handles)
handles = loadSettingsHyscorean(handles);
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function NonCorrectedTrace_Callback(hObject, eventdata, handles)
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function PreProcessedTrace_Callback(hObject, eventdata, handles)
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function SaverSettings_Callback(hObject, eventdata, handles)
setappdata(0,'SaverSettings',handles.SaveHyscoreanSettings)
%Make the window appear relative to the Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
Position(3) = 451.0;
Position(4) = 177.0;
%Call graphical settings GUI
Hyscorean_saveSettings('Position',Position)
uiwait(Hyscorean_saveSettings)
handles.SaveHyscoreanSettings = getappdata(0,'SaverSettings');
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function XUpperLimit_Callback(hObject, eventdata, handles)
updateHyscoreanGUI(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function InvertCorrection_Callback(hObject, eventdata, handles)
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BackgroundMethod1_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
  case 1
    set(handles.BackgroundParameterText1,'String','')
    set(handles.BackgroundParameter1,'enable','off')
  case 2
    set(handles.BackgroundParameterText1,'String','Fractal Dimension')
    set(handles.BackgroundParameter1,'enable','on')
    set(handles.BackgroundParameter1,'String','1')
  case 3
    set(handles.BackgroundParameterText1,'String','Polynomial Order')
    set(handles.BackgroundParameter1,'String','1')
    set(handles.BackgroundParameter1,'enable','on')
  case 4
    set(handles.BackgroundParameterText1,'String','Exponential Order')
    set(handles.BackgroundParameter1,'enable','on')
    set(handles.BackgroundParameter1,'String','1')
end
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BackgroundMethod2_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
  case 1
    set(handles.BackgroundParameterText2,'String','')
    set(handles.BackgroundParameter2,'enable','off')
  case 2
    set(handles.BackgroundParameterText2,'String','Fractal Dimension')
    set(handles.BackgroundParameter2,'enable','on')
    set(handles.BackgroundParameter2,'String','1')
  case 3
    set(handles.BackgroundParameterText2,'String','Polynomial Order')
    set(handles.BackgroundParameter2,'String','1')
    set(handles.BackgroundParameter2,'enable','on')
  case 4
    set(handles.BackgroundParameterText2,'String','Exponential Order')
    set(handles.BackgroundParameter2,'enable','on')
    set(handles.BackgroundParameter2,'String','1')
end
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BackgroundParameter1_Callback(hObject, eventdata, handles)
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BackgroundParameter2_Callback(hObject, eventdata, handles)
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function ReconstructionAlgorithm_Callback(hObject, eventdata, handles)
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
    switch get(hObject,'Value')
      case 1
        set(handles.MaxEntLagrangianMultiplier,'enable','on')
        set(handles.LagrangeMultiplierText,'enable','on')
        set(handles.BackgroundParameterText,'enable','on')
        set(handles.MaxEntBackgroundParameter,'enable','on')
      case {2,3,4}
        set(handles.MaxEntLagrangianMultiplier,'enable','off')
        set(handles.LagrangeMultiplierText,'enable','off')
        set(handles.BackgroundParameterText,'enable','on')
        set(handles.MaxEntBackgroundParameter,'enable','on')
      otherwise
        set(handles.MaxEntLagrangianMultiplier,'enable','off')
        set(handles.LagrangeMultiplierText,'enable','off')
        set(handles.BackgroundParameterText,'enable','off')
        set(handles.MaxEntBackgroundParameter,'enable','off')
    end
guidata(hObject, handles);
return 
%==========================================================================

%==========================================================================
function MaxEntBackgroundParameter_Callback(hObject, eventdata, handles)
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function MaxEntLagrangianMultiplier_Callback(hObject, eventdata, handles)
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function plotNUSgrid_Callback(hObject, eventdata, handles)
displayNUSreconstructionResults(handles)
return
%==========================================================================

%==========================================================================
function detachMainContour_Callback(hObject, eventdata, handles)
%Find figure, close it and open it again
Figure = findobj('Tag','mainContourDetached');
if isempty(Figure)
  Figure = figure('Tag','mainContourDetached','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
%Make the window appear relative to the Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
%Copy object as it is
AxesHandles = copyobj(handles.mainPlot,Figure);
GraphicalSettings = getpref('hyscorean','graphicalsettings');
set(Figure,'NumberTitle','off','Name','Hyscorean: HYSCORE Spectrum','Units','pixels','Position',[Position(1) Position(2) 776 415]);
set(AxesHandles,'Position',[0.07 0.12 0.9 0.85]);
colormap(AxesHandles,GraphicalSettings.ColormapName)

%If the blindspots are being superimposed then switch to the hot colormap
if get(handles.ImposeBlindSpots,'value')
  colormap(AxesHandles,'hot')
end

return
%==========================================================================

%==========================================================================
function detachMainSurface_Callback(hObject, eventdata, handles)
%Find figure, close it and open it again
Figure = findobj('Tag','mainSurfaceDetached');
if isempty(Figure)
  Figure = figure('Tag','mainSurfaceDetached','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
%Make the window appear relative to the Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
set(Figure,'NumberTitle','off','Name','Hyscorean: HYSCORE Surface','Units','pixels','Position',[Position(1) Position(2) 776 415]);
if handles.GraphicalSettings.Absolute
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Real
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Imaginary
  spectrum2 = imag(handles.Processed.spectrum);
end
surf(handles.Processed.axis1,handles.Processed.axis2,spectrum2)
colormap(handles.GraphicalSettings.ColormapName)
shading('flat'),colorbar
XupperLimit = str2double(get(handles.XUpperLimit,'string'));
xlim([-XupperLimit XupperLimit]),ylim([0 XupperLimit])
xlabel('\nu_1 [MHz]'), ylabel('\nu_2 [MHz]')
return
%==========================================================================

%==========================================================================
function DetachProjectionPlot_Callback(hObject, eventdata, handles)
%Find figure, close it and open it again
Figure = findobj('Tag','mainProjectionDetached');
if isempty(Figure)
  Figure = figure('Tag','mainProjectionDetached','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
%Make the window appear relative to the Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
options.figsize = [500 500 790 450];
set(Figure,'NumberTitle','off','Name','Hyscorean: Projection Contour','Units','pixels','Position',options.figsize);
  XUpperLimit=str2double(get(handles.XUpperLimit,'string'));
  options.xaxs = [-XUpperLimit XUpperLimit]; options.yaxs = [0 XUpperLimit];
  options.xlabel = '\nu_1 [MHz]'; options.ylabel = '\nu_2 [MHz]';
options.levels=handles.GraphicalSettings.Levels;
options.Linewidth=handles.GraphicalSettings.LineWidth;
options.nonewfig = true;
options.MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
options.MaximalContourLevel = str2double(get(handles.MaximalContourLevel,'string'));

colormap(handles.GraphicalSettings.ColormapName)
if handles.GraphicalSettings.Absolute
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Real
  spectrum2 = real(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Imaginary
  spectrum2 = imag(handles.Processed.spectrum);
end
Hyscore_correlation_plot(handles.Processed.axis2,handles.Processed.axis1,spectrum2,options)
return
%==========================================================================

%==========================================================================
function GraphicalSettingsButton_Callback(hObject, eventdata, handles)

setappdata(0,'GraphicalSettings',handles.GraphicalSettings)
%Make the window appear relative to the Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
Position(3) = 451.0;
Position(4) = 177.0;
%Call graphical settings GUI
Hyscorean_GraphicalSettings('Position',Position)
uiwait(Hyscorean_GraphicalSettings)

handles.GraphicalSettings = getappdata(0,'GraphicalSettings');

switch handles.GraphicalSettings.Colormap
  case 1
    handles.GraphicalSettings.ColormapName = 'parula';
  case 2
    handles.GraphicalSettings.ColormapName = 'jet';
  case 3
    handles.GraphicalSettings.ColormapName = 'hsv';
  case 4
    handles.GraphicalSettings.ColormapName = 'hot';
  case 5
    handles.GraphicalSettings.ColormapName = 'cool';
  case 6
    handles.GraphicalSettings.ColormapName = 'spring';
  case 7
    handles.GraphicalSettings.ColormapName = 'summer';
  case 8
    handles.GraphicalSettings.ColormapName = 'autumn';
  case 9
    handles.GraphicalSettings.ColormapName = 'winter';
  case 10
    handles.GraphicalSettings.ColormapName = 'gray';
end

set(handles.ProcessingInfo, 'String', 'Status: Rendering...');drawnow;
try
updateHyscoreanGUI(handles,handles.Processed)
catch
end
set(handles.ProcessingInfo, 'String', 'Status: Finished');drawnow;

guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function MultiTauDimensions_Callback(hObject, eventdata, handles)
handles.TauSelectionSwitch = true;
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch = true;
  set(handles.TauSelectionCheck,'visible','off')
  set(handles.BackgroundCorrectionCheck,'visible','off')
  set(handles.ReconstructionCheck,'visible','off')
  set(handles.Validation_Button,'enable','off')
guidata(hObject,handles)
return
%==========================================================================

%==========================================================================
function GraphicalSettingsButton_CreateFcn(hObject, eventdata, handles)
handles.GraphicalSettings = getpref('hyscorean','graphicalsettings');
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function ImposeBlindSpots_Callback(hObject, eventdata, handles)
updateHyscoreanGUI(handles,handles.Processed);
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function AddHelpLine_Callback(hObject, eventdata, handles)
%Get gyromagnetic ratio from selected nuclei
gyromagneticRatio = getgyro_Hyscorean(get(handles.AddTagList,'Value'));
%Get center field in gauss
try
  if isfield(handles.Data,'BrukerParameters')
    CenterField = handles.Data.BrukerParameters.CenterField;
    %Remove units character and convert to double
    CenterField = str2double(CenterField(1:end-2));
  elseif isfield(handles.Data,'AWG_Parameters')
    CenterField = handles.Data.AWG_Parameters.B;
  end
  
catch
  errordlg('The experimental parameters could not be extracted from the loaded file.','File Error');
end
%convert to tesla
CenterField = CenterField*1e-4;
%Get field offset
Offset = get(handles.FieldOffset,'string');
Offset = str2double(Offset)*1e-4;

%Get type of transition and corresponding multiplier
FrequencyMultiplier = handles.FrequencyMultiplier;
%get Larmor frequency in MHz
Larmorfrequency = FrequencyMultiplier*gyromagneticRatio*(CenterField + Offset);
X = Larmorfrequency;
Y = abs(Larmorfrequency);

  Xaxis = handles.Processed.axis1;
if X>0 
  Xaxis = Xaxis(Xaxis>0);
  Slope = -1;
else
    Xaxis = Xaxis(Xaxis>0);
    Slope = -1;
end

switch FrequencyMultiplier
  case 1
    color = 'k';
  case 2
    color = 'r';
  case 4
    color = 'b';
end
Yaxis =  Y + Slope*(Xaxis - abs(X));
hold(handles.mainPlot,'on')
LineHandle = plot(handles.mainPlot,Xaxis,Yaxis,'-.','LineWidth',1.5,'Color',color);
hold(handles.mainPlot,'off')
if isfield(handles,'AddedLines')
size = length(handles.AddedLines);
else
  size = 0;
end
handles.AddedLines{size +1}.x = Xaxis;
handles.AddedLines{size +1}.y = Yaxis;
handles.AddedLines{size +1}.handle = LineHandle;
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function TransititonType_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
  case 1
    FrequencyMultiplier = 1;
  case 2
    FrequencyMultiplier = 2;
  case 3
    FrequencyMultiplier = 4;
end
handles.FrequencyMultiplier = FrequencyMultiplier;
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function TransititonType_CreateFcn(hObject, eventdata, handles)
handles.FrequencyMultiplier = 1;
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function AddTagList_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end
Names = get(hObject,'string');
Colors = white(length(Names))-1;
for i=1:length(Names)
  
  Position1 = strfind(Names{i},'<SUP>');
  Position2 = strfind(Names{i},'</SUP>');
  Position3 = strfind(Names{i},'</FONT>');
  
  IsotopeTags(i).isotope = Names{i}(Position1+length('<SUP>'):Position2-1);
  IsotopeTags(i).name = Names{i}(Position2+length('</SUP>'):Position3-1);
  IsotopeTags(i).Color =  uint8(Colors(i,:) * 255 + 0.5);
end

ListBoxStrings = cell(numel( IsotopeTags ),1);
for i = 1:numel( IsotopeTags )
  String = ['<HTML><FONT color=' reshape( dec2hex( IsotopeTags(i).Color,2 )',1, 6) '></FONT><SUP>' IsotopeTags(i).isotope '</SUP>' IsotopeTags(i).name '</HTML>'];
  ListBoxStrings{i} = String;
end
handles.IsotopeTags = IsotopeTags;
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function SaverSettings_CreateFcn(hObject, eventdata, handles)
handles.SaveHyscoreanSettings.IdentifierName = 'Hyscorean_save';
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function ClearTags_Callback(hObject, eventdata, handles)
try
  for i=1:length(handles.AddedLines)
  delete(handles.AddedLines{i}.handle)
  end
  handles = rmfield(handles,'AddedLines');
catch 
end
try
  for i=1:length(handles.AddedTags)
  delete(handles.AddedTags{i}.handle)
  end
handles = rmfield(handles,'AddedTags');
catch 
end
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function Lorentz2GaussCheck_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
      enableDisableGUI(handles,'Lorent2Gauss','on')
else
      enableDisableGUI(handles,'Lorent2Gauss','off')
end
return
%==========================================================================

%==========================================================================
function PlotApodizationWindow_Callback(hObject, eventdata, handles)
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function ChangeSignalPlotDimension_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function DetachSignalPlot_Callback(hObject, eventdata, handles)
setappdata(0,'Processed',handles.Processed)
setappdata(0,'Data',handles.Data)
setappdata(0,'InvertCorrection',get(handles.InvertCorrection,'value'))
setappdata(0,'ZeroFilling1',str2double(get(handles.ZeroFilling1,'String')))
setappdata(0,'ZeroFilling2',str2double(get(handles.ZeroFilling2,'String')))
setappdata(0,'WindowLength1',get(handles.WindowLength1,'String'))
setappdata(0,'WindowLength2',get(handles.WindowLength2,'String'))
setappdata(0,'WindowType',get(handles.WindowType,'Value'))

%Call graphical settings GUI
handles.SignalPlotIsDetached = true;
guidata(hObject, handles);

uiwait(Hyscorean_detachedSignalPlot)

handles.SignalPlotIsDetached = false;
guidata(hObject, handles);

return
%==========================================================================

%==========================================================================
function MinimalContourLevel_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String')) < 0
  set(hObject,'String',0)
end
if str2double(get(hObject,'String')) >= str2double(get(handles.MaximalContourLevel,'String'))
  set(hObject,'String',str2double(get(handles.MaximalContourLevel,'String'))-0.5)
end
updateHyscoreanGUI(handles,handles.Processed)  
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function MaximalContourLevel_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String')) > 100
  set(hObject,'String',100)
end
if str2double(get(hObject,'String')) <= str2double(get(handles.MinimalContourLevel,'String'))
  set(hObject,'String',str2double(get(handles.MinimalContourLevel,'String'))+0.5)
end
updateHyscoreanGUI(handles,handles.Processed)  
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function FieldOffset_ButtonDownFcn(hObject, eventdata, handles)
set(hObject,'string','');
return
%==========================================================================

%==========================================================================
function BackgroundStart1_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String'))<1
   set(hObject,'string',1)
end
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BackgroundStart2_Callback(hObject, eventdata, handles)
if str2double(get(hObject,'String'))<1
   set(hObject,'string',1)
end
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function WindowType_Callback(hObject, eventdata, handles)
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
    case 8
      WindowType = 'tukey25';
    case 9
      WindowType = 'tukey50';
    case 10
      WindowType = 'tukey75';
    case 11
      WindowType = 'hann';
    case 12
      WindowType = 'none';  
  end
  if WindowMenuState == 12
    set(handles.WindowLength1,'enable','off')
    set(handles.WindowLength2,'enable','off')
    set(handles.WindowLengthText1,'enable','off')
    set(handles.WindowLengthText2,'enable','off')
  else
    set(handles.WindowLength1,'enable','on')
    set(handles.WindowLength2,'enable','on')
    set(handles.WindowLengthText1,'enable','on')
    set(handles.WindowLengthText2,'enable','on')
  end
handles.WindowTypeString = WindowType;
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function WindowType_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.WindowTypeString = 'chebyshev';
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function BlindSpotsSimulator_Callback(hObject, eventdata, handles)
Blindspot_simulator(handles.Processed.axis1,handles.Processed.axis2,handles.Processed.spectrum,str2double(get(handles.XUpperLimit,'string')))
return
%==========================================================================

%==========================================================================
function EasyspinFitButton_Callback(hObject, eventdata, handles)

%Fill known experimental parameters
Exp.Sequence = 'HYSCORE';
if isfield(handles.Data,'BrukerParameters')
  BrukerParameters = handles.Data.BrukerParameters;
  if ~isfield(BrukerParameters,'PlsSPELGlbTxt')
    errordlg('Descriptor file is incomplete or corrupted. Cannot initialize the fitting module.','Desciptor fields missing','modal');
    return
  end
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
  Exp.Field = 0.1*str2double(handles.Data.BrukerParameters.CenterField(1:6)); %mT
  Exp.mwFreq = handles.Data.BrukerParameters.MWFQ/1e9;
  FirstPulseLength = str2double(Pulse90String)/1000;
elseif isfield(handles.Data,'AWG_Parameters')
  Exp.Field =  0.1*handles.Data.AWG_Parameters.B;
  Exp.mwFreq = handles.Data.AWG_Parameters.LO + handles.Data.AWG_Parameters.nu_obs;
  FirstPulseLength = handles.Data.AWG_Parameters.events{1}.pulsedef.tp/1000;
end
%Set the excitation bandwidth [GHz] to the inverse of the first pulse employed
Exp.ExciteWidth = 1/FirstPulseLength;
%Compute the corrected magnetic field [mT]
Offset = str2double(get(handles.FieldOffset,'string'));
Exp.Field = Exp.Field + 0.1*Offset;
Exp.tau = handles.Data.TauValues/1000;
Exp.dt = handles.Data.TimeStep1;
Exp.nPoints = length(handles.Data.PreProcessedSignal);

%Fill known processing parameters
if ~iscell(handles.FilePaths.Path)
  Opt.FileNames = {handles.FilePaths.Files};
else
  Opt.FileNames = handles.FilePaths.Files;
end
if ~iscell(handles.FilePaths.Files)
  Opt.FilePaths = {handles.FilePaths.Path};
else
  Opt.FilePaths = handles.FilePaths.Path;
end
Opt.nKnots = 181;
Opt.ZeroFillFactor = length(handles.Processed.Signal)/length(handles.Data.PreProcessedSignal);
Opt.FreqLim = str2double(get(handles.XUpperLimit,'string'));
Opt.WindowType = handles.WindowTypeString;
Opt.WindowDecay1 = str2double(get(handles.WindowLength1,'string'));
Opt.WindowDecay2 = str2double(get(handles.WindowLength2,'string'));
Opt.L2GParameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
Opt.L2GParameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
Opt.L2GParameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
Opt.L2GParameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
Opt.Lorentz2GaussCheck = get(handles.Lorentz2GaussCheck,'value');
Opt.Symmetrization = handles.SymmetrizationString;
Opt.TimeStepFactor = 1;
%Launch the fitting module
esfit_hyscorean('saffron',abs(handles.Processed.spectrum),[],[],Exp,Opt)

return
%==========================================================================

%==========================================================================
function ZoomButton_Callback(hObject, eventdata, handles)
zoom
return
%==========================================================================

%==========================================================================
function ZoomOutButton_Callback(hObject, eventdata, handles)
zoom off
Upperlimit = str2double(get(handles.XUpperLimit,'string'));
set(handles.mainPlot,'xlim',[-Upperlimit Upperlimit],'ylim',[0 Upperlimit])
return
%==========================================================================

%==========================================================================
function Validation_Button_Callback(hObject, eventdata, handles)

%Get the signal before the pre-processing
RawData.Signal = handles.Data.Integral;
RawData.TimeAxis1 = handles.Data.TimeAxis1;
RawData.TimeAxis2 = handles.Data.TimeAxis2;
RawData.NUSflag = handles.Data.NUSflag;
%Check if NUS reconstruction is needed
  switch get(handles.ReconstructionAlgorithm,'Value')
    case 1 %Constant-lambda CAMERA Reconstruction
      ReconstructionMethod = 'constantcamera';
    case 2 %CAMERA
      ReconstructionMethod = 'camera';
    case 3 %FFM-CG
      ReconstructionMethod = 'ffmcg';
    case 4 %FFM-GD
      ReconstructionMethod = 'ffmgd';
    case 5 %IST-S Reconstruction
      ReconstructionMethod = 'ists';
    case 6 %IST-D Reconstruction
      ReconstructionMethod = 'istd';
  end
if RawData.NUSflag
  RawData.NUSgrid = handles.Data.NUSgrid;
  RawData.NUS = handles.Data.NUS;
end

%Get the current pre-processing settings
Defaults.InvertCorrection = get(handles.InvertCorrection,'value');
Defaults.BackgroundDimension1 = str2double(get(handles.BackgroundParameter1,'string'));
Defaults.BackgroundDimension2 = str2double(get(handles.BackgroundParameter2,'string'));
Defaults.BackgroundMethod1 = get(handles.BackgroundMethod1,'value') - 1;
Defaults.BackgroundMethod2 = get(handles.BackgroundMethod2,'value') - 1;
Defaults.BackgroundStart1 = str2double(get(handles.BackgroundStart1,'string'));
Defaults.BackgroundStart2 = str2double(get(handles.BackgroundStart2,'string'));
Defaults.BackgroundParameter = str2double(get(handles.MaxEntBackgroundParameter,'string'));
Defaults.LagrangeMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));
Defaults.ThresholdParameter = 0.98;
Defaults.ReconstructionMethod = ReconstructionMethod;

%Get the current processing settings
Defaults.ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
Defaults.ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
Defaults.WindowType = handles.WindowTypeString;
Defaults.WindowDecay1 = str2double(get(handles.WindowLength1,'string'));
Defaults.WindowDecay2 = str2double(get(handles.WindowLength2,'string'));
Defaults.SymmetrizationString = handles.SymmetrizationString;
Parameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
Parameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
Parameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
Parameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
Defaults.L2GParameters = Parameters;
Defaults.L2GCheck = get(handles.Lorentz2GaussCheck,'Value');

Defaults.MaximalContourLevel = str2double(get(handles.MaximalContourLevel,'string'));
Defaults.MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
Defaults.XUpperLimit = str2double(get(handles.XUpperLimit,'string'));
GraphicalSetttings = getpref('hyscorean','graphicalsettings');
Defaults.Levels = GraphicalSetttings.Levels;
%Launch the validation module
Hyscorean_validationModule(RawData,Defaults)

return
%==========================================================================

%==========================================================================
function CopyrightText_ButtonDownFcn(hObject, eventdata, handles)
%Find figure, close it and open it again
Figure = findobj('Tag','LicenseFigure');
if isempty(Figure)
  Figure = figure('Tag','LicenseFigure','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
%Center the new window at Hyscorean window
Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)+500;
Position(2) = Position(2)+60;
screensize = get(0,'ScreenSize'); %Get screensize
set(Figure,'NumberTitle','off','Name','Hyscorean: License','menu','none','toolbar','none',...
  'units','pixels','Position',[Position(1) Position(2) 0.3*screensize(3) 0.65*screensize(4)]);

%Get the license
Path = fileparts(which('Hyscorean'));
fid = fopen(fullfile(Path,'LICENSE.LGPL.txt'));

%Generate UI elements to scroll the license
ph = uipanel(Figure,'Units','normalized','position',[0.01 0.01 0.99 0.99],'title',...
  'License Agreement');
lbh = uicontrol(ph,'style','listbox','Units','normalized','position',...
  [0 0 1 1],'FontSize',9);

%Read the license and print to UI element
indic = 1;
while 1
  tline = fgetl(fid);
  if ~ischar(tline)
    break
  end
  strings{indic}=tline;
  indic = indic + 1;
end
fclose(fid);
set(lbh,'string',strings);
set(lbh,'Value',1);
set(lbh,'Selected','on');
return
%==========================================================================

%==========================================================================
function Symmetrization_ListBox_Callback(hObject, eventdata, handles)
switch get(hObject,'Value')
  case 1
    handles.SymmetrizationString = 'None';
  case 2
    handles.SymmetrizationString = 'Diagonal';
  case 3
    handles.SymmetrizationString = 'Anti-Diagonal';
  case 4
    handles.SymmetrizationString = 'Both';
end
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function Symmetrization_ListBox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
  set(hObject,'BackgroundColor','white');
end
handles.SymmetrizationString = 'None';
guidata(hObject, handles);
return
%==========================================================================

%==========================================================================
function ImaginaryTrace_Callback(hObject, eventdata, handles)

if get(hObject,'value')
  handles.PlotImaginarySignal = true;
else
  handles.PlotImaginarySignal = false;
end
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
return
%==========================================================================


%==========================================================================
function Help_Button_Callback(hObject, eventdata, handles)
%Get the location of the html doc
Path = fileparts(which('Hyscorean'));
Path = fullfile(Path,'doc','html');
web(fullfile(Path,'index.html'),'-browser')
%==========================================================================
