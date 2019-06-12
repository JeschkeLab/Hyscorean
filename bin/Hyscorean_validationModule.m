function varargout = Hyscorean_validationModule(varargin)
%==========================================================================
% Hyscorean validation module
%==========================================================================
% This code is responsible for all callbacks of the Hyscorean validation
% module GUI. The function cannot be called directly since it depends on
% input from the Hyscorean GUI. 
% THe validation module permits the validation of all critical processing 
% steps in Hyscorean such as background correction and reconstruction. 
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
                   'gui_OpeningFcn', @Hyscorean_validationModule_OpeningFcn, ...
                   'gui_OutputFcn',  @Hyscorean_validationModule_OutputFcn, ...
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

%------------------------------------------------------------------------------
% --- Executes just before Hyscorean_validationModule is made visible.
function Hyscorean_validationModule_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;
warning('off','all')
Path =  fileparts(which('Hyscorean'));
jFrame=get(hObject,'javaframe');
jicon=javax.swing.ImageIcon(fullfile(Path, 'bin', 'logo.png'));
jFrame.setFigureIcon(jicon);
handles.output = hObject;
warning('on','all')
guidata(hObject, handles);

% Choose default command line output for Hyscorean_validationModule
handles.output = hObject;
handles.RawData = varargin{1};
handles.Defaults = varargin{2};

%Prepare the sampling density slider
if isfield(handles.RawData,'NUS')
  handles.RawData.NUS.SamplingDensity = length(find(handles.RawData.NUSgrid ==1))/(handles.RawData.NUS.Dimension1*handles.RawData.NUS.Dimension2);
  Npoints  = length(1:0.1:100*handles.RawData.NUS.SamplingDensity );
  set(handles.SamplingDensity_Slider,'Min', 1, 'Max',100*handles.RawData.NUS.SamplingDensity  , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 100*handles.RawData.NUS.SamplingDensity )
  String = sprintf('%.1f%%',100*handles.RawData.NUS.SamplingDensity );
  set(handles.SliderText,'string',String);
end

%Check if data is NUS and activate proper UI elements
if handles.RawData.NUSflag
  switch handles.Defaults.ReconstructionMethod
    case {'ists','istd'}
      set(handles.ThresholdParameter_Check,'enable','on')
      set(handles.LagrangeMultiplier_Check,'enable','off')
      set(handles.BackgroundParameter_Check,'enable','off')
    case {'ffmgd','ffmcg'}
      set(handles.ThresholdParameter_Check,'enable','off')
      set(handles.LagrangeMultiplier_Check,'enable','off')
      set(handles.BackgroundParameter_Check,'enable','on')
    otherwise
      set(handles.ThresholdParameter_Check,'enable','off')
      set(handles.LagrangeMultiplier_Check,'enable','on')
      set(handles.BackgroundParameter_Check,'enable','on')
  end
else
  set(handles.NoiseLevel_Check,'enable','off')
  set(handles.SamplingDensity_Check,'enable','off')
  set(handles.LagrangeMultiplier_Check,'enable','off')
  set(handles.BackgroundParameter_Check,'enable','off')
  set(handles.ThresholdParameter_Check,'enable','off')
end

% Update handles structure
guidata(hObject, handles);

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
%                            GUI OUTPUT FUNCTION
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
function varargout = Hyscorean_validationModule_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
varargout{1} = handles.output;
cla(handles.ValidationMainPlot)
cla(handles.ValidationInset1)
cla(handles.ValidationInset2)
set(handles.ValidationMainPlot,'xticklabel',[],'yticklabel',[])
set(handles.ValidationInset1,'xticklabel',[],'yticklabel',[])
set(handles.ValidationInset2,'xticklabel',[],'yticklabel',[])
box(handles.ValidationMainPlot,'on')
box(handles.ValidationInset2,'on')
box(handles.ValidationInset1,'on')
linkaxes([handles.ValidationInset1,handles.ValidationMainPlot],'x')
linkaxes([handles.ValidationInset2,handles.ValidationMainPlot],'y')
drawnow
return

%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
%                            CHECK BOXES CALLBACKS
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function enableDisable_Edits(HandleBaseName,Status,handles)

%Get the handles of the Min,Max and Trials edit boxes
MinHandle = eval(['handles.',HandleBaseName,'_Min']);
MaxHandle = eval(['handles.',HandleBaseName,'_Max']);
TrialsHandle = eval(['handles.',HandleBaseName,'_Trials']);

%Enable /Disable them
set(MinHandle,'Enable',Status)
set(MaxHandle,'Enable',Status)
set(TrialsHandle,'Enable',Status)

return
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
% The following callbacks react to the check boxes for activating or deactivating
% the different validation parameters. They also update the total trials value
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
function BackgroundStart1_Check_Callback(hObject, eventdata, handles)

if get(hObject,'value')
  handles.NumberTrialsVector(1) = str2double(get(handles.BackgroundStart1_Trials,'string'));
  enableDisable_Edits('BackgroundStart1','on',handles)
