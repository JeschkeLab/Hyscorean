function varargout = Hyscorean_saveSettings(varargin)
%==========================================================================
% SaveHyscorean Settings
%==========================================================================
% This function collects all callbacks of the GUI Hyscorean_saveSettings
% which allows the user to define the path and identifier to use when using
% the Save&Report button. 
%
% (See Hyscorean's manual for more information)
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
                   'gui_OpeningFcn', @Hyscorean_saveSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @Hyscorean_saveSettings_OutputFcn, ...
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
function Hyscorean_saveSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output 
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

initialize_gui(hObject, handles, false);
%==========================================================================

%==========================================================================
function varargout = Hyscorean_saveSettings_OutputFcn(hObject, eventdata, handles)
% Get default command line output from handles structure
varargout{1} = handles.output;
%==========================================================================

%==========================================================================
function Set_Callback(hObject, eventdata, handles)

%Get default save path from Hyscorean preferences
DefaultSavePath = getpref('hyscorean','savepath');
%Now get the save path given in the edit box
SavePath = get(handles.SavePath,'String');

%Now if they are different then inform user
if ~strcmp(DefaultSavePath,SavePath)
  
  %Ask user if path does not exist and ask to create it
  if ~exist(SavePath,'dir')
    choice = questdlg('The folder given as default path does not exist. Do you want to create it (otherwise the previous default path will be set)?', ...
      'Hyscorean', ...
      'Yes','No','Yes');
    switch choice
      case 'Yes'
        Answer = 1;
      case 'No'
        Answer = 0;
    end
    %If allowed by user then create new directory
    if Answer
      mkdir(SavePath)
    else
      %Otherwise set the default path into the edit box and return
      set(handles.SavePath,'String',DefaultSavePath)
      SavePath = get(handles.SavePath,'String');
      return
    end
  end
  %Now ask the user if they want to overwritte the default path by the new one
  choice = questdlg('The default save path has been modified and will be now saved for further sessions.... Do you want to overwrite the previous default path?', ...
    'Hyscorean', ...
    'Yes','No','Yes');
  switch choice
    case 'Yes'
      Answer = 1;
    case 'No'
      Answer = 0;
  end
  %If allowed, then set new path as default save path
  if Answer
    Root = fileparts(which('Hyscorean'));
    Path = fullfile(Root,'bin');
    setpref('hyscorean','savepath',SavePath)
  end
end
%Set app data to get it back at Hyscorean (old method, works but can be improved)
setappdata(0,'SaverSettings',handles.SaverSettings)
%Close the window and return
close()
%==========================================================================

%==========================================================================
function Cancel_Callback(hObject, eventdata, handles)
%Just return without doing anything more
close()
%==========================================================================

%==========================================================================
function initialize_gui(fig_handle, handles, isreset)
% If the metricdata field is present and the Cancel flag is false, it means
% we are we are just re-initializing a GUI by calling it from the cmd line
% while it is up. So, bail out as we dont want to Cancel the data.
if isfield(handles, 'metricdata') && ~isreset
    return;
end
%==========================================================================

%==========================================================================
function SavePath_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%Load the default save path... 
SavePath = getpref('hyscorean','savepath');
%... and set it into to edit box upon creation
set(hObject,'String',SavePath)
%==========================================================================

%==========================================================================
function Identifier_Callback(hObject, eventdata, handles)
%Save the input identifier to handles
handles.SaverSettings.IdentifierName = get(hObject,'String');
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function Identifier_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.SaverSettings = getappdata(0,'SaverSettings');
set(hObject,'String',handles.SaverSettings.IdentifierName)
guidata(hObject, handles);
%==========================================================================

%==========================================================================
function UILoad_Button_Callback(hObject, eventdata, handles)
%Allow user to choose directory via OS window
selpath = uigetdir;
set(handles.SavePath,'String',selpath);
%==========================================================================
