function varargout = Hyscorean_validationModule(varargin)
% HYSCOREAN_VALIDATIONMODULE MATLAB code for Hyscorean_validationModule.fig
%      HYSCOREAN_VALIDATIONMODULE, by itself, creates a new HYSCOREAN_VALIDATIONMODULE or raises the existing
%      singleton*.
%
%      H = HYSCOREAN_VALIDATIONMODULE returns the handle to a new HYSCOREAN_VALIDATIONMODULE or the handle to
%      the existing singleton*.
%
%      HYSCOREAN_VALIDATIONMODULE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HYSCOREAN_VALIDATIONMODULE.M with the given input arguments.
%
%      HYSCOREAN_VALIDATIONMODULE('Property','Value',...) creates a new HYSCOREAN_VALIDATIONMODULE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Hyscorean_validationModule_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Hyscorean_validationModule_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Hyscorean_validationModule

% Last Modified by GUIDE v2.5 13-Dec-2018 11:38:20

% Begin initialization code - DO NOT EDIT
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
% End initialization code - DO NOT EDIT


% --- Executes just before Hyscorean_validationModule is made visible.
function Hyscorean_validationModule_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Hyscorean_validationModule (see VARARGIN)

% Choose default command line output for Hyscorean_validationModule
handles.output = hObject;
handles.RawData = varargin{1};
handles.Defaults = varargin{2};

%Prepare the sampling density slider 
handles.RawData.NUS.SamplingDensity = length(find(handles.RawData.NUS.SamplingGrid ==1))/(handles.RawData.NUS.Dimension1*handles.RawData.NUS.Dimension2);
Npoints  = length(1:0.1:100*handles.RawData.NUS.SamplingDensity );
set(handles.SamplingDensity_Slider,'Min', 1, 'Max',100*handles.RawData.NUS.SamplingDensity  , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 100*handles.RawData.NUS.SamplingDensity )
String = sprintf('%.1f%%',100*handles.RawData.NUS.SamplingDensity );
set(handles.SliderText,'string',String);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Hyscorean_validationModule wait for user response (see UIREprodE)
% uiwait(handles.figure1);


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

function enableDisable_Edits(HandleBaseName,Status,handles)

MinHandle = eval(['handles.',HandleBaseName,'_Min']);
MaxHandle = eval(['handles.',HandleBaseName,'_Max']);
TrialsHandle = eval(['handles.',HandleBaseName,'_Trials']);

set(MinHandle,'Enable',Status)
set(MaxHandle,'Enable',Status)
set(TrialsHandle,'Enable',Status)

return

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
      enableDisable_Edits('BackgroundParameter','off',handles)
else
    handles.NumberTrialsVector(7) = 1;
        enableDisable_Edits('BackgroundParameter','off',handles)
end
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
guidata(hObject, handles);
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SamplingDensity_Check_Callback(hObject, eventdata, handles)
 if get(hObject,'value')
  handles.NumberTrialsVector(8) = str2double(get(handles.SamplingDensity_Trials,'string'));