else
  handles.NumberTrialsVector(1) = 1;
    enableDisable_Edits('BackgroundStart1','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundDimension1_Check_Callback(hObject, eventdata, handles)

if get(hObject,'value')
  handles.NumberTrialsVector(2) = str2double(get(handles.BackgroundDimension1_Trials,'string'));
    enableDisable_Edits('BackgroundDimension1','on',handles)
else
  enableDisable_Edits('BackgroundDimension1','off',handles)
    handles.NumberTrialsVector(2) = 1;
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundStart2_Check_Callback(hObject, eventdata, handles)

 if get(hObject,'value')
  handles.NumberTrialsVector(3) = str2double(get(handles.BackgroundStart2_Trials,'string'));
  enableDisable_Edits('BackgroundStart2','on',handles)
else
    handles.NumberTrialsVector(3) = 1;
    enableDisable_Edits('BackgroundStart2','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundDimension2_Check_Callback(hObject, eventdata, handles)

 if get(hObject,'value')
  handles.NumberTrialsVector(4) = str2double(get(handles.BackgroundDimension2_Trials,'string'));
    enableDisable_Edits('BackgroundDimension2','on',handles)
else
    handles.NumberTrialsVector(4) = 1;
    enableDisable_Edits('BackgroundDimension2','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function LagrangeMultiplier_Check_Callback(hObject, eventdata, handles)

if get(hObject,'value')
  handles.NumberTrialsVector(5) = str2double(get(handles.LagrangeMultiplier_Trials,'string'));
  enableDisable_Edits('LagrangeMultiplier','on',handles)
else
  handles.NumberTrialsVector(5) = 1;
  enableDisable_Edits('LagrangeMultiplier','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundParameter_Check_Callback(hObject, eventdata, handles)

 if get(hObject,'value')
  handles.NumberTrialsVector(6) = str2double(get(handles.BackgroundParameter_Trials,'string'));
  enableDisable_Edits('BackgroundParameter','on',handles)
else
    handles.NumberTrialsVector(6) = 1;
    enableDisable_Edits('BackgroundParameter','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function ThresholdParameter_Check_Callback(hObject, eventdata, handles)

 if get(hObject,'value')
  handles.NumberTrialsVector(7) = str2double(get(handles.ThresholdParameter_Trials,'string'));
      enableDisable_Edits('ThresholdParameter','on',handles)
else
    handles.NumberTrialsVector(7) = 1;
        enableDisable_Edits('ThresholdParameter','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SamplingDensity_Check_Callback(hObject, eventdata, handles)

if get(hObject,'value')
  handles.NumberTrialsVector(8) = str2double(get(handles.SamplingDensity_Trials,'string'));
  set(handles.SamplingDensity_Slider,'enable','on')
  set(handles.SamplingDensity_Trials,'enable','on')
  set(handles.SliderText,'enable','on')
else
  handles.NumberTrialsVector(8) = 1;
  set(handles.SamplingDensity_Slider,'enable','off')
  set(handles.SamplingDensity_Trials,'enable','off')
  set(handles.SliderText,'enable','off')
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function NoiseLevel_Check_Callback(hObject, eventdata, handles)
if get(hObject,'value')
  handles.NumberTrialsVector(9) = str2double(get(handles.NoiseLevel_Trials,'string'));
  enableDisable_Edits('NoiseLevel','on',handles)
else
  handles.NumberTrialsVector(9) = 1;
  enableDisable_Edits('NoiseLevel','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------


%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
%                            TRIALS EDITS CALLBACKS
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundStart1_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(1) = floor(str2double(get(hObject,'string')));
IntegerTrials = floor(handles.NumberTrialsVector(1));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundStart1_Max,'string'));
MinValue = str2double(get(handles.BackgroundStart1_Min,'string'));
PossibleIntegers = length(MinValue:1:MaxValue);
if IntegerTrials>PossibleIntegers
  handles.NumberTrialsVector(1) = PossibleIntegers;
  set(hObject,'string',PossibleIntegers);
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));

guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundDimension1_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(2) = floor(str2double(get(hObject,'string')));
IntegerTrials = floor(handles.NumberTrialsVector(2));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundDimension1_Max,'string'));
MinValue = str2double(get(handles.BackgroundDimension1_Min,'string'));
PossibleIntegers = length(MinValue:IntegerTrials:MaxValue);
if IntegerTrials>PossibleIntegers
  handles.NumberTrialsVector(2) = PossibleIntegers;
  set(hObject,'string',PossibleIntegers);
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundStart2_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(3) = floor(str2double(get(hObject,'string')));
IntegerTrials = floor(handles.NumberTrialsVector(3));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundStart2_Max,'string'));
MinValue = str2double(get(handles.BackgroundStart2_Min,'string'));
PossibleIntegers = length(MinValue:IntegerTrials:MaxValue);
if IntegerTrials>PossibleIntegers
  handles.NumberTrialsVector(3) = PossibleIntegers;
  set(hObject,'string',PossibleIntegers);
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundDimension2_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(4) = floor(str2double(get(hObject,'string')));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
IntegerTrials = floor(handles.NumberTrialsVector(4));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundDimension2_Max,'string'));
MinValue = str2double(get(handles.BackgroundDimension2_Min,'string'));
PossibleIntegers = length(MinValue:1:MaxValue);
if IntegerTrials>PossibleIntegers
  handles.NumberTrialsVector(4) = PossibleIntegers;
  set(hObject,'string',PossibleIntegers);
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function LagrangeMultiplier_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(5) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundParameter_Trials_Callback(hObject, eventdata, handles)

handles.NumberTrialsVector(6) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SamplingDensity_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(8) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function NoiseLevel_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(9) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
%------------------------------------------------------------------------------
%                            OTHER BUTTONS CALLBACKS
%------------------------------------------------------------------------------
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function ThresholdParameter_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(7) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function TotalTrials_CreateFcn(hObject, eventdata, handles)
handles.NumberTrialsVector = ones(9,1);
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function ZoomIn_Button_Callback(hObject, eventdata, handles)
zoom on
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function ZoomOut_Button_Callback(hObject, eventdata, handles)
zoom off
Upperlimit = 20;
% Upperlimit = str2double(get(handles.XUpperLimit,'string'));
set(handles.ValidationMainPlot,'xlim',[-Upperlimit Upperlimit],'ylim',[0 Upperlimit])

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function NextParameterSet_Button_Callback(hObject, eventdata, handles)
currentParameterSet = str2double(get(handles.SetParameterSet_Button,'string'));
if currentParameterSet < length(handles.ParameterSets)
  currentParameterSet = currentParameterSet + 1;
  set(handles.SetParameterSet_Button,'string',currentParameterSet)
  updateParameterSets(currentParameterSet,handles)
end
if get(handles.DisplayParameterSet_Radio,'value')
plotParameterSet(handles)
end
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function PreviousParameterSet_Button_Callback(hObject, eventdata, handles)
currentParameterSet = str2double(get(handles.SetParameterSet_Button,'string'));
if currentParameterSet > 1
  currentParameterSet = currentParameterSet - 1;
  set(handles.SetParameterSet_Button,'string',currentParameterSet)
  updateParameterSets(currentParameterSet,handles)
end
if get(handles.DisplayParameterSet_Radio,'value')
plotParameterSet(handles)
end
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SetParameterSet_Button_Callback(hObject, eventdata, handles)
currentParameterSet = str2double(get(hObject,'string'));
if currentParameterSet > length(handles.ParameterSets)
  currentParameterSet = length(handles.ParameterSets);
elseif currentParameterSet < 1
  currentParameterSet = 1;
end
updateParameterSets(currentParameterSet,handles)
if get(handles.DisplayParameterSet_Radio,'value')
plotParameterSet(handles)
end

