function varargout = Hyscorean_GraphicalSettings(varargin)
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
                   'gui_OpeningFcn', @TrierAnalysis_GraphicalSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @TrierAnalysis_GraphicalSettings_OutputFcn, ...
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


% --- Executes just before TrierAnalysis_GraphicalSettings is made visible.
function TrierAnalysis_GraphicalSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TrierAnalysis_GraphicalSettings (see VARARGIN)
% Choose default command line output for TrierAnalysis_GraphicalSettings
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);
GraphicalSettings = getpref('hyscorean','graphicalsettings');
handles.GraphicalSettings = GraphicalSettings;
set(handles.Absolute,'value',handles.GraphicalSettings.Absolute);
set(handles.Imaginary,'value',handles.GraphicalSettings.Imaginary);
set(handles.Real,'value',handles.GraphicalSettings.Real);
set(handles.Colormap,'value',handles.GraphicalSettings.Colormap);
set(handles.PlotType,'value',handles.GraphicalSettings.PlotType);
set(handles.Linewidth,'string',num2str(handles.GraphicalSettings.LineWidth));
set(handles.ContourLevels,'string',num2str(handles.GraphicalSettings.Levels));
% UIWAIT makes TrierAnalysis_GraphicalSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TrierAnalysis_GraphicalSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in PlotType.
function PlotType_Callback(hObject, eventdata, handles)
% hObject    handle to PlotType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PlotType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PlotType
handles.GraphicalSettings.PlotType = (get(hObject,'value'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function PlotType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PlotType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'Value',handles.GraphicalSettings.PlotType)
guidata(hObject, handles);

% --- Executes on selection change in Colormap.
function Colormap_Callback(hObject, eventdata, handles)
% hObject    handle to Colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns Colormap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Colormap
handles.GraphicalSettings.Colormap = (get(hObject,'value'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Colormap_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'Value',handles.GraphicalSettings.Colormap)
guidata(hObject, handles);

% --- Executes on button press in SaveButton.
function SaveButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
setappdata(0,'GraphicalSettings',handles.GraphicalSettings)
setpref('hyscorean','graphicalsettings',handles.GraphicalSettings)

close()


% --- Executes on button press in SaveDefault.
function SaveDefault_Callback(hObject, eventdata, handles)
% hObject    handle to SaveDefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GraphicalSettings = handles.GraphicalSettings;
if dialog_default_graphics
Root = which('Hyscorean');
Root = Root(1:end-12);
Path = fullfile(Root,'\bin');
setpref('hyscorean','graphicalsettings',GraphicalSettings)
% save(fullfile(Path,'GraphicalSettings_default.mat'),'GraphicalSettings')
end

% --- Executes on button press in LoadDefault.
function LoadDefault_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Root = which('Hyscorean');
Root = Root(1:end-12);
Path = fullfile(Root,'\bin');
% data = load(fullfile(Path,'GraphicalSettings_default.mat'));
GraphicalSettings = getpref('hyscorean','graphicalsettings');
handles.GraphicalSettings = GraphicalSettings;
set(handles.Absolute,'value',handles.GraphicalSettings.Absolute);
set(handles.Imaginary,'value',handles.GraphicalSettings.Imaginary);
set(handles.Real,'value',handles.GraphicalSettings.Real);
set(handles.Colormap,'value',handles.GraphicalSettings.Colormap);
set(handles.PlotType,'value',handles.GraphicalSettings.PlotType);
set(handles.Linewidth,'string',num2str(handles.GraphicalSettings.Linewidth));
set(handles.ContourLevels,'string',num2str(handles.GraphicalSettings.Levels));
guidata(hObject, handles);



function ContourLevels_Callback(hObject, eventdata, handles)
% hObject    handle to ContourLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ContourLevels as text
%        str2double(get(hObject,'String')) returns contents of ContourLevels as a double
handles.GraphicalSettings.Levels = str2double(get(hObject,'string'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ContourLevels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ContourLevels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.GraphicalSettings = getpref('hyscorean','graphicalsettings');
set(hObject,'string',num2str(handles.GraphicalSettings.Levels))
guidata(hObject, handles);


function Linewidth_Callback(hObject, eventdata, handles)
% hObject    handle to Linewidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Linewidth as text
%        str2double(get(hObject,'String')) returns contents of Linewidth as a double
handles.GraphicalSettings.LineWidth = str2double(get(hObject,'string'));
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Linewidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Linewidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'string',num2str(handles.GraphicalSettings.LineWidth))
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function Absolute_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Absolute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'Value',(handles.GraphicalSettings.Absolute))
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function Real_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Real (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'Value',(handles.GraphicalSettings.Real))
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function Imaginary_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Imaginary (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
handles.GraphicalSettings = getappdata(0,'GraphicalSettings');
set(hObject,'Value',(handles.GraphicalSettings.Imaginary))
guidata(hObject, handles);


% --- Executes on button press in Absolute.
function Absolute_Callback(hObject, eventdata, handles)
% hObject    handle to Absolute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Absolute
handles.GraphicalSettings.Absolute = (get(hObject,'value'));
handles.GraphicalSettings.Imaginary = get(handles.Imaginary,'value');
handles.GraphicalSettings.Real = get(handles.Real,'value');
guidata(hObject, handles);


% --- Executes on button press in Real.
function Real_Callback(hObject, eventdata, handles)
% hObject    handle to Real (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Real
handles.GraphicalSettings.Real = get(hObject,'value');
handles.GraphicalSettings.Absolute = get(handles.Absolute,'value');
handles.GraphicalSettings.Imaginary = get(handles.Imaginary,'value');
guidata(hObject, handles);


% --- Executes on button press in Imaginary.
function Imaginary_Callback(hObject, eventdata, handles)
% hObject    handle to Imaginary (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Imaginary
handles.GraphicalSettings.Imaginary = (get(hObject,'value'));
handles.GraphicalSettings.Absolute = get(handles.Absolute,'value');
handles.GraphicalSettings.Real = get(handles.Real,'value');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