else
    handles.NumberTrialsVector(8) = 1;
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
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundStart1_Max,'string'));
MinValue = str2double(get(handles.BackgroundStart1_Min,'string'));
PossibleIntegers = length(MinValue:1:MaxValue);
if IntegerTrials>PossibleIntegers
set(hObject,'string',PossibleIntegers);
end
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundDimension1_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(2) = floor(str2double(get(hObject,'string')));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
IntegerTrials = floor(handles.NumberTrialsVector(2));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundDimension1_Max,'string'));
MinValue = str2double(get(handles.BackgroundDimension1_Min,'string'));
PossibleIntegers = length(MinValue:1:MaxValue);
if IntegerTrials>PossibleIntegers
set(hObject,'string',PossibleIntegers);
end
guidata(hObject, handles);
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function BackgroundStart2_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(3) = floor(str2double(get(hObject,'string')));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
IntegerTrials = floor(handles.NumberTrialsVector(3));
set(hObject,'string',IntegerTrials);
MaxValue = str2double(get(handles.BackgroundStart2_Max,'string'));
MinValue = str2double(get(handles.BackgroundStart2_Min,'string'));
PossibleIntegers = length(MinValue:1:MaxValue);
if IntegerTrials>PossibleIntegers
set(hObject,'string',PossibleIntegers);
end
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
set(hObject,'string',PossibleIntegers);
end
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
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function SamplingDensity_Trials_Callback(hObject, eventdata, handles)
handles.NumberTrialsVector(8) = str2double(get(hObject,'string'));
set(handles.TotalTrials,'string',prod(handles.NumberTrialsVector));
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
handles.NumberTrialsVector = ones(7,1);
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
% try
Defaults = handles.Defaults;
set(handles.SetParameterSet_Button,'enable','off')
set(handles.SetSelection_Text,'enable','off')
set(handles.RemoveSet_Button,'enable','off')
set(handles.PreviousParameterSet_Button,'enable','off')
set(handles.NextParameterSet_Button,'enable','off')
set(handles.TitleParameterSet_Text,'enable','off')
set(findall(handles.CurrentParameterSet_Panel, '-property', 'enable'), 'enable', 'off')
set(findall(handles.Display_Panel, '-property', 'enable'), 'enable', 'off')

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
else
  BackgroundDimension1_Vector = Defaults.BackgroundDimension1;
end

if get(handles.BackgroundDimension2_Check,'value')
  BackgroundDimension2_Min = str2double(get(handles.BackgroundDimension2_Min,'string'));
  BackgroundDimension2_Max = str2double(get(handles.BackgroundDimension2_Max,'string'));
  BackgroundDimension2_Trials = str2double(get(handles.BackgroundDimension2_Trials,'string'));
  BackgroundDimension2_Vector  = linspace(BackgroundDimension2_Min,BackgroundDimension2_Max,BackgroundDimension2_Trials);
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
  SamplingDensity_Vector = [handles.RawData.NUS.SamplingDensity 1];
end

%Flip vector so longer cpu times are are the start
ThresholdParameter_Vector = fliplr(ThresholdParameter_Vector);

ValidationVectors.BackgroundStart1_Vector = BackgroundStart1_Vector;
ValidationVectors.BackgroundStart2_Vector = BackgroundStart2_Vector;
ValidationVectors.BackgroundDimension1_Vector = BackgroundDimension1_Vector;
ValidationVectors.BackgroundDimension2_Vector = BackgroundDimension2_Vector;
ValidationVectors.LagrangeMultiplier_Vector = LagrangeMultiplier_Vector;
ValidationVectors.BackgroundParameter_Vector = BackgroundParameter_Vector;
ValidationVectors.ThresholdParameter_Vector = ThresholdParameter_Vector;
ValidationVectors.SamplingDensity_Vector  = SamplingDensity_Vector;
handles.ValidationMainPlot = handles.ValidationMainPlot;
handles.ValidationInset1 = handles.ValidationInset1;
handles.ValidationInset2 = handles.ValidationInset2;

set(handles.ValidationStatus,'string','Validation in progress...'),drawnow;

[ReconstructedSpectra,ParameterSets] = validateHyscorean(handles.RawData,ValidationVectors,handles.ValidationStatus,Defaults);
handles.ParameterSets = ParameterSets;
handles.ReconstructedSpectra = ReconstructedSpectra;
updateValidationPlots(handles)

updateParameterSets(1,handles)

set(handles.ZoomOut_Button,'visible','on')
set(handles.ZoomIn_Button,'visible','on')
set(handles.SetParameterSet_Button,'enable','on')
set(handles.PreviousParameterSet_Button,'enable','on')
set(handles.NextParameterSet_Button,'enable','on')
set(handles.TitleParameterSet_Text,'enable','on')
set(handles.RemoveSet_Button,'enable','on')
set(handles.SetSelection_Text,'enable','on')
set(findall(handles.CurrentParameterSet_Panel, '-property', 'enable'), 'enable', 'on')
set(findall(handles.Display_Panel, '-property', 'enable'), 'enable', 'on')