%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayMean_Radio_Callback(hObject, eventdata, handles)
updateValidationPlots(handles)
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayParameterSet_Radio_Callback(hObject, eventdata, handles)
plotParameterSet(handles)
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function Validation_Button_Callback(hObject, eventdata, handles)
%------------------------------------------------------------------------------

%Get processing defaults
Defaults = handles.Defaults;

%Disable everything in the GUI during calculations
set(handles.SetParameterSet_Button,'enable','off')
set(handles.SetSelection_Text,'enable','off')
set(handles.RemoveSet_Button,'enable','off')
set(handles.PreviousParameterSet_Button,'enable','off')
set(handles.NextParameterSet_Button,'enable','off')
set(handles.TitleParameterSet_Text,'enable','off')
set(findall(handles.CurrentParameterSet_Panel, '-property', 'enable'), 'enable', 'off')
set(findall(handles.Display_Panel, '-property', 'enable'), 'enable', 'off')

% Construct the validation parameter vectors according the the GUI status
if get(handles.BackgroundStart1_Check,'value')
  BackgroundStart1_Min = str2double(get(handles.BackgroundStart1_Min,'string'));
  BackgroundStart1_Max = str2double(get(handles.BackgroundStart1_Max,'string'));
  BackgroundStart1_Trials = str2double(get(handles.BackgroundStart1_Trials,'string'));
  BackgroundStart1_Vector  = linspace(BackgroundStart1_Min,BackgroundStart1_Max,BackgroundStart1_Trials);
else
  BackgroundStart1_Vector = Defaults.BackgroundStart1;
end
if get(handles.BackgroundStart2_Check,'value')
  BackgroundStart2_Min = str2double(get(handles.BackgroundStart2_Min,'string'));
  BackgroundStart2_Max = str2double(get(handles.BackgroundStart2_Max,'string'));
  BackgroundStart2_Trials = str2double(get(handles.BackgroundStart2_Trials,'string'));
  BackgroundStart2_Vector  = linspace(BackgroundStart2_Min,BackgroundStart2_Max,BackgroundStart2_Trials);
else
  BackgroundStart2_Vector = Defaults.BackgroundStart2;
end
if get(handles.BackgroundDimension1_Check,'value')
  BackgroundDimension1_Min = str2double(get(handles.BackgroundDimension1_Min,'string'));
  BackgroundDimension1_Max = str2double(get(handles.BackgroundDimension1_Max,'string'));
  BackgroundDimension1_Trials = str2double(get(handles.BackgroundDimension1_Trials,'string'));
  BackgroundDimension1_Vector  = linspace(BackgroundDimension1_Min,BackgroundDimension1_Max,BackgroundDimension1_Trials);
  BackgroundDimension1_Vector = round(BackgroundDimension1_Vector);
else
  BackgroundDimension1_Vector = Defaults.BackgroundDimension1;
end
if get(handles.BackgroundDimension2_Check,'value')
  BackgroundDimension2_Min = str2double(get(handles.BackgroundDimension2_Min,'string'));
  BackgroundDimension2_Max = str2double(get(handles.BackgroundDimension2_Max,'string'));
  BackgroundDimension2_Trials = str2double(get(handles.BackgroundDimension2_Trials,'string'));
  BackgroundDimension2_Vector  = linspace(BackgroundDimension2_Min,BackgroundDimension2_Max,BackgroundDimension2_Trials);
  BackgroundDimension2_Vector = round(BackgroundDimension2_Vector);
else
  BackgroundDimension2_Vector = Defaults.BackgroundDimension2;
end
if get(handles.LagrangeMultiplier_Check,'value')
  LagrangeMultiplier_Min = str2double(get(handles.LagrangeMultiplier_Min,'string'));
  LagrangeMultiplier_Max = str2double(get(handles.LagrangeMultiplier_Max,'string'));
  LagrangeMultiplier_Trials = str2double(get(handles.LagrangeMultiplier_Trials,'string'));
  LagrangeMultiplier_Vector  = linspace(LagrangeMultiplier_Min,LagrangeMultiplier_Max,LagrangeMultiplier_Trials);
else
  LagrangeMultiplier_Vector = Defaults.LagrangeMultiplier;
end
if get(handles.BackgroundParameter_Check,'value')
  BackgroundParameter_Min = str2double(get(handles.BackgroundParameter_Min,'string'));
  BackgroundParameter_Max = str2double(get(handles.BackgroundParameter_Max,'string'));
  BackgroundParameter_Trials = str2double(get(handles.BackgroundParameter_Trials,'string'));
  BackgroundParameter_Vector  = linspace(BackgroundParameter_Min,BackgroundParameter_Max,BackgroundParameter_Trials);
else
  BackgroundParameter_Vector = Defaults.BackgroundParameter;
end
if get(handles.ThresholdParameter_Check,'value')
  ThresholdParameter_Min = str2double(get(handles.ThresholdParameter_Min,'string'));
  ThresholdParameter_Max = str2double(get(handles.ThresholdParameter_Max,'string'));
  ThresholdParameter_Trials = str2double(get(handles.ThresholdParameter_Trials,'string'));
  ThresholdParameter_Vector  = linspace(ThresholdParameter_Min,ThresholdParameter_Max,ThresholdParameter_Trials);
else
  ThresholdParameter_Vector = Defaults.ThresholdParameter;
end
if get(handles.SamplingDensity_Check,'value')
  SamplingDensity = get(handles.SamplingDensity_Slider,'value');
  SamplingDensity_Trials = str2double(get(handles.SamplingDensity_Trials,'string'));
  SamplingDensity_Vector  = [SamplingDensity,SamplingDensity_Trials];
else
  if handles.RawData.NUSflag
  SamplingDensity_Vector = [handles.RawData.NUS.SamplingDensity 1];
  else
    SamplingDensity_Vector = [1 1];
  end
end
if get(handles.NoiseLevel_Check,'value')
  NoiseLevel_Min = str2double(get(handles.NoiseLevel_Min,'string'));
  NoiseLevel_Max = str2double(get(handles.NoiseLevel_Max,'string'));
  NoiseLevel_Trials = str2double(get(handles.NoiseLevel_Trials,'string'));
  NoiseLevel_Vector  = linspace(NoiseLevel_Min,NoiseLevel_Max,NoiseLevel_Trials);
