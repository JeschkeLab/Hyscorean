function varargout = Hyscorean_saveSettings(varargin)
% TRIERANALYSIS_SAVESETTINGS MATLAB code for TrierAnalysis_saveSettings.fig
%      TRIERANALYSIS_SAVESETTINGS, by itself, creates a new TRIERANALYSIS_SAVESETTINGS or raises the existing
%      singleton*.
%
%      H = TRIERANALYSIS_SAVESETTINGS returns the handle to a new TRIERANALYSIS_SAVESETTINGS or the handle to
%      the existing singleton*.
%
%      TRIERANALYSIS_SAVESETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRIERANALYSIS_SAVESETTINGS.M with the given input arguments.
%
%      TRIERANALYSIS_SAVESETTINGS('Property','Value',...) creates a new TRIERANALYSIS_SAVESETTINGS or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TrierAnalysis_saveSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TrierAnalysis_saveSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TrierAnalysis_saveSettings

% Last Modified by GUIDE v2.5 17-May-2018 16:28:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TrierAnalysis_saveSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @TrierAnalysis_saveSettings_OutputFcn, ...
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

% --- Executes just before TrierAnalysis_saveSettings is made visible.
function TrierAnalysis_saveSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TrierAnalysis_saveSettings (see VARARGIN)

% Choose default command line output for TrierAnalysis_saveSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);

% UIWAIT makes TrierAnalysis_saveSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TrierAnalysis_saveSettings_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on button press in Set.
function Set_Callback(hObject, eventdata, handles)
% hObject    handle to Set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Default = load('Hyscorean_default_savepath.mat');
SavePath = get(handles.SavePath,'String');
if ~strcmp(Default.SavePath,SavePath)
  
  if ~exist(SavePath,'dir')
    choice = questdlg('The folder given as default path does not exist. Do you want to create it (otherwise the previous default path will be set)?', ...
      'Hyscorean', ...
      'Yes','No','Yes');
    % Handle response
    switch choice
      case 'Yes'
        Answer = 1;
      case 'No'
        Answer = 0;
    end
    if Answer
      mkdir(SavePath)
    else
      set(handles.SavePath,'String',Default.SavePath)
      SavePath = get(handles.SavePath,'String');
      return
    end   
  end
if dialog_default_saver
Root = which('Hyscorean');
Root = Root(1:end-12);
Path = fullfile(Root,'\bin');
save(fullfile(Path,'Hyscorean_default_savepath.mat'),'SavePath')
end
end
setappdata(0,'SaverSettings',handles.SaverSettings)
close()

% --- Executes on button press in Cancel.
function Cancel_Callback(hObject, eventdata, handles)
% hObject    handle to Cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close()

% --------------------------------------------------------------------
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the Cancel flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to Cancel the data.
if isfield(handles, 'metricdata') && ~isreset
    return;
end

function SavePath_Callback(hObject, eventdata, handles)
% hObject    handle to SavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SavePath as text
%        str2double(get(hObject,'String')) returns contents of SavePath as a double

% --- Executes during object creation, after setting all properties.
function SavePath_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SavePath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

load Hyscorean_default_savepath.mat
set(hObject,'String',SavePath)


function Identifier_Callback(hObject, eventdata, handles)
% hObject    handle to Identifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Identifier as text
%        str2double(get(hObject,'String')) returns contents of Identifier as a double
handles.SaverSettings.IdentifierName = get(hObject,'String');
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function Identifier_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Identifier (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.SaverSettings = getappdata(0,'SaverSettings');
set(hObject,'String',handles.SaverSettings.IdentifierName)
guidata(hObject, handles);
