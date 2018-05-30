function varargout = Hyscorean_detachedSignalPlot(varargin)
% HYSCOREAN_DETACHEDSIGNALPLOT MATLAB code for Hyscorean_detachedSignalPlot.fig
%      HYSCOREAN_DETACHEDSIGNALPLOT, by itself, creates a new HYSCOREAN_DETACHEDSIGNALPLOT or raises the existing
%      singleton*.
%
%      H = HYSCOREAN_DETACHEDSIGNALPLOT returns the handle to a new HYSCOREAN_DETACHEDSIGNALPLOT or the handle to
%      the existing singleton*.
%
%      HYSCOREAN_DETACHEDSIGNALPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HYSCOREAN_DETACHEDSIGNALPLOT.M with the given input arguments.
%
%      HYSCOREAN_DETACHEDSIGNALPLOT('Property','Value',...) creates a new HYSCOREAN_DETACHEDSIGNALPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Hyscorean_detachedSignalPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Hyscorean_detachedSignalPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Hyscorean_detachedSignalPlot

% Last Modified by GUIDE v2.5 29-May-2018 12:34:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Hyscorean_detachedSignalPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @Hyscorean_detachedSignalPlot_OutputFcn, ...
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


% --- Executes just before Hyscorean_detachedSignalPlot is made visible.
function Hyscorean_detachedSignalPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Hyscorean_detachedSignalPlot (see VARARGIN)

% Choose default command line output for Hyscorean_detachedSignalPlot
handles.output = hObject;
Processed = getappdata(0,'Processed');
handles.Processed = Processed;
handles.Data = getappdata(0,'Data');
Hammingedit = getappdata(0,'Hammingedit');
HammingWindow = getappdata(0,'HammingWindow');
set(handles.HammingWindow,'Value',HammingWindow)
set(handles.Hammingedit,'string',Hammingedit)
ZeroFilling1 = getappdata(0,'ZeroFilling1');
ZeroFilling2 = getappdata(0,'ZeroFilling2');
set(handles.ZeroFilling2,'string',ZeroFilling2)
set(handles.ZeroFilling1,'string',ZeroFilling1)
Npoints = length(Processed.TimeAxis2) - str2double(get(handles.ZeroFilling2,'string'));
set(handles.t1_Slider,'Min', 1, 'Max',Npoints , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 1)
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Hyscorean_detachedSignalPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Hyscorean_detachedSignalPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles.PlotProcessedSignal = get(handles.PlotProcessed,'Value');
HyscoreanSignalPlot(handles,handles.Processed)

varargout{1} = handles.output;


% --- Executes on slider movement.
function t1_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to t1_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.slider_t1=get(hObject,'Value');
Processed = handles.Processed;
handles.PlotProcessedSignal = get(handles.PlotProcessed,'Value');
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


% --- Executes on button press in NonCorrectedTrace.
function NonCorrectedTrace_Callback(hObject, eventdata, handles)
% hObject    handle to NonCorrectedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NonCorrectedTrace
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes on button press in PreProcessedTrace.
function PreProcessedTrace_Callback(hObject, eventdata, handles)
% hObject    handle to PreProcessedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PreProcessedTrace
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes on button press in PlotApodizationWindow.
function PlotApodizationWindow_Callback(hObject, eventdata, handles)
% hObject    handle to PlotApodizationWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotApodizationWindow
HyscoreanSignalPlot(handles,handles.Processed)


% --- Executes on button press in ChangeSignalPlotDimension.
function ChangeSignalPlotDimension_Callback(hObject, eventdata, handles)
% hObject    handle to ChangeSignalPlotDimension (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ChangeSignalPlotDimension


HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes on button press in PlotProcessed.
function PlotProcessed_Callback(hObject, eventdata, handles)
% hObject    handle to PlotProcessed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PlotProcessed
handles.PlotProcessedSignal = get(hObject,'Value');
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function signal_t1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to signal_t1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate signal_t1



% --- Executes during object creation, after setting all properties.
function ChangeSignalPlotDimension_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChangeSignalPlotDimension (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function PlotApodizationWindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PlotApodizationWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function PreProcessedTrace_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PreProcessedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
guidata(hObject,handles)


% --- Executes during object creation, after setting all properties.
function NonCorrectedTrace_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NonCorrectedTrace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
guidata(hObject,handles)



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


% --- Executes on button press in HammingWindow.
function HammingWindow_Callback(hObject, eventdata, handles)
% hObject    handle to HammingWindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of HammingWindow