else
  NoiseLevel_Vector = 0;
end

%Put all vectors into one structure
ValidationVectors.BackgroundStart1_Vector = BackgroundStart1_Vector;
ValidationVectors.BackgroundStart2_Vector = BackgroundStart2_Vector;
ValidationVectors.BackgroundDimension1_Vector = BackgroundDimension1_Vector;
ValidationVectors.BackgroundDimension2_Vector = BackgroundDimension2_Vector;
ValidationVectors.LagrangeMultiplier_Vector = LagrangeMultiplier_Vector;
ValidationVectors.BackgroundParameter_Vector = BackgroundParameter_Vector;
ValidationVectors.ThresholdParameter_Vector = ThresholdParameter_Vector;
ValidationVectors.SamplingDensity_Vector  = SamplingDensity_Vector;
ValidationVectors.NoiseLevel_Vector  = NoiseLevel_Vector;

%Inform that validation starts
set(handles.ValidationStatus,'string','Validation in progress...'),drawnow;

%Launch validation protocol
[ReconstructedSpectra,ParameterSets] = validateHyscorean(handles.RawData,ValidationVectors,handles.ValidationStatus,Defaults);

%Save results to handles structure
handles.ParameterSets = ParameterSets;
handles.ReconstructedSpectra = ReconstructedSpectra;
handles.ValidationVectors = ValidationVectors;

%Update the GUI display
set(handles.DisplayMean_Radio,'Value',1);
updateValidationPlots(handles)
%Update the parameter sets for the parameter table
updateParameterSets(1,handles)

%Re-activate everyhting in the GUI 
set(handles.ZoomOut_Button,'visible','on')
set(handles.ZoomIn_Button,'visible','on')
set(handles.DetachPlot_Button,'visible','on')
set(handles.SetParameterSet_Button,'enable','on')
set(handles.PreviousParameterSet_Button,'enable','on')
set(handles.NextParameterSet_Button,'enable','on')
set(handles.TitleParameterSet_Text,'enable','on')
set(handles.RemoveSet_Button,'enable','on')
set(handles.SetSelection_Text,'enable','on')
set(findall(handles.CurrentParameterSet_Panel, '-property', 'enable'), 'enable', 'on')
set(findall(handles.Display_Panel, '-property', 'enable'), 'enable', 'on')
set(handles.SaveValidation_Button, 'enable', 'on')

%Save handles and return
guidata(hObject, handles);

return

%------------------------------------------------------------------------------
function updateValidationPlots(handles)

%Get all spectra generated during validation
ReconstructedSpectra = handles.ReconstructedSpectra;

%Inform that rendering is under progress
set(handles.ValidationStatus,'string','Rendering...'),drawnow;

%Compute the statistical results accorsing to the two-sigma rule of the 68-95-99.7 rule
MeanReconstruction = mean(ReconstructedSpectra,3);
MeanReconstruction = MeanReconstruction/max(max(MeanReconstruction));
Uncertainty = std(ReconstructedSpectra,0,3);
LowerBound = MeanReconstruction - 2*Uncertainty;
UpperBound = MeanReconstruction + 2*Uncertainty;

%Get dimensions of zero-filled signal
Dimension1 = size(MeanReconstruction,1);
Dimension2 = size(MeanReconstruction,2);

TimeAxis1 = handles.RawData.TimeAxis1;
TimeAxis2 = handles.RawData.TimeAxis2;
TimeStep1 = TimeAxis1(end)/length(TimeAxis1);
TimeStep2 = TimeAxis2(end)/length(TimeAxis2);

%Construct frequency axis
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),Dimension1);
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),Dimension2);

%Account for zero-filling size
Dimension1 = Dimension1 - handles.Defaults.ZeroFilling1;
Dimension2 = Dimension2 - handles.Defaults.ZeroFilling2;

%Get Hyscorean path
HyscoreanPath = which('Hyscorean');
HyscoreanPath = HyscoreanPath(1:end-11);

