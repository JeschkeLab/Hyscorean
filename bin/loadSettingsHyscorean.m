function loadSettings(handles)

try
  %Get path to settings file with loading GUI
  [File, Path]=uigetfile('MultiSelect','off');
  
  %Load settings
  Settings = load(fullfile(Path,File));
catch
  return
end
Settings = Settings.Settings;

%Set edit boxes
set(handles.L2G_tau,'string',Settings.tauFactor1)
set(handles.L2G_tau2,'string',Settings.tauFactor2)
set(handles.L2G_sigma,'string',Settings.sigmaFactor1)
set(handles.L2G_sigma2,'string',Settings.sigmaFactor2)
set(handles.ZeroFilling2,'string',Settings.zerofilling2)
set(handles.ZeroFilling1,'string',Settings.zerofilling1)
% set(handles.Limit1,'string',Settings.FrequencyLimit1)
% set(handles.Limit2,'string',Settings.FrequencyLimit2)
set(handles.MaxEntBackgroundParameter,'string',Settings.MaxEntBackgroundParameter)
set(handles.MaxEntLagrangianMultiplier,'string',Settings.MaxEntLagrangianMultiplier)
try
  set(handles.Hammingedit,'string',Settings.WindowDecay)
catch
end
set(handles.BackgroundParameter1,'string',Settings.BackgroundParameter1);
set(handles.BackgroundParameter2,'string',Settings.BackgroundParameter2);
set(handles.FrameLength,'string',Settings.SavitzkyGolayFrameLength)
set(handles.FilterOrder,'string',Settings.SavitzkyGolayOrder)

%Set buttons
set(handles.ZeroTimeTruncation,'Value',Settings.ZeroTimeTruncation)
set(handles.BackgroundMethod2,'Value',Settings.BackgroundMethod2);
set(handles.BackgroundMethod1,'Value',Settings.BackgroundMethod1);
set(handles.InvertCorrection,'Value',Settings.InvertCorrection)
set(handles.SavitzkyFilter,'Value',Settings.SavitzkyGolayFilter)
set(handles.ReconstructionAlgorithm,'Value',Settings.MaxEntBackgroundParameter)


try
  if isnan(Settings.HammingWindow)
set(handles.HammingWindow,'Value',0)
set(handles.ChebishevWindow,'Value',1)
  else
set(handles.HammingWindow,'Value',Settings.HammingWindow)
set(handles.ChebishevWindow,'Value',Settings.ChebishevWindow)
  end
catch   
  
end

