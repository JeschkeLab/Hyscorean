function Settings = getSettings(handles)

 % Retrieve and store current GUI settings 
  Settings.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
  Settings.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
  Settings.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
  Settings.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
  Settings.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
  Settings.Lorentz2GaussCheck = get(handles.Lorentz2GaussCheck,'value');

  Settings.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
  Settings.zerofilling2 = str2double(get(handles.ZeroFilling2,'string'));
  Settings.WindowDecay1 = str2double(get(handles.WindowLength1,'string'));
  Settings.WindowDecay2 = str2double(get(handles.WindowLength1,'string'));

  %   Settings.FrequencyLimit1 = str2double(get(handles.Limit1,'string'));
  %   Settings.FrequencyLimit2 = str2double(get(handles.Limit2,'string'));
  Settings.WindowType = get(handles.WindowType,'value');
  try
  Settings.HammingWindow = (get(handles.HammingWindow,'value'));
  Settings.ChebishevWindow = (get(handles.ChebishevWindow,'value'));
  catch 
    %to ensure no conflict with older version without chebishev window
  end
  Settings.BackgroundMethod2 = get(handles.BackgroundMethod2,'Value');
  Settings.BackgroundMethod1 = get(handles.BackgroundMethod1,'Value');
  Settings.BackgroundParameter1 = str2double(get(handles.BackgroundParameter1,'string'));
  Settings.BackgroundParameter2 = str2double(get(handles.BackgroundParameter2,'string'));
  Settings.BackgroundCorrection2D = 0;
  Settings.InvertCorrection = get(handles.InvertCorrection,'Value');
%   Settings.SavitzkyGolayFrameLength = str2double(get(handles.FrameLength,'string'));
%   Settings.SavitzkyGolayOrder = str2double(get(handles.FilterOrder,'string'));
%   Settings.SavitzkyGolayFilter = get(handles.SavitzkyFilter,'Value');
  Settings.FieldOffset = get(handles.FieldOffset,'string');
Settings.BackgroundStart1 = get(handles.BackgroundStart1,'string');
Settings.BackgroundStart2 = get(handles.BackgroundStart2,'string');
Settings.MultiTauDimension = get(handles.MultiTauDimensions,'value');
Settings.MinimalContourLevel = get(handles.MinimalContourLevel,'string');
Settings.XUpperLimit = get(handles.XUpperLimit,'string');

  Settings.ReconstructionAlgorithm = get(handles.ReconstructionAlgorithm,'value');
  Settings.MaxEntBackgroundParameter = str2double(get(handles.MaxEntBackgroundParameter,'string'));
  Settings.MaxEntLagrangianMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));

  Settings.Symmetrization = get(handles.Symmetrization_ListBox,'value');

  