%Load custom modified hot colormap
CustomColormap = load(fullfile(HyscoreanPath,'bin', 'RedWhiteColorMap_old.mat'));
CustomColormap = CustomColormap.mycmap;
CustomColormap = fliplr(CustomColormap(1:end-2,:)')';
CustomColormap(1,:) = [1 1 1];
% CustomColormap(2,:) = [1 1 1];
% CustomColormap(3,:) = [1 1 1];

% CustomColormap(:,1) = 1;
% CustomColormap(:,2) = 0;
% CustomColormap(:,3) = 0;

%Clear current display in axes
cla(handles.ValidationMainPlot)

%Get graphical settings
Defaults = handles.Defaults;
ContourLevels  = Defaults.Levels;

%Compute contour levels
minContourLevel = min(min(Defaults.MinimalContourLevel/100*abs((MeanReconstruction))));
maxContourLevel = max(max(Defaults.MaximalContourLevel/100*abs((MeanReconstruction))));
ContourLevels = linspace(minContourLevel,maxContourLevel,ContourLevels);

%Select the validation results chosen by the user to display
switch handles.DisplayRadioStatus
  case 'lower'
    Display = max(LowerBound,0);
    colormap(handles.ValidationMainPlot,CustomColormap)
  case 'upper'
    Display = UpperBound;
    colormap(handles.ValidationMainPlot,CustomColormap)
  case 'uncertainty'
    if get(handles.superimpose_Check,'value')
    Display = Uncertainty;
    else
    Display = MeanReconstruction;
    end
end

%Configure axis
set(handles.ValidationMainPlot,'YLim',[0 Defaults.XUpperLimit],'XLim',[-Defaults.XUpperLimit Defaults.XUpperLimit])
grid(handles.ValidationMainPlot,'on')
xlabel(handles.ValidationMainPlot,'\nu_1 [MHz]'),ylabel(handles.ValidationMainPlot,'\nu_2 [MHz]')
hold(handles.ValidationMainPlot,'on')
ticks = xticks(handles.ValidationMainPlot);
set(handles.ValidationMainPlot,'ytick',ticks)
set(handles.ValidationMainPlot,'FontSize',13)

if get(handles.superimpose_Check,'value')

%Display mean validation spectrum as black contour plot with custom contour levels
contour(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,abs((MeanReconstruction)),ContourLevels,'k','LineWidth',1)
colormap(handles.ValidationMainPlot,'jet')

% h = surf(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,ZDisplacement+Display);
h = pcolor(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,Display);

% caxis(handles.ValidationMainPlot,[min(min(ZDisplacement+Display)),max(max(ZDisplacement+Display))])% 
% h.AlphaData  = Display*0 + 0.7;
h.FaceAlpha  = 0.65;
% cmp = cbrewer('div','RdBu',2*Defaults.Levels);
% cmp = flipud(cmp(1:size(cmp,1)/2,:));
% cmp(1,:) = [1 1 1];
colormap(handles.ValidationMainPlot,CustomColormap)
% rotate3d(handles.ValidationMainPlot,'on')
% rotate3d(new_handle,'on')

%Further configure the axes
grid(handles.ValidationMainPlot,'on')
shading(handles.ValidationMainPlot,'interp')
caxis(handles.ValidationMainPlot,[0 max(max(abs(MeanReconstruction)))])
% handles.Link = linkprop([handles.ValidationMainPlot,new_handle],{'CameraUpVector', 'CameraPosition', 'CameraTarget', 'XLim', 'YLim', 'ZLim'});
% new_handle.Visible = 'off';
% handles.ValidationMainPlot = 'off';

% zlim(new_handle,[min(min(ZDisplacement+Display)) max(max(max(ZDisplacement+Display)),0)])
% uistack(handles.ValidationMainPlot,'top')
% new_handle.Tag = 'GhostAxis';
else
 
% Display = Display/max(max(Display));
contour(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,abs((Display)),ContourLevels,'LineWidth',1)
colormap(handles.ValidationMainPlot,'parula')
  
end

hold(handles.ValidationMainPlot,'off')

%Clear the upper inset
cla(handles.ValidationInset1)

QuadrantCutoff = round(length(FrequencyAxis1)/2);

if get(handles.superimpose_Check,'value')
  %Get projection of mean spectrum
  MeanInset = max(MeanReconstruction(:,QuadrantCutoff:end),[],2)';
  plot(handles.ValidationInset1,FrequencyAxis1,MeanInset,'k')
  hold(handles.ValidationInset1,'on')
  Color = 'r';
else
  Color = 'k';
end
%Get projection of validation result
switch handles.DisplayRadioStatus
  case 'uncertainty'
    if get(handles.superimpose_Check,'value')
    Upper = abs(MeanReconstruction(QuadrantCutoff:end,:)) + 2*abs(Uncertainty(QuadrantCutoff:end,:));
    Lower = MeanReconstruction(QuadrantCutoff:end,:) - 2*abs(Uncertainty(QuadrantCutoff:end,:));
    LowerInset =  max(Lower/max(max(Lower)));
    UpperInset =  max(Upper/max(max(Upper)));
    a1 = fill(handles.ValidationInset1,[FrequencyAxis1 fliplr(FrequencyAxis1)], [ LowerInset  fliplr(MeanInset) ], 'r','LineStyle','none');
    a2 = fill(handles.ValidationInset1,[FrequencyAxis1 fliplr(FrequencyAxis1)], [ MeanInset fliplr(UpperInset)  ], 'r','LineStyle','none');
    a1.FaceAlpha = 0.5;
    a2.FaceAlpha = 0.5;
    else
      Inset = MeanReconstruction(QuadrantCutoff:end,:);
%       Inset =  max(Inset/max(max(Inset)));
      Inset =  max(Inset);
      plot(handles.ValidationInset1,FrequencyAxis1,Inset,Color,'LineWidth',1)
    end
  case 'upper'
    Upper = UpperBound(QuadrantCutoff:end,:);
%     UpperInset =  max(Upper/max(max(Upper)));
    UpperInset =  max(Upper);
    plot(handles.ValidationInset1,FrequencyAxis1,UpperInset,Color,'LineWidth',1)
  case 'lower'
    Lower = LowerBound(QuadrantCutoff:end,:);
%     LowerInset =  max(Lower/max(max(Lower)));
    LowerInset =   max(Lower);
    plot(handles.ValidationInset1,FrequencyAxis1,LowerInset,Color,'LineWidth',1)
end
%Configure the inset axes
set(handles.ValidationInset1,'XLim',[-Defaults.XUpperLimit Defaults.XUpperLimit])
set(handles.ValidationInset1,'YLim',[0 1])
set(handles.ValidationInset1,'XTick',[],'YTick',[])
hold(handles.ValidationInset2,'off')

%Clear the side inset
cla(handles.ValidationInset2)

if get(handles.superimpose_Check,'value')
  %Get projection of mean spectrum
  MeanInset = max(MeanReconstruction);
  plot(handles.ValidationInset2,MeanInset,FrequencyAxis1,'k')
  hold(handles.ValidationInset2,'on')
  Color = 'r';
else
  Color = 'k';
end

%Get projection of validation result
switch handles.DisplayRadioStatus
  case 'uncertainty'
    if get(handles.superimpose_Check,'value')
      Upper = MeanReconstruction + 2*Uncertainty;
      Lower = MeanReconstruction - 2*Uncertainty;
      LowerInset =  max(Lower/max(max(Lower)));
      UpperInset =  max(Upper/max(max(Upper)));
      a1 = fill(handles.ValidationInset2, [LowerInset  fliplr(MeanInset)],[FrequencyAxis1 fliplr(FrequencyAxis1)], 'r','LineStyle','none');
      a2 = fill(handles.ValidationInset2, [MeanInset fliplr(UpperInset)],[FrequencyAxis1 fliplr(FrequencyAxis1)], 'r','LineStyle','none');
      a1.FaceAlpha = 0.5;
      a2.FaceAlpha = 0.5;
    else
      Inset = MeanReconstruction;
%       Inset =  max(Inset/max(max(Inset)));
      Inset =  max(Inset);
      plot(handles.ValidationInset2,Inset,FrequencyAxis1,Color,'LineWidth',1)
    end
  case 'upper'
    Upper = UpperBound;
%     UpperInset =  max(Upper/max(max(Upper)));
    UpperInset =  max(Upper);
    plot(handles.ValidationInset2,UpperInset,FrequencyAxis1,Color,'LineWidth',1)
  case 'lower'
    Lower = LowerBound;
%     LowerInset =  max(Lower/max(max(Lower)));
    LowerInset =   max(Lower);
    plot(handles.ValidationInset2,LowerInset,FrequencyAxis1,Color,'LineWidth',1)
end
%Configure the inset axes
set(handles.ValidationInset2,'YLim',[0 Defaults.XUpperLimit])
set(handles.ValidationInset2,'XLim',[0 1])
set(handles.ValidationInset2,'XTick',[],'YTick',[])
hold(handles.ValidationInset2,'off')

%Inform user that the graphics are rendered
set(handles.ValidationStatus,'string','Ready'),drawnow;

guidata(handles.ValidationMainPlot, handles);

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function updateParameterSets(currentParameterSet,handles)

%Get parameter sets
ParameterSets = handles.ParameterSets;
set(handles.SetParameterSet_Button,'string',currentParameterSet)
set(handles.CurrentParameterSet_Panel,'title',sprintf('Parameter Set #%i',currentParameterSet))
%Update the text boxes of the table in the GUI
set(handles.CurrentBackgroundStart1_Text,'string',ParameterSets(currentParameterSet).BackgroundStart1);
set(handles.CurrentBackgroundStart2_Text,'string',ParameterSets(currentParameterSet).BackgroundStart2);
set(handles.CurrentBackgroundDimension1_Text,'string',ParameterSets(currentParameterSet).BackgroundDimension1);
set(handles.CurrentBackgroundDimension2_Text,'string',ParameterSets(currentParameterSet).BackgroundDimension2);
%For the NUS reconstruction parameters, if not NUS then just set to '-'
if ~isnan(ParameterSets(currentParameterSet).LagrangeMultiplier)
  set(handles.CurrentLagrangianMultiplier_Text,'string',ParameterSets(currentParameterSet).LagrangeMultiplier);
else
  set(handles.CurrentLagrangianMultiplier_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).BackgroundParameter)
  set(handles.CurrentBackgroundParameter_Text,'string',ParameterSets(currentParameterSet).BackgroundParameter);
