function varargout = Hyscorean_esfit_GraphicalSettings(varargin)
%------------------------------------------------------------------------
% Hyscorean Fitting module graphical settings GUI
%------------------------------------------------------------------------
% This function contains the callbacks of the UI elements for the graphical
% settings of the Hyscorean fitting module. This GUI allows the user to
% select the different plot styles and contour levels for the experimental
% as well as for the fitted spectra. 
% This is a GUI generated via GUIDE and requires the 
% Hyscorean_esfit_GraphicalSettings.fig file to execute.
% (See the Hyscorean manual for further details) 
%
% This function is called from esfit_hyscorean and cannot be employed as a
% standalone function.
%------------------------------------------------------------------------
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%------------------------------------------------------------------------

%GUIDE specific definitions
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

%------------------------------------------------------------------------
function Hyscorean_esfit_GraphicalSettings_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
set(hObject,'Units',varargin{2});
set(hObject,'Position',varargin{3});
Settings = varargin{1};
%Get current settings from the function input and set the UI elements
set(handles.ExperimentalSpectrumType,'value',Settings.ExperimentalSpectrumType);
set(handles.FitSpectraType,'value',Settings.FitSpectraType);
set(handles.Linewidth,'string',num2str(Settings.LineWidth));
set(handles.ContourLevels,'string',num2str(Settings.ContourLevels));
handles.Settings = Settings;
guidata(hObject, handles);

%Set the GUI in a uiwait state to make the window modal
uiwait(handles.figure1);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function Hyscorean_esfit_GraphicalSettings_CloseReqFcn(hObject, eventdata, handles, varargin)
%The GUI will close as soon as the Save button is pressed.
if isequal(get(hObject, 'waitstatus'), 'waiting')
% The GUI is still in UIWAIT, us UIRESUME
uiresume(hObject);
else
% The GUI is no longer waiting, just close it
delete(hObject);
end
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function varargout = Hyscorean_esfit_GraphicalSettings_OutputFcn(hObject, eventdata, handles) 
%When closing, return the settings as the function output
varargout{1} = handles.Settings;
delete(handles.figure1);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function ExperimentalSpectrumType_Callback(hObject, eventdata, handles)
handles.Settings.ExperimentalSpectrumType = (get(hObject,'value'));
guidata(hObject, handles);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function FitSpectraType_Callback(hObject, eventdata, handles)
handles.Settings.FitSpectraType = (get(hObject,'value'));
guidata(hObject, handles);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function ContourLevels_Callback(hObject, eventdata, handles)
handles.Settings.ContourLevels = str2double(get(hObject,'string'));
guidata(hObject, handles);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function Linewidth_Callback(hObject, eventdata, handles)
handles.Settings.Linewidth = str2double(get(hObject,'string'));
guidata(hObject, handles);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function SaveButton_Callback(hObject, eventdata, handles)
%Get the current state of the UI elements
Settings.ExperimentalSpectrumType = get(handles.ExperimentalSpectrumType,'value');
Settings.FitSpectraType = get(handles.FitSpectraType,'value');
Settings.LineWidth = str2double(get(handles.Linewidth,'string'));
Settings.Cancelled = false;
Settings.ContourLevels = str2double(get(handles.ContourLevels,'string'));
%Save them to the handles
handles.Settings = Settings;
guidata(hObject, handles);
%Lift the uiwait state prompting the CloseReqFcn to start
uiresume(handles.figure1);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function LoadDefault_Callback(hObject, eventdata, handles)
%Reset the UI elements to the state at the creation of the window
Settings = handles.Settings;
set(handles.ExperimentalSpectrumType,'value',Settings.ExperimentalSpectrumType);
set(handles.FitSpectraType,'value',Settings.FitSpectraType);
set(handles.Linewidth,'string',num2str(Settings.Linewidth));
set(handles.ContourLevels,'string',num2str(Settings.ContourLevels));
guidata(hObject, handles);
%------------------------------------------------------------------------

%------------------------------------------------------------------------
function CloseButton_Callback(hObject, eventdata, handles)
%Get the current state of the UI elements
Settings.Cancelled = true;
%Save them to the handles
handles.Settings = Settings;
guidata(hObject, handles);
%Lift the uiwait state prompting the CloseReqFcn to start
uiresume(handles.figure1);
%------------------------------------------------------------------------