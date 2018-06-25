function varargout = Hyscorean(varargin)
% HYSCOREAN MATLAB code for Hyscorean.fig
%      HYSCOREAN, by itself, creates a new HYSCOREAN or raises the existing
%      singleton*.
%
%      H = HYSCOREAN returns the handle to a new HYSCOREAN or the handle to
%      the existing singleton*.
%
%      HYSCOREAN('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HYSCOREAN.M with the given input arguments.
%
%      HYSCOREAN('Property','Value',...) creates a new HYSCOREAN or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Hyscorean_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Hyscorean_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Hyscorean

% Last Modified by GUIDE v2.5 12-Jun-2018 10:41:07

% Begin initialization code - DO NOT EDIT
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
% End initialization code - DO NOT EDIT


% --- Executes just before Hyscorean is made visible.
function Hyscorean_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Hyscorean (see VARARGIN)

% Choose default command line output for Hyscorean
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Hyscorean wait for user response (see UIRESUME)
% uiwait(handles.HyscoreanFigure);


% --- Outputs from this function are returned to the command line.
function varargout = Hyscorean_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
plot(handles.mainPlot,-50:1:50,abs(-50:1:50),'k-.'),grid(handles.mainPlot,'on')
hold(handles.mainPlot,'on')
plot(handles.mainPlot,zeros(length(0:50),1),abs(0:50),'k-')
hold(handles.mainPlot,'off')
set(handles.mainPlot,'xticklabel',[],'yticklabel',[])

varargout{1} = handles.output;


function resetPlots(handles)
plot(handles.mainPlot,-50:1:50,abs(-50:1:50),'k-.'),grid(handles.mainPlot,'on')
hold(handles.mainPlot,'on')
plot(handles.mainPlot,zeros(length(0:50),1),abs(0:50),'k-')
hold(handles.mainPlot,'off')
set(handles.mainPlot,'xticklabel',[],'yticklabel',[])
cla(handles.signal_t1,'reset')
set(handles.signal_t1,'xtick',[],'ytick',[])


% --- Executes on button press in LoadButton.
function LoadButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.LoadedData, 'String', 'Loading...');drawnow;

[handles.FileNames,handles.FilePaths] = multiload_mod;
if handles.FilePaths.Files == 0
  set(handles.LoadedData,'String','Loading canceled');drawnow;
  return;
end

set(handles.DisplayLoadedFiles,'enable','on')


handles.TauSelectionSwitch = true;
handles.backgroundCorrectionSwitch = true;
handles.ReconstructionSwitch  = true;
handles.MountDataSwitch  = true;

   set(handles.TauSelectionCheck,'visible','off')
   set(handles.BackgroundCorrectionCheck,'visible','off')
   set(handles.ReconstructionCheck,'visible','off')
   set(handles.TauSelectionWaiting,'visible','off')
   set(handles.BackgroundCorrectionWaiting,'visible','off')
      drawnow
      
if isempty(handles.FileNames)
  set(handles.LoadedData, 'String', 'Loading canceled');drawnow;
else
  set(handles.LoadedData, 'String', sprintf('%d File(s) Loaded',length(handles.FileNames)));drawnow;
  resetPlots(handles);
  enableDisableGUI(handles,'NUSReconstruction','off')
end

handles.Data = mountHYSCOREdata(handles.FileNames);
TauValues = handles.Data.TauValues;

[handles.Selections,handles.Data.Combinations] = getTauCombinations(TauValues);

 set(handles.MultiTauDimensions,'enable','on');

 set(handles.MultiTauDimensions,'String',handles.Selections);
 set(handles.ZeroFilling1,'String',2*size(handles.Data.TauSignals,2));
 set(handles.ZeroFilling2,'String',2*size(handles.Data.TauSignals,2));
 set(handles.Hammingedit,'String',size(handles.Data.TauSignals,2));

  %Check if data is NUS and activate the panels in the GUI
  if handles.Data.NUSflag
    enableDisableGUI(handles,'NUSReconstruction','on')
  end
 