else
  set(handles.CurrentBackgroundParameter_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).ThresholdParameter)
  set(handles.CurrentThresholdParameter_Text,'string',ParameterSets(currentParameterSet).ThresholdParameter);
else
  set(handles.CurrentThresholdParameter_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).SamplingDensity)
  set(handles.CurrentSamplingDensity_Text,'string',ParameterSets(currentParameterSet).SamplingDensity);
else
  set(handles.CurrentSamplingDensity_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).Entropy)
  set(handles.CurrentEntropy_Text,'string',ParameterSets(currentParameterSet).Entropy);
else
  set(handles.CurrentEntropy_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).RMSD)
  set(handles.CurrentRMSD_Text,'string',ParameterSets(currentParameterSet).RMSD);
else
  set(handles.CurrentRMSD_Text,'string','-');
end
if ~isnan(ParameterSets(currentParameterSet).NoiseLevel)
  set(handles.CurrentNoiseLevel_Text,'string',ParameterSets(currentParameterSet).NoiseLevel);
else
  set(handles.CurrentNoiseLevel_Text,'string','-');
end

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function plotParameterSet(handles)

%Inform user that graphics are being rendering
set(handles.ValidationStatus,'string','Rendering'),drawnow;

%Get the parameter set index to be displayed
CurrentParameterSet = str2double(get(handles.SetParameterSet_Button,'string'));
ValidationSpectra = handles.ReconstructedSpectra;
CurrentSpectrum =  ValidationSpectra(:,:,CurrentParameterSet);
Defaults = handles.Defaults;

%Construct frequency axis
Dimension1 = size(CurrentSpectrum,1);
Dimension2 = size(CurrentSpectrum,2);
TimeAxis1 = handles.RawData.TimeAxis1;
TimeAxis2 = handles.RawData.TimeAxis2;
TimeStep1 = TimeAxis1(end)/length(TimeAxis1);
TimeStep2 = TimeAxis2(end)/length(TimeAxis2);
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),Dimension1);
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),Dimension2);

%Set the main display
cla(handles.ValidationMainPlot)
contour(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,abs((CurrentSpectrum)),80,'LineWidth',1)
set(handles.ValidationMainPlot,'YLim',[0 Defaults.XUpperLimit],'XLim',[-Defaults.XUpperLimit Defaults.XUpperLimit])
grid(handles.ValidationMainPlot,'on')
xlabel(handles.ValidationMainPlot,'\nu_1 [MHz]'),ylabel(handles.ValidationMainPlot,'\nu_2 [MHz]')
colormap(handles.ValidationMainPlot,'parula')
ticks = xticks(handles.ValidationMainPlot);
set(handles.ValidationMainPlot,'ytick',ticks)
set(handles.ValidationMainPlot,'FontSize',13)

%Set the upper inset
cla(handles.ValidationInset1)
MeanInset = max(CurrentSpectrum(:,round(Dimension1/2):end),[],2);
plot(handles.ValidationInset1,FrequencyAxis1,MeanInset,'k')
set(handles.ValidationInset1,'XLim',[-Defaults.XUpperLimit Defaults.XUpperLimit])
set(handles.ValidationInset1,'XTick',[],'YTick',[])

%Set the side inset
cla(handles.ValidationInset2)
MeanInset = max(CurrentSpectrum);
plot(handles.ValidationInset2,MeanInset,FrequencyAxis1,'k')
set(handles.ValidationInset2,'YLim',[0 Defaults.XUpperLimit])
set(handles.ValidationInset2,'XTick',[],'YTick',[])

%Inform user that graphics are rendered
set(handles.ValidationStatus,'string','Ready'),drawnow;

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function Min_Edits_Callback(hObject, eventdata, handles)

%Get the tag of the object sent to this function
Tag = get(hObject,'Tag');
%Append 'max' to the tag
Tag = [Tag(1:end-3) 'Max'];
%Get the handles of the min and max edit boxes
Min_EditHandle = hObject;
Max_EditHandle = findobj('Tag',Tag);
%Get the values
MaxValue = str2double(get(Max_EditHandle,'string'));
MinValue = str2double(get(Min_EditHandle,'string'));
%Check that the given min is smaller than the max
if MinValue>MaxValue
  set(Max_EditHandle,'string',MinValue);
  set(Min_EditHandle,'string',MaxValue);
end

guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function Max_Edits_Callback(hObject, eventdata, handles)