% catch
%   set(handles.ValidationStatus,'string','Ready'),drawnow;
% end

guidata(hObject, handles);

return

%------------------------------------------------------------------------------
function updateValidationPlots(handles)
ReconstructedSpectra = handles.ReconstructedSpectra;
set(handles.ValidationStatus,'string','Rendering...'),drawnow;

MeanReconstruction = mean(ReconstructedSpectra,3);
MeanReconstruction = MeanReconstruction/max(max(MeanReconstruction));
Uncertainty = std(ReconstructedSpectra,0,3);
LowerBound = MeanReconstruction - 2*Uncertainty;
UpperBound = MeanReconstruction + 2*Uncertainty;
Dimension1 = 0.5*size(MeanReconstruction,1);
Dimension2 = 0.5*size(MeanReconstruction,2);

TimeAxis1 = handles.RawData.TimeAxis1;
TimeAxis2 = handles.RawData.TimeAxis2;
TimeStep1 = TimeAxis1(2) - TimeAxis1(1);
TimeStep2 = TimeAxis2(2) - TimeAxis2(1);

%Construct frequency axis
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),2*Dimension1);
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),2*Dimension2);

%Plot reconstructed results
% CustomColormap = [0 0.5 0.2; 0 0.45 0.2; 0 0.4 0.2; 0.05 0.4 0.2; 0.1 0.4 0.2; 0.15 0.4 0.2; 0.2 0.4 0.2; 0.2 0.35 0.2; 0.2 0.3 0.2; 0.2 0.2 0.2; 0 0.4 0.2; 0 0.6 0.2; 0.1 0.7 0.2; 0.2 0.8 0.2; 0.1 0.8 0; 0.2 0.8 0; 0.6 1 0.6; 0.7 1 0.7; 0.8 1 0.8;
%             1 1 1; 1 1 1; 1 0.7 0.7; 1 0.65 0.65; 1 0.6 0.6;  1 0.55 0.55; 1 0.5 0.5;  1 0.45 0.45; 1 0.4 0.4; 1 0.3 0.3; 1 0.2 0.2; 1 0.15 0.15; 1 0.1 0.1; 1 0.05 0.05;   1 0 0;    0.95 0 0;      0.9 0 0;     0.8 0 0;     0.7 0 0;   0.65 0 0;  0.6 0 0];