% Save the handles structure.
guidata(hObject,handles)

% --- Executes on button press in ProcessButton.
function ProcessButton_Callback(hObject, eventdata, handles)
% hObject    handle to ProcessButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,'Data')
 set(handles.ProcessingInfo,'String','Error: No data loaded.')
 return
end
% set(hObject,'enable','inactive')
set(handles.ProcessingInfo, 'String', 'Status: Processing...');drawnow;
[handles] = processHYSCORE(handles);
updateHyscoreanGUI(handles,handles.Processed)

set(handles.ImposeBlindSpots,'enable','on')
set(handles.AddHelpLine,'enable','on')
set(handles.AddTag,'enable','on')
set(handles.AddTagList,'enable','on')
set(handles.ClearTags,'enable','on')
set(handles.FieldOffsetTag,'enable','on')
set(handles.FieldOffset,'enable','on')
set(findall(handles.GraphicsPanel, '-property', 'enable'), 'enable', 'on')
% set(hObject,'enable','on')

guidata(hObject, handles)

% --- Executes on slider movement.
function t2_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to t2_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.slider_t2=get(hObject,'Value');
Processed = handles.Processed;
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,Processed)
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function t2_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t2_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
handles.PlotProcessedSignal = true;
guidata(hObject,handles)


% --- Executes on slider movement.
function t1_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to t1_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.slider_t1=get(hObject,'Value');
Processed = handles.Processed;
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,Processed)
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function t1_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t1_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in SaveReportButton.
function SaveReportButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveReportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
saveHyscorean(handles);


% --- Executes on button press in DisplayLoadedFiles.
function DisplayLoadedFiles_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayLoadedFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
  [handles.FileNames,handles.FilePaths] = listLoadedFiles(handles.FileNames,handles.FilePaths);
  set(handles.LoadedData, 'String', sprintf('%d File(s) Loaded',length(handles.FileNames)));drawnow;
  handles.EchoIntegrationSwitch = true;
  guidata(hObject, handles);
catch
  return
end

% --- Executes on button press in pushbutton22.
function pushbutton22_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in LoadSettings.
function LoadSettings_Callback(hObject, eventdata, handles)
% hObject    handle to LoadSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
loadSettingsHyscorean(handles)
guidata(hObject, handles);


% --- Executes on button press in NonCorrectedTrace.
function NonCorrectedTrace_Callback(hObject, eventdata, handles)
% hObject    handle to NonCorrectedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NonCorrectedTrace
handles.PlotProcessedSignal = true;
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);


% --- Executes on button press in PreProcessedTrace.
function PreProcessedTrace_Callback(hObject, eventdata, handles)
% hObject    handle to PreProcessedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PreProcessedTrace
handles.PlotProcessedSignal = true;

HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes on button press in SaverSettings.
function SaverSettings_Callback(hObject, eventdata, handles)
% hObject    handle to SaverSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0,'SaverSettings',handles.SaveHyscoreanSettings)

Position = handles.HyscoreanFigure.Position;
Position(1) = Position(1)-40;
Position(2) = Position(2)+60;
Position(3) = 451.0;
Position(4) = 177.0;
%Call graphical settings GUI
Hyscorean_saveSettings('Position',Position)
uiwait(Hyscorean_saveSettings)

handles.SaveHyscoreanSettings = getappdata(0,'SaverSettings');
guidata(hObject, handles);

function XLowerLimit_Callback(hObject, eventdata, handles)
% hObject    handle to XLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XLowerLimit as text
%        str2double(get(hObject,'String')) returns contents of XLowerLimit as a double