%Get the tag of the object sent to this function
Tag = get(hObject,'Tag');
%Append 'min' to the tag
Tag = [Tag(1:end-3) 'Min'];
%Get the handles of the min and max edit boxes
Max_EditHandle = hObject;
Min_EditHandle = findobj('Tag',Tag);
%Get the values
MaxValue = str2double(get(Max_EditHandle,'string'));
MinValue = str2double(get(Min_EditHandle,'string'));
%Check that the given max is smaller than the min
if MinValue>MaxValue
  set(Max_EditHandle,'string',MinValue);
  set(Min_EditHandle,'string',MaxValue);
end

guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function RemoveSet_Button_Callback(hObject, eventdata, handles)

%Get current parameter set value
CurrentSet = str2double(get(handles.SetParameterSet_Button,'string'));

%Remove the current parameter set
handles.ParameterSets(CurrentSet) = [];
handles.ReconstructedSpectra(:,:,CurrentSet) =[];
CurrentSet = CurrentSet -1;

%Check that the new current value is not exceeding
if CurrentSet > length(handles.ParameterSets)
  CurrentSet = length(handles.ParameterSets);
elseif CurrentSet < 1
  CurrentSet = 1;
end
updateParameterSets(CurrentSet,handles)

%Update the corresponding plot
if get(handles.DisplayMean_Radio,'value')
updateValidationPlots(handles)
else
  plotParameterSet(handles)
end

guidata(hObject, handles);
return
%------------------------------------------------------------------------------


%------------------------------------------------------------------------------
function DetachPlot_Button_Callback(hObject, eventdata, handles)

%Check if window is open, close and make new one
FigureHandle = findobj('Tag','validationResultsDetached');
if isempty(FigureHandle)
  FigureHandle = figure('Tag','validationResultsDetached','WindowStyle','normal');
else
  figure(FigureHandle);
  clf(FigureHandle);
end

%Set the figure and axis position and size
set(FigureHandle,'Position',[-1364 463 997 623])
ExternalHandles.ValidationMainPlot = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.12 0.7 0.6]);
box(ExternalHandles.ValidationMainPlot,'on');
ExternalHandles.ValidationInset1 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.75 0.7 0.2]);
ExternalHandles.ValidationInset2 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.8 0.12 0.15 0.6]);
ExternalHandles.ValidationStatus = uicontrol('Parent',FigureHandle,'Style','text','Visible','off','Position',[0.8 0.12 0.15 0.6]);

%Get GUI status and variables
ExternalHandles.ReconstructedSpectra = handles.ReconstructedSpectra;
ExternalHandles.DisplayRadioStatus = handles.DisplayRadioStatus;
ExternalHandles.SetParameterSet_Button = handles.SetParameterSet_Button;
ExternalHandles.RawData = handles.RawData;
ExternalHandles.Defaults = handles.Defaults;
ExternalHandles.superimpose_Check = handles.superimpose_Check;

%Update the graphics in the detached figure
if get(handles.DisplayMean_Radio,'value')
  updateValidationPlots(ExternalHandles)
else
  plotParameterSet(ExternalHandles)
end

 return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayUpperBound_Radio_Callback(hObject, eventdata, handles)
handles.DisplayRadioStatus = 'upper';
updateValidationPlots(handles)
guidata(hObject, handles);
 return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayUncertainty_Radio_Callback(hObject, eventdata, handles)
handles.DisplayRadioStatus = 'uncertainty';
updateValidationPlots(handles)
guidata(hObject, handles);
 return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayLowerBound_Radio_Callback(hObject, eventdata, handles)
handles.DisplayRadioStatus = 'lower';
updateValidationPlots(handles)
guidata(hObject, handles);
 return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function DisplayUncertainty_Radio_CreateFcn(hObject, eventdata, handles)
handles.DisplayRadioStatus = 'uncertainty';
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SamplingDensity_Slider_Callback(hObject, eventdata, handles)
CurrentSliderValue = get(hObject,'Value');
String = sprintf('%.1f%%',CurrentSliderValue);
set(handles.SliderText,'string',String);
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SaveValidation_Button_Callback(hObject, eventdata, handles)

%First ask user where to save the validation data
[SaveName,SavePath] = uiputfile('*.*','Save validation as');
%If cancelled, return
if SaveName == 0
  return
end

f = msgbox('Saving validation session. Please wait...','modal');
delete(f.Children(1))
drawnow

% Prepare saving procedures
DateFormatOut = 'yyyymmdd';
Date = datestr(date,DateFormatOut);
%Set identifier
Identifier = SaveName;
%Get file path
FullPath = fullfile(SavePath);
CrashFlag = false;

%Construct a structure with the input parameters
ValidationParameters  = handles.ValidationVectors;
RawData = handles.RawData;
Defaults = handles.Defaults;
ReconstructedSpectra = handles.ReconstructedSpectra;

%Get the validation statistics results
MeanReconstruction = mean(ReconstructedSpectra,3);
MeanReconstruction = MeanReconstruction/max(max(MeanReconstruction));
Uncertainty = std(ReconstructedSpectra,0,3);

Properties = whos('ReconstructedSpectra');
ExpectedFileSize = Properties.bytes/1e9;

if ExpectedFileSize>1
    Answer = questdlg(sprintf('The data file size to be exported is %.2f GB. Do you still want to export it? ',ExpectedFileSize), ...
	'Large data export', 'Yes','No','No');
else
  Answer = 'Yes';
end
 
%Save them to an output structure
ValidationResults.ParameterSets = handles.ParameterSets;
for i=1:length(ValidationResults.ParameterSets)
  SamplingDensities(i) = ValidationResults.ParameterSets(i).SamplingDensity;
end
if ~handles.RawData.NUSflag
  ValidationParameters.SamplingDensity_Vector = 100;
else
  ValidationParameters.SamplingDensity_Vector = unique(SamplingDensities);
end
ValidationResults.Uncertainty = Uncertainty;
ValidationResults.LowerBound = MeanReconstruction - 2*Uncertainty;
ValidationResults.MeanSpectrum = MeanReconstruction;
ValidationResults.UpperBound = MeanReconstruction + 2*Uncertainty;
ValidationResults.ValidationSpectra = handles.ReconstructedSpectra;
ValidationResults.ValidationParameters = ValidationParameters;
%Construct frequency axis
Dimension1 = size(MeanReconstruction,1);
Dimension2 = size(MeanReconstruction,2);
TimeAxis1 = handles.RawData.TimeAxis1;
TimeAxis2 = handles.RawData.TimeAxis2;
TimeStep1 = TimeAxis1(end)/(1/2*Dimension1);
TimeStep2 = TimeAxis2(end)/(1/2*Dimension2);
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),Dimension1);
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),Dimension2);
ValidationResults.FrequencyAxis1 = FrequencyAxis1;
ValidationResults.FrequencyAxis2 = FrequencyAxis2;