HyscoreanPath = which('Hyscorean');
HyscoreanPath = HyscoreanPath(1:end-11);
CustomColormap = load(fullfile(HyscoreanPath,'bin\RedWhiteColorMap.mat'));
CustomColormap = CustomColormap.mycmap;
CustomColormap = fliplr(CustomColormap(1:end-2,:)')';
CustomColormap(1,:) = [1 1 1];
cla(handles.ValidationMainPlot)
contour(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,abs((MeanReconstruction)),80,'k','LineWidth',1)
set(handles.ValidationMainPlot,'YLim',[0 20],'XLim',[-20 20])
grid(handles.ValidationMainPlot,'on')
xlabel(handles.ValidationMainPlot,'\nu_1 [MHz]'),ylabel(handles.ValidationMainPlot,'\nu_2 [MHz]')
hold(handles.ValidationMainPlot,'on')
switch handles.DisplayRadioStatus
  case 'lower'
    Display = max(LowerBound,0);
  case 'upper'
    Display = UpperBound;
  case 'uncertainty'
    Display = Uncertainty;
end
h = pcolor(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,Display);
shading(handles.ValidationMainPlot,'interp')
colormap(handles.ValidationMainPlot,CustomColormap)
caxis(handles.ValidationMainPlot,[0 1])
h.FaceAlpha  = 0.7;
set(handles.ValidationMainPlot,'YLim',[0 20],'XLim',[-20 20])
hold(handles.ValidationMainPlot,'off')

  cla(handles.ValidationInset1)

MeanInset = max(MeanReconstruction(Dimension1:end,:));
Upper = MeanReconstruction(Dimension1:end,:) + Uncertainty(Dimension1:end,:);
Lower = MeanReconstruction(Dimension1:end,:) - Uncertainty(Dimension1:end,:);
LowerInset =  max(Lower/max(max(Lower)));
UpperInset =  max(Upper/max(max(Upper)));
plot(handles.ValidationInset1,FrequencyAxis1,MeanInset,'k')
hold(handles.ValidationInset1,'on')
a1 = fill(handles.ValidationInset1,[FrequencyAxis1 fliplr(FrequencyAxis1)], [ LowerInset  fliplr(MeanInset) ], 'r','LineStyle','none');
a2 = fill(handles.ValidationInset1,[FrequencyAxis1 fliplr(FrequencyAxis1)], [ MeanInset fliplr(UpperInset)  ], 'r','LineStyle','none');
a1.FaceAlpha = 0.5;
a2.FaceAlpha = 0.5;
set(handles.ValidationInset1,'XLim',[-20 20])
set(handles.ValidationInset1,'YLim',[0 1])
  set(handles.ValidationInset1,'XTick',[],'YTick',[])
hold(handles.ValidationInset2,'off')

  cla(handles.ValidationInset2)
MeanInset = max(MeanReconstruction);
Upper = MeanReconstruction + Uncertainty;
Lower = MeanReconstruction - Uncertainty;
LowerInset =  max(Lower/max(max(Lower)));
UpperInset =  max(Upper/max(max(Upper)));
plot(handles.ValidationInset2,MeanInset,FrequencyAxis1,'k')
hold(handles.ValidationInset2,'on')
a1 = fill(handles.ValidationInset2, [LowerInset  fliplr(MeanInset)],[FrequencyAxis1 fliplr(FrequencyAxis1)], 'r','LineStyle','none');
a2 = fill(handles.ValidationInset2, [MeanInset fliplr(UpperInset)],[FrequencyAxis1 fliplr(FrequencyAxis1)], 'r','LineStyle','none');
a1.FaceAlpha = 0.5;
a2.FaceAlpha = 0.5;

set(handles.ValidationInset2,'YLim',[0 20])
set(handles.ValidationInset2,'XLim',[0 1])

  set(handles.ValidationInset2,'XTick',[],'YTick',[])
%     camroll(handles.ValidationInset2,-90)
hold(handles.ValidationInset2,'off')

set(handles.ValidationStatus,'string','Ready'),drawnow;


return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function updateParameterSets(currentParameterSet,handles)

ParameterSets = handles.ParameterSets;
        set(handles.SetParameterSet_Button,'string',currentParameterSet)
        set(handles.CurrentParameterSet_Panel,'title',sprintf('Parameter Set #%i',currentParameterSet))

    set(handles.CurrentBackgroundStart1_Text,'string',ParameterSets(currentParameterSet).BackgroundStart1);
    set(handles.CurrentBackgroundStart2_Text,'string',ParameterSets(currentParameterSet).BackgroundStart2);
    set(handles.CurrentBackgroundDimension1_Text,'string',ParameterSets(currentParameterSet).BackgroundDimension1);
    set(handles.CurrentBackgroundDimension2_Text,'string',ParameterSets(currentParameterSet).BackgroundDimension2);
    set(handles.CurrentLagrangianMultiplier_Text,'string',ParameterSets(currentParameterSet).LagrangeMultiplier);
    set(handles.CurrentBackgroundParameter_Text,'string',ParameterSets(currentParameterSet).BackgroundParameter);
    set(handles.CurrentThresholdParameter_Text,'string',ParameterSets(currentParameterSet).ThresholdParameter);
    set(handles.CurrentSamplingDensity_Text,'string',ParameterSets(currentParameterSet).SamplingDensity);

return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function plotParameterSet(handles)

set(handles.ValidationStatus,'string','Rendering'),drawnow;

CurrentParameterSet = str2double(get(handles.SetParameterSet_Button,'string'));
ValidationSpectra = handles.ReconstructedSpectra;
CurrentSpectrum =  ValidationSpectra(:,:,CurrentParameterSet);

Dimension1 = 0.5*size(CurrentSpectrum,1);
Dimension2 = 0.5*size(CurrentSpectrum,2);

TimeStep1 = 0.016;
TimeStep2 = 0.016;
%Construct frequency axis
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),2*Dimension1);
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),2*Dimension2);