% --- Executes during object creation, after setting all properties.
function XLowerLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function XUpperLimit_Callback(hObject, eventdata, handles)
% hObject    handle to XUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XUpperLimit as text
%        str2double(get(hObject,'String')) returns contents of XUpperLimit as a double
updateHyscoreanGUI(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function XUpperLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkbox12.
function checkbox12_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox12



function YLowerLimit_Callback(hObject, eventdata, handles)
% hObject    handle to YLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YLowerLimit as text
%        str2double(get(hObject,'String')) returns contents of YLowerLimit as a double


% --- Executes during object creation, after setting all properties.
function YLowerLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YLowerLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function YUpperLimit_Callback(hObject, eventdata, handles)
% hObject    handle to YUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of YUpperLimit as text
%        str2double(get(hObject,'String')) returns contents of YUpperLimit as a double


% --- Executes during object creation, after setting all properties.
function YUpperLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to YUpperLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ZeroFilling1_Callback(hObject, eventdata, handles)
% hObject    handle to ZeroFilling1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZeroFilling1 as text
%        str2double(get(hObject,'String')) returns contents of ZeroFilling1 as a double


% --- Executes during object creation, after setting all properties.
function ZeroFilling1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ZeroFilling1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ZeroFilling2_Callback(hObject, eventdata, handles)
% hObject    handle to ZeroFilling2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ZeroFilling2 as text
%        str2double(get(hObject,'String')) returns contents of ZeroFilling2 as a double


% --- Executes during object creation, after setting all properties.
function ZeroFilling2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ZeroFilling2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Hammingedit_Callback(hObject, eventdata, handles)
% hObject    handle to Hammingedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Hammingedit as text
%        str2double(get(hObject,'String')) returns contents of Hammingedit as a double


% --- Executes during object creation, after setting all properties.
function Hammingedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Hammingedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function L2G_sigma_Callback(hObject, eventdata, handles)
% hObject    handle to L2G_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of L2G_sigma as text
%        str2double(get(hObject,'String')) returns contents of L2G_sigma as a double


% --- Executes during object creation, after setting all properties.
function L2G_sigma_CreateFcn(hObject, eventdata, handles)
% hObject    handle to L2G_sigma (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function L2G_tau_Callback(hObject, eventdata, handles)
% hObject    handle to L2G_tau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of L2G_tau as text
%        str2double(get(hObject,'String')) returns contents of L2G_tau as a double


% --- Executes during object creation, after setting all properties.
function L2G_tau_CreateFcn(hObject, eventdata, handles)
% hObject    handle to L2G_tau (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function L2G_sigma2_Callback(hObject, eventdata, handles)
% hObject    handle to L2G_sigma2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of L2G_sigma2 as text
%        str2double(get(hObject,'String')) returns contents of L2G_sigma2 as a double


% --- Executes during object creation, after setting all properties.
function L2G_sigma2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to L2G_sigma2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function L2G_tau2_Callback(hObject, eventdata, handles)
% hObject    handle to L2G_tau2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of L2G_tau2 as text
%        str2double(get(hObject,'String')) returns contents of L2G_tau2 as a double


% --- Executes during object creation, after setting all properties.
function L2G_tau2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to L2G_tau2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ChebishevWindow.
function ChebishevWindow_Callback(hObject, eventdata, handles)
% hObject    handle to ChebishevWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ChebishevWindow
if get(hObject,'Value')
    set(handles.HammingWindow,'Value',0);
else
    set(handles.HammingWindow,'Value',1);
end

% --- Executes on button press in HammingWindow.
function HammingWindow_Callback(hObject, eventdata, handles)
% hObject    handle to HammingWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HammingWindow
if get(hObject,'Value')
    set(handles.ChebishevWindow,'Value',0);
else
    set(handles.ChebishevWindow,'Value',1);
end

% --- Executes on button press in radiobutton16.
function radiobutton16_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton16



function edit19_Callback(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit19 as text
%        str2double(get(hObject,'String')) returns contents of edit19 as a double


% --- Executes during object creation, after setting all properties.
function edit19_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ZeroTimeTruncation.
function ZeroTimeTruncation_Callback(hObject, eventdata, handles)
% hObject    handle to ZeroTimeTruncation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ZeroTimeTruncation
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes on button press in InvertCorrection.
function InvertCorrection_Callback(hObject, eventdata, handles)
% hObject    handle to InvertCorrection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InvertCorrection
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes on button press in SavitzkyFilter.
function SavitzkyFilter_Callback(hObject, eventdata, handles)
% hObject    handle to SavitzkyFilter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SavitzkyFilter
if get(hObject,'Value')
  set(handles.FilterOrder, 'enable', 'on')
  set(handles.FilterOrderText, 'enable', 'on')
  set(handles.FrameLength, 'enable', 'on')
  set(handles.FrameLengthText, 'enable', 'on')
else
  set(handles.FilterOrder, 'enable', 'off')
  set(handles.FilterOrderText, 'enable', 'off')
  set(handles.FrameLength, 'enable', 'off')
  set(handles.FrameLengthText, 'enable', 'off')
end
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
handles.backgroundCorrectionSwitch = true;


guidata(hObject, handles);


function FilterOrder_Callback(hObject, eventdata, handles)
% hObject    handle to FilterOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FilterOrder as text
%        str2double(get(hObject,'String')) returns contents of FilterOrder as a double
if str2double(get(handles.FrameLength,'string'))< str2double(get(hObject,'string'))
    set(handles.FrameLength,'string',str2double(get(hObject,'string'))+1)
end
if ~mod(str2double(get(handles.FrameLength,'string')),2)
  set(handles.FrameLength,'string',str2double(get(handles.FrameLength,'string'))+1)
end
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FilterOrder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FilterOrder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FrameLength_Callback(hObject, eventdata, handles)
% hObject    handle to FrameLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrameLength as text
%        str2double(get(hObject,'String')) returns contents of FrameLength as a double
if str2double(get(hObject,'string'))< str2double(get(handles.FilterOrder,'string'))
    set(hObject,'string',str2double(get(handles.FilterOrder,'string'))+1)
end
if ~mod(str2double(get(hObject,'string')),2)
  set(hObject,'string',str2double(get(hObject,'string'))+1)
end
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function FrameLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in BackgroundMethod1.
function BackgroundMethod1_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundMethod1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BackgroundMethod1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BackgroundMethod1
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
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundMethod1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundMethod1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in BackgroundMethod2.
function BackgroundMethod2_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundMethod2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BackgroundMethod2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BackgroundMethod2
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
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundMethod2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundMethod2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BackgroundParameter1_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundParameter1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackgroundParameter1 as text
%        str2double(get(hObject,'String')) returns contents of BackgroundParameter1 as a double
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundParameter1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundParameter1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BackgroundParameter2_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundParameter2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackgroundParameter2 as text
%        str2double(get(hObject,'String')) returns contents of BackgroundParameter2 as a double
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundParameter2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundParameter2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ReconstructionAlgorithm.
function ReconstructionAlgorithm_Callback(hObject, eventdata, handles)
% hObject    handle to ReconstructionAlgorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ReconstructionAlgorithm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ReconstructionAlgorithm
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ReconstructionAlgorithm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ReconstructionAlgorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MaxEntBackgroundParameter_Callback(hObject, eventdata, handles)
% hObject    handle to MaxEntBackgroundParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxEntBackgroundParameter as text
%        str2double(get(hObject,'String')) returns contents of MaxEntBackgroundParameter as a double
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function MaxEntBackgroundParameter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxEntBackgroundParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MaxEntLagrangianMultiplier_Callback(hObject, eventdata, handles)
% hObject    handle to MaxEntLagrangianMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MaxEntLagrangianMultiplier as text
%        str2double(get(hObject,'String')) returns contents of MaxEntLagrangianMultiplier as a double
handles.ReconstructionSwitch = true;
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function MaxEntLagrangianMultiplier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxEntLagrangianMultiplier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in plotNUSgrid.
function plotNUSgrid_Callback(hObject, eventdata, handles)
% hObject    handle to plotNUSgrid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in plotNUSsignal.
function plotNUSsignal_Callback(hObject, eventdata, handles)
% hObject    handle to plotNUSsignal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in TauSelectionCheck.
function TauSelectionCheck_Callback(hObject, eventdata, handles)
% hObject    handle to TauSelectionCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TauSelectionCheck


% --- Executes on button press in BackgroundCorrectionCheck.
function BackgroundCorrectionCheck_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundCorrectionCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BackgroundCorrectionCheck


% --- Executes on button press in ReconstructionCheck.
function ReconstructionCheck_Callback(hObject, eventdata, handles)
% hObject    handle to ReconstructionCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ReconstructionCheck


% --- Executes on button press in BackgroundCorrectionWaiting.
function BackgroundCorrectionWaiting_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundCorrectionWaiting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BackgroundCorrectionWaiting


% --- Executes on button press in ReconstructionWaiting.
function ReconstructionWaiting_Callback(hObject, eventdata, handles)
% hObject    handle to ReconstructionWaiting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ReconstructionWaiting


% --- Executes on button press in TauSelectionWaiting.
function TauSelectionWaiting_Callback(hObject, eventdata, handles)
% hObject    handle to TauSelectionWaiting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of TauSelectionWaiting


% --- Executes on button press in radiobutton24.
function radiobutton24_Callback(hObject, eventdata, handles)
% hObject    handle to radiobutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of radiobutton24


% --- Executes on button press in detachMainContour.
function detachMainContour_Callback(hObject, eventdata, handles)
% hObject    handle to detachMainContour (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Figure = figure(51002);
set(Figure,'NumberTitle','off','Name','Hyscorean: HYSCORE Spectrum','Units','pixels','Position',[100 100 790 450]);
copyobj(handles.mainPlot,Figure)

% --- Executes on button press in detachMainSurface.
function detachMainSurface_Callback(hObject, eventdata, handles)
% hObject    handle to detachMainSurface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure(51001)
set(gcf,'NumberTitle','off','Name','Hyscorean: HYSCORE Surface','Units','pixels','Position',[100 100 790 450]);
if handles.GraphicalSettings.Absolute
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Real
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Imaginary
  spectrum2 = imag(handles.Processed.spectrum);
end
surf(handles.Processed.axis1,handles.Processed.axis2,spectrum2)
switch handles.GraphicalSettings.Colormap
  case 1
    colormap('parula')
  case 2
    colormap('jet')
  case 3
    colormap('hsv')
  case 4
    colormap('hot')
  case 5
    colormap('cool')
  case 6
    colormap('spring')
  case 7
    colormap('summer')
  case 8
    colormap('autumn')
  case 9
    colormap('winter')
  case 10
    colormap('gray')
end
shading('flat'),colorbar
  XupperLimit = str2double(get(handles.XUpperLimit,'string'));
  XlowerLimit = -XupperLimit;
  YupperLimit = XupperLimit;
  YlowerLimit = 0;
  xlim([XlowerLimit XupperLimit]),ylim([YlowerLimit YupperLimit])
  xlabel('\nu_1 [MHz]'), ylabel('\nu_2 [MHz]')

% --- Executes on button press in GraphicalSettingsButton.
function GraphicalSettingsButton_Callback(hObject, eventdata, handles)
% hObject    handle to GraphicalSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0,'GraphicalSettings',handles.GraphicalSettings)
%Set relative positioning of the new window
Position = handles.HyscoreanFigure.Position;
% Position(1) = Position(1)-40;
% Position(2) = Position(2)+25;
% Position(3) = 87.80000000000001;
% Position(4) = 12.615384615384613;
%Call graphical settings GUI
Hyscorean_GraphicalSettings
uiwait(Hyscorean_GraphicalSettings)

handles.GraphicalSettings = getappdata(0,'GraphicalSettings');

set(handles.ProcessingInfo, 'String', 'Status: Rendering...');drawnow;
try
updateHyscoreanGUI(handles,handles.Processed)
catch
end
set(handles.ProcessingInfo, 'String', 'Status: Finished');drawnow;


guidata(hObject, handles);

% --- Executes on button press in DisplayEchos.
function DisplayEchos_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayEchos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DisplayEchos


% --- Executes on button press in DisplayCorrected.
function DisplayCorrected_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayCorrected (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DisplayCorrected


% --- Executes on button press in DisplayIntegral.
function DisplayIntegral_Callback(hObject, eventdata, handles)
% hObject    handle to DisplayIntegral (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DisplayIntegral


% --- Executes on selection change in MultiTauDimensions.
function MultiTauDimensions_Callback(hObject, eventdata, handles)
% hObject    handle to MultiTauDimensions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MultiTauDimensions contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MultiTauDimensions
handles.TauSelectionSwitch = true;
  set(handles.TauSelectionCheck,'visible','off')
  set(handles.BackgroundCorrectionCheck,'visible','off')
  set(handles.ReconstructionCheck,'visible','off')
guidata(hObject,handles)

% --- Executes during object creation, after setting all properties.
function MultiTauDimensions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MultiTauDimensions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function GraphicalSettingsButton_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GraphicalSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
Root = which('Hyscorean');
Root = Root(1:end-12);
Path = fullfile(Root,'\bin');
data = load(fullfile(Path,'GraphicalSettings_default.mat'));
handles.GraphicalSettings = data.GraphicalSettings;
guidata(hObject, handles);


% --- Executes on button press in ImposeBlindSpots.
function ImposeBlindSpots_Callback(hObject, eventdata, handles)
% hObject    handle to ImposeBlindSpots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ImposeBlindSpots
updateHyscoreanGUI(handles,handles.Processed);


% --- Executes on button press in AddHelpLine.
function AddHelpLine_Callback(hObject, eventdata, handles)
% hObject    handle to AddHelpLine (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Get gyromagnetic ratio from selected nuclei
gyromagneticRatio = getgyro(get(handles.AddTagList,'Value'));
%Get center field in gauss
CenterField = handles.Data.BrukerParameters.CenterField; 
%Remove units character and convert to double
CenterField = str2double(CenterField(1:end-2));
%convert to tesla
CenterField = CenterField*1e-4;
%Get field offset
Offset = get(handles.FieldOffset,'string');
Offset = str2double(Offset(1:end-2))*1e-4;
%get Larmor frequency in MHz
Larmorfrequency = gyromagneticRatio*(CenterField + Offset);

X = Larmorfrequency;
Y = abs(Larmorfrequency);

  Xaxis = handles.Processed.axis1;
if X>0 
  Xaxis = Xaxis(Xaxis>0);
  Slope = -1;
else
    Xaxis = Xaxis(Xaxis<0);
    Slope = 1;
end
Yaxis =  Y + Slope*(Xaxis - X);
hold(handles.mainPlot,'on')
plot(handles.mainPlot,Xaxis,Yaxis,'k-.','LineWidth',0.5);
hold(handles.mainPlot,'off')
if isfield(handles,'AddedLines')
size = length(handles.AddedLines);
else
  size = 0;
end
handles.AddedLines{size +1}.x = Xaxis;
handles.AddedLines{size +1}.y = Yaxis;

guidata(hObject, handles);


% --- Executes on button press in AddTag.
function AddTag_Callback(hObject, eventdata, handles)
% hObject    handle to AddTag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%Get gyromagnetic ratio from selected nuclei
gyromagneticRatio = getgyro(get(handles.AddTagList,'Value'));
%Get center field in gauss
CenterField = handles.Data.BrukerParameters.CenterField; 
%Remove units character and convert to double
CenterField = str2double(CenterField(1:end-2));
%convert to tesla
CenterField = CenterField*1e-4;
%Get field offset
Offset = get(handles.FieldOffset,'string');
Offset = str2double(Offset(1:end-2))*1e-4;
%get Larmor frequency in MHz
Larmorfrequency = gyromagneticRatio*(CenterField + Offset);

X = Larmorfrequency;
Y = abs(Larmorfrequency);

Limit = str2double(get(handles.XUpperLimit,'string'));

if abs(Larmorfrequency) < Limit

Tags = handles.IsotopeTags;
Tag = Tags(get(handles.AddTagList,'Value'));


  AestheticShift = Limit/20;


text(handles.mainPlot,AestheticShift+X,Y,sprintf('^{%s}%s',Tag.isotope,Tag.name),'FontSize',14)

if isfield(handles,'AddedTags')
size = length(handles.AddedTags);
else
  size = 0;
end
handles.AddedTags{size +1}.x = X;
handles.AddedTags{size +1}.y = Y;
handles.AddedTags{size +1}.Tag = sprintf('^{%s}%s',Tag.isotope,Tag.name);
end

guidata(hObject, handles);

% --- Executes on selection change in AddTagList.
function AddTagList_Callback(hObject, eventdata, handles)
% hObject    handle to AddTagList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns AddTagList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from AddTagList


% --- Executes during object creation, after setting all properties.
function AddTagList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AddTagList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
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
% set(hObject,'string',ListBoxStrings)
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function SaverSettings_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaverSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.SaveHyscoreanSettings.IdentifierName = 'Hyscorean_save';
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function HyscoreanFigure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to HyscoreanFigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
% Root = which('Hyscorean');
% Pos = strfind(Root,'\Hyscorean 1.0');
% Root = Root(1:Pos); 
% addpath(fullfile(Root,'\Hyscorean 1.0\bin'))


% --- Executes on button press in ClearTags.
function ClearTags_Callback(hObject, eventdata, handles)
% hObject    handle to ClearTags (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
handles = rmfield(handles,'AddedLines');
catch 
end
try
handles = rmfield(handles,'AddedTags');
catch 
end
updateHyscoreanGUI(handles,handles.Processed)
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function trace2Info_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trace2Info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes during object creation, after setting all properties.
function trace1Info_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trace2Info (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in Lorentz2GaussCheck.
function Lorentz2GaussCheck_Callback(hObject, eventdata, handles)
% hObject    handle to Lorentz2GaussCheck (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Lorentz2GaussCheck
if get(hObject,'Value')
      enableDisableGUI(handles,'Lorent2Gauss','on')
else
      enableDisableGUI(handles,'Lorent2Gauss','off')
end


% --- Executes on button press in PlotApodizationWindow.
function PlotApodizationWindow_Callback(hObject, eventdata, handles)
% hObject    handle to PlotApodizationWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotApodizationWindow
handles.PlotProcessedSignal = true;

HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);


% --- Executes on button press in ChangeSignalPlotDimension.
function ChangeSignalPlotDimension_Callback(hObject, eventdata, handles)
% hObject    handle to ChangeSignalPlotDimension (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ChangeSignalPlotDimension
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);


% --- Executes on button press in DetachSignalPlot.
function DetachSignalPlot_Callback(hObject, eventdata, handles)
% hObject    handle to DetachSignalPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0,'Processed',handles.Processed)
setappdata(0,'Data',handles.Data)
setappdata(0,'InvertCorrection',get(handles.InvertCorrection,'value'))
setappdata(0,'ZeroFilling1',str2double(get(handles.ZeroFilling1,'String')))
setappdata(0,'ZeroFilling2',str2double(get(handles.ZeroFilling2,'String')))
setappdata(0,'Hammingedit',get(handles.Hammingedit,'String'))
setappdata(0,'HammingWindow',get(handles.HammingWindow,'Value'))

%Call graphical settings GUI
handles.SignalPlotIsDetached = true;
guidata(hObject, handles);

uiwait(Hyscorean_detachedSignalPlot)

handles.SignalPlotIsDetached = false;
guidata(hObject, handles);



function MinimalContourLevel_Callback(hObject, eventdata, handles)
% hObject    handle to MinimalContourLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MinimalContourLevel as text
%        str2double(get(hObject,'String')) returns contents of MinimalContourLevel as a double
if str2double(get(hObject,'String')) <= 0
  set(hObject,'String',1)
end
if str2double(get(hObject,'String')) >= 100
  set(hObject,'String',90)
end
updateHyscoreanGUI(handles,handles.Processed)  
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function MinimalContourLevel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MinimalContourLevel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over ProcessButton.
function ProcessButton_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ProcessButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function FieldOffset_Callback(hObject, eventdata, handles)
% hObject    handle to FieldOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FieldOffset as text
%        str2double(get(hObject,'String')) returns contents of FieldOffset as a double
FieldOffset = (get(hObject,'string'));
Tag = [FieldOffset ' G'];
set(hObject,'string',Tag);

% --- Executes during object creation, after setting all properties.
function FieldOffset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FieldOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over FieldOffset.
function FieldOffset_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to FieldOffset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(hObject,'string','');


% --- Executes during object creation, after setting all properties.
function GraphicsPanel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GraphicsPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% --- Executes on button press in AutomaticBackgroundStart.
function AutomaticBackgroundStart_Callback(hObject, eventdata, handles)
% hObject    handle to AutomaticBackgroundStart (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of AutomaticBackgroundStart
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')

if get(hObject,'value')
  set(handles.BackgroundStart1,'enable','off')
  set(handles.BackgroundStart2,'enable','off')
else
  set(handles.BackgroundStart1,'enable','on')
  set(handles.BackgroundStart2,'enable','on')
end
guidata(hObject, handles);

function BackgroundStart1_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundStart1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackgroundStart1 as text
%        str2double(get(hObject,'String')) returns contents of BackgroundStart1 as a double
if str2double(get(hObject,'String'))<1
   set(hObject,'string',1)
end
  
handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundStart1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundStart1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function BackgroundStart2_Callback(hObject, eventdata, handles)
% hObject    handle to BackgroundStart2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BackgroundStart2 as text
%        str2double(get(hObject,'String')) returns contents of BackgroundStart2 as a double
if str2double(get(hObject,'String'))<1
   set(hObject,'string',1)
end

handles.backgroundCorrectionSwitch = true;
set(handles.BackgroundCorrectionCheck,'visible','off')
set(handles.ReconstructionCheck,'visible','off')
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function BackgroundStart2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BackgroundStart2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in DetachProjectionPlot.
function DetachProjectionPlot_Callback(hObject, eventdata, handles)
% hObject    handle to DetachProjectionPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure(51002)
options.figsize = [500 500 790 450];

set(gcf,'NumberTitle','off','Name','Hyscorean: Projection Contour','Units','pixels','Position',options.figsize);
  XUpperLimit=str2double(get(handles.XUpperLimit,'string'));
  options.xaxs = [-XUpperLimit XUpperLimit]; options.yaxs = [0 XUpperLimit];
  options.xlabel = '\nu_1 [MHz]'; options.ylabel = '\nu_2 [MHz]';
options.levels=handles.GraphicalSettings.Levels;
options.Linewidth=handles.GraphicalSettings.Linewidth;
options.nonewfig = true;
options.MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
switch handles.GraphicalSettings.Colormap
  case 1
    colormap('parula')
  case 2
    colormap('jet')
  case 3
    colormap('hsv')
  case 4
    colormap('hot')
  case 5
    colormap('cool')
  case 6
    colormap('spring')
  case 7
    colormap('summer')
  case 8
    colormap('autumn')
  case 9
    colormap('winter')
  case 10
    colormap('gray')
end
if handles.GraphicalSettings.Absolute
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Real
  spectrum2 = real(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Imaginary
  spectrum2 = imag(handles.Processed.spectrum);
end
Hyscore_correlation_plot(handles.Processed.axis2,handles.Processed.axis1,spectrum2,options)