if strcmp(Answer,'Yes')
%Format savename until it is different from the rest in the folder
SaveName = sprintf('%s_%s_ValidationData.mat',Date,Identifier);
CopyIndex = 1;
while true
  %If name is different stop
  if ~exist(fullfile(FullPath,SaveName),'file')
    break
  end
  %Otherwise just increase the counter number and add to name
  CopyIndex = CopyIndex + 1;
  CrashFlag = true;
  SaveName = sprintf('%s_%s_ValidationData_%i.mat',Date,Identifier,CopyIndex);
end

%Save settings to file
save(fullfile(FullPath,SaveName),'ValidationResults');
end

%Update the graphics in the detached figure
ExternalHandles.ReconstructedSpectra = ReconstructedSpectra;
ExternalHandles.RawData = RawData;
ExternalHandles.Defaults = Defaults;

%Check if window is open, close and make new one
FigureHandle = figure('Tag','windowBeingSaved','Visible','off','WindowStyle','normal');
%Define a create function for ghost figure, so that when it is later opened by user, it dislplays normally
set(FigureHandle,'CreateFcn','set(gcbf,''Visible'',''on'')');
%Set the figure and axis position and size
set(FigureHandle,'Position',[-1364 463 997 623])
ExternalHandles.ValidationMainPlot = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.12 0.7 0.6]);
ExternalHandles.ValidationInset1 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.75 0.7 0.2]);
ExternalHandles.ValidationInset2 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.8 0.12 0.15 0.6]);
ExternalHandles.ValidationStatus = uicontrol('Parent',FigureHandle,'Style','text','Visible','off','Position',[0.8 0.12 0.15 0.6]);
ExternalHandles.superimpose_Check = handles.superimpose_Check;
%Plot uncertainty and save
ExternalHandles.DisplayRadioStatus = 'uncertainty';
updateValidationPlots(ExternalHandles)
%Use the same formatting in name as before to avoid filename clash
if ExternalHandles.superimpose_Check
  SaveName = sprintf('%s_%s_Uncertainty',Date,Identifier);
  if CrashFlag
    SaveName = sprintf('%s_%s_Uncertainty_%i',Date,Identifier,CopyIndex);
  end
else
  SaveName = sprintf('%s_%s_Mean',Date,Identifier);
  if CrashFlag
    SaveName = sprintf('%s_%s_Mean_%i',Date,Identifier,CopyIndex);
  end
end
%Save as Matlab figure (.fig)
savefig(FigureHandle,fullfile(FullPath,[SaveName '.fig']), 'compact');

%Clear the figure axes
cla(ExternalHandles.ValidationMainPlot)
cla(ExternalHandles.ValidationInset1)
cla(ExternalHandles.ValidationInset2)

%Plot lower bound and save
ExternalHandles.DisplayRadioStatus = 'lower';
updateValidationPlots(ExternalHandles)
%Use the same formatting in name as before to avoid filename clash
  SaveName = sprintf('%s_%s_LowerBound',Date,Identifier);  
  if CrashFlag
      SaveName = sprintf('%s_%s_LowerBound_%i',Date,Identifier,CopyIndex);
  end
%Save as Matlab figure (.fig)
savefig(FigureHandle,fullfile(FullPath,[SaveName '.fig']), 'compact');

%Clear the figure axes
cla(ExternalHandles.ValidationMainPlot)
cla(ExternalHandles.ValidationInset1)
cla(ExternalHandles.ValidationInset2)

%Plot upper bound and save
ExternalHandles.DisplayRadioStatus = 'upper';
updateValidationPlots(ExternalHandles)
%Use the same formatting in name as before to avoid filename clash
  SaveName = sprintf('%s_%s_UpperBound',Date,Identifier);  
  if CrashFlag
      SaveName = sprintf('%s_%s_UpperBound_%i',Date,Identifier,CopyIndex);
  end
%Save as Matlab figure (.fig)
savefig(FigureHandle,fullfile(FullPath,[SaveName '.fig']), 'compact');

close(FigureHandle)

%Check if license exists and continue if so
if getpref('hyscorean','reportlicense')
  
  %Construct report data structure
  ReportData.ValidationParametersFields = fields(ValidationParameters);
  ReportData.ValidationParameters = ValidationParameters;
  ReportData.Defaults = Defaults;
  ReportData.RawData = RawData;
  ReportData.ReconstructedSpectra = ReconstructedSpectra;
  ReportData.MeanReconstruction = MeanReconstruction;
  ReportData.Uncertainty = ValidationResults.Uncertainty;
  ReportData.LowerBound = ValidationResults.LowerBound;
  ReportData.UpperBound = ValidationResults.UpperBound;
  ReportData.UpdateValidationPlotHandle = @updateValidationPlots;
  %Use the same formatting in name as before to avoid filename clash
  ReportName = sprintf('%s_%s_ValidationReport',Date,Identifier);
  if CrashFlag
    ReportName = sprintf('%s_%s_ValidationReport_%i',Date,Identifier,CopyIndex);
  end
  ReportData.SaveName = ReportName;
  ReportData.SavePath = FullPath;
  
  %Get the location of the processing report logo
  HyscoreanPath = fileparts(which('Hyscorean'));
  ReportData.ValidationReport_logo_Path = fullfile(HyscoreanPath,'bin','ValidationReport_logo.png');
  
  %Send structure to workspace
  assignin('base', 'ReportData', ReportData);
  
  %Generate report
  report Hyscorean_Validation_report -fpdf ;
  
  evalin('base','clear ReportData')
  
else
  warning('MATLAB report generator not installed or license not found. Report generation was skipped.')
end

close(f)

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function superimpose_Check_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
  set(handles.DisplayUncertainty_Radio,'String','Uncertainty')
else
  set(handles.DisplayUncertainty_Radio,'String','Mean')
end

updateValidationPlots(handles)
guidata(hObject, handles);
return
%------------------------------------------------------------------------------
