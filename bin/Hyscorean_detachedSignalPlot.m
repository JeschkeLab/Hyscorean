function varargout = Hyscorean_detachedSignalPlot(varargin)
%==========================================================================
% Hyscorean Detached Signal Monitoring 
%==========================================================================
% This function collects all callbacks needed by the external detached
% signal monitoring GUI. 
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================
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
%==========================================================================

%==========================================================================
function Hyscorean_detachedSignalPlot_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
%Get data from Hyscorean
Processed = getappdata(0,'Processed');
handles.Processed = Processed;
handles.Data = getappdata(0,'Data');
InvertCorrection = getappdata(0,'InvertCorrection');
set(handles.InvertCorrection,'value',InvertCorrection)
WindowLength1 = getappdata(0,'WindowLength1');
WindowLength2 = getappdata(0,'WindowLength2');
HammingWindow = getappdata(0,'HammingWindow');
ZeroFilling1 = getappdata(0,'ZeroFilling1');
ZeroFilling2 = getappdata(0,'ZeroFilling2');
WindowTypeState =  getappdata(0,'WindowType');
%Set the different handles to their corresponding values
set(handles.HammingWindow,'Value',HammingWindow)
set(handles.WindowLength1,'string',WindowLength1)
set(handles.WindowLength2,'string',WindowLength2)
set(handles.WindowType,'value',WindowTypeState)
set(handles.ZeroFilling2,'string',ZeroFilling2)
set(handles.ZeroFilling1,'string',ZeroFilling1)
Npoints = length(Processed.TimeAxis2) - str2double(get(handles.ZeroFilling2,'string'));
set(handles.t1_Slider,'Min', 1, 'Max',Npoints , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 1)
% Update handles structure
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function varargout = Hyscorean_detachedSignalPlot_OutputFcn(hObject, eventdata, handles) 
handles.PlotProcessedSignal = get(handles.PlotProcessed,'Value');
HyscoreanSignalPlot(handles,handles.Processed)
varargout{1} = handles.output;
%==========================================================================

%==========================================================================
function t1_Slider_Callback(hObject, eventdata, handles)
handles.slider_t1=get(hObject,'Value');
Processed = handles.Processed;
handles.PlotProcessedSignal = get(handles.PlotProcessed,'Value');
HyscoreanSignalPlot(handles,Processed)
guidata(hObject,handles)
%==========================================================================

%==========================================================================
function NonCorrectedTrace_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function PreProcessedTrace_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function PlotApodizationWindow_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
%==========================================================================

%==========================================================================
function ChangeSignalPlotDimension_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function PlotProcessed_Callback(hObject, eventdata, handles)
handles.PlotProcessedSignal = get(hObject,'Value');
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function PlotBackground_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function PlotWithZeroFilling_Callback(hObject, eventdata, handles)
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function ImaginaryButton_Callback(hObject, eventdata, handles)
if get(handles.RealButton,'value')
  set(handles.RealButton,'Value',0)
else
  set(handles.RealButton,'Value',1)
end
if get(hObject,'value')
  handles.PlotImaginarySignal = true;
else
  handles.PlotImaginarySignal = false;
end
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function RealButton_Callback(hObject, eventdata, handles)
if get(handles.ImaginaryButton,'value')
  set(handles.ImaginaryButton,'Value',0)
else
  set(handles.ImaginaryButton,'Value',1)
end
if get(hObject,'value')
  handles.PlotImaginarySignal = false;
else
  handles.PlotImaginarySignal = true;
end
HyscoreanSignalPlot(handles,handles.Processed)
guidata(hObject, handles);
%==========================================================================