cla(handles.ValidationMainPlot)
contour(handles.ValidationMainPlot,FrequencyAxis1,FrequencyAxis2,abs((CurrentSpectrum)),80,'LineWidth',1)
set(handles.ValidationMainPlot,'YLim',[0 20],'XLim',[-20 20])
grid(handles.ValidationMainPlot,'on')
xlabel(handles.ValidationMainPlot,'\nu_1 [MHz]'),ylabel(handles.ValidationMainPlot,'\nu_2 [MHz]')
colormap(handles.ValidationMainPlot,'parula')

cla(handles.ValidationInset1)
MeanInset = max(CurrentSpectrum(Dimension1:end,:));
plot(handles.ValidationInset1,FrequencyAxis1,MeanInset,'k')
set(handles.ValidationInset1,'XLim',[-20 20])
  set(handles.ValidationInset1,'XTick',[],'YTick',[])

cla(handles.ValidationInset2)
MeanInset = max(CurrentSpectrum);
plot(handles.ValidationInset2,MeanInset,FrequencyAxis1,'k')
set(handles.ValidationInset2,'YLim',[0 20])
set(handles.ValidationInset2,'XTick',[],'YTick',[])

set(handles.ValidationStatus,'string','Ready'),drawnow;
return
%------------------------------------------------------------------------------


%------------------------------------------------------------------------------
function Min_Edits_Callback(hObject, eventdata, handles)
Tag = get(hObject,'Tag');
Tag = [Tag(1:end-3) 'Max'];
Min_EditHandle = hObject;
Max_EditHandle = findobj('Tag',Tag);
MaxValue = str2double(get(Max_EditHandle,'string'));
MinValue = str2double(get(Min_EditHandle,'string'));
if MinValue>MaxValue
  set(Max_EditHandle,'string',MinValue);
  set(Min_EditHandle,'string',MaxValue);
end
return
%------------------------------------------------------------------------------

%------------------------------------------------------------------------------
function Max_Edits_Callback(hObject, eventdata, handles)
Tag = get(hObject,'Tag');
Tag = [Tag(1:end-3) 'Min'];
Max_EditHandle = hObject;
Min_EditHandle = findobj('Tag',Tag);
MaxValue = str2double(get(Max_EditHandle,'string'));
MinValue = str2double(get(Min_EditHandle,'string'));
if MinValue>MaxValue
  set(Max_EditHandle,'string',MinValue);
  set(Min_EditHandle,'string',MaxValue);
end
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
FigureHandle = figure(12);
clf(FigureHandle)
set(FigureHandle,'Position',[-1364 463 997 623])
ExternalHandles.ValidationMainPlot = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.12 0.7 0.6]);
ExternalHandles.ValidationInset1 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.08 0.75 0.7 0.2]);
ExternalHandles.ValidationInset2 = axes('Units','Normalized','Parent',FigureHandle,'Position',[0.8 0.12 0.15 0.6]);
ExternalHandles.ValidationStatus = uicontrol('Parent',FigureHandle,'Style','text','Visible','off','Position',[0.8 0.12 0.15 0.6]);
ExternalHandles.ReconstructedSpectra = handles.ReconstructedSpectra;
ExternalHandles.DisplayRadioStatus = handles.DisplayRadioStatus;
ExternalHandles.RawData = handles.RawData;
updateValidationPlots(ExternalHandles)

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
