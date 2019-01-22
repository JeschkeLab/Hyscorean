function varargout = Hyscorean_esfit_GraphicalSettings(varargin)
% TRIERANALYSIS_GRAPHICALSETTINGS MATLAB code for TrierAnalysis_GraphicalSettings.fig
%      TRIERANALYSIS_GRAPHICALSETTINGS, by itself, creates a new TRIERANALYSIS_GRAPHICALSETTINGS or raises the existing
%      singleton*.
%
%      H = TRIERANALYSIS_GRAPHICALSETTINGS returns the handle to a new TRIERANALYSIS_GRAPHICALSETTINGS or the handle to
%      the existing singleton*.
%
%      TRIERANALYSIS_GRAPHICALSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRIERANALYSIS_GRAPHICALSETTINGS.M with the given input arguments.
%
%      TRIERANALYSIS_GRAPHICALSETTINGS('Property','Value',...) creates a new TRIERANALYSIS_GRAPHICALSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TrierAnalysis_GraphicalSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TrierAnalysis_GraphicalSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TrierAnalysis_GraphicalSettings

% Last Modified by GUIDE v2.5 23-Jan-2018 15:51:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Hyscorean_esfit_GraphicalSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @Hyscorean_esfit_GraphicalSettings_OutputFcn, ...
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


function Hyscorean_esfit_GraphicalSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TrierAnalysis_GraphicalSettings (see VARARGIN)
% Choose default command line output for TrierAnalysis_GraphicalSettings
handles.output = hObject;
% Update handles structure
Settings = varargin{1};

set(handles.ExperimentalSpectrumType,'value',Settings.ExperimentalSpectrumType);
set(handles.FitSpectraType,'value',Settings.FitSpectraType);
set(handles.Linewidth,'string',num2str(Settings.LineWidth));
set(handles.ContourLevels,'string',num2str(Settings.ContourLevels));
handles.Settings = Settings;
guidata(hObject, handles);

% UIWAIT makes TrierAnalysis_GraphicalSettings wait for user response (see UIRESUME)
uiwait(handles.figure1);

function Hyscorean_esfit_GraphicalSettings_CloseReqFcn(hObject, eventdata, handles, varargin)

if isequal(get(hObject, 'waitstatus'), 'waiting')
% The GUI is still in UIWAIT, us UIRESUME
uiresume(hObject);
else
% The GUI is no longer waiting, just close it
delete(hObject);
end

% --- Outputs from this function are returned to the command line.
function varargout = Hyscorean_esfit_GraphicalSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
varargout{1} = handles.Settings;
delete(handles.figure1);
% --- Executes on selection change in PlotType.
function ExperimentalSpectrumType_Callback(hObject, eventdata, handles)
% hObject    handle to PlotType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PlotType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PlotType
handles.Settings.ExperimentalSpectrumType = (get(hObject,'value'));
guidata(hObject, handles);

% --- Executes on selection change in Colormap.
function FitSpectraType_Callback(hObject, eventdata, handles)
% hObject    handle to Colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Colormap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Colormap
handles.Settings.FitSpectraType = (get(hObject,'value'));
guidata(hObject, handles);

% --- Executes on button press in SaveButton.
function SaveButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Settings.ExperimentalSpectrumType = get(handles.ExperimentalSpectrumType,'value');
Settings.FitSpectraType = get(handles.FitSpectraType,'value');
Settings.LineWidth = str2double(get(handles.Linewidth,'string'));
Settings.ContourLevels = str2double(get(handles.ContourLevels,'string'));
handles.Settings = Settings;
guidata(hObject, handles);

uiresume(handles.figure1);

% --- Executes on button press in LoadDefault.
function LoadDefault_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Settings = handles.Settings;
set(handles.ExperimentalSpectrumType,'value',Settings.ExperimentalSpectrumType);
set(handles.FitSpectraType,'value',Settings.FitSpectraType);
set(handles.Linewidth,'string',num2str(Settings.Linewidth));
set(handles.ContourLevels,'string',num2str(Settings.ContourLevels));
guidata(hObject, handles);



function ContourLevels_Callback(hObject, eventdata, handles)
% hObject    handle to ContourLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ContourLevels as text
%        str2double(get(hObject,'String')) returns contents of ContourLevels as a double
handles.Settings.ContourLevels = str2double(get(hObject,'string'));
guidata(hObject, handles);


function Linewidth_Callback(hObject, eventdata, handles)
% hObject    handle to Linewidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Linewidth as text
%        str2double(get(hObject,'String')) returns contents of Linewidth as a double
handles.Settings.Linewidth = str2double(get(hObject,'string'));
guidata(hObject, handles);
