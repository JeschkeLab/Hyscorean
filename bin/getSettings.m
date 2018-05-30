function Settings = getSettings(handles)

 % Retrieve and store current GUI settings 
  Settings.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
  Settings.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
  Settings.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
  Settings.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
  Settings.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
  Settings.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
  Settings.zerofilling2 = str2double(get(handles.ZeroFilling2,'string'));
  Settings.WindowDecay = str2double(get(handles.Hammingedit,'string'));
%   Settings.FrequencyLimit1 = str2double(get(handles.Limit1,'string'));
%   Settings.FrequencyLimit2 = str2double(get(handles.Limit2,'string'));

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
  Settings.ZeroTimeTruncation = get(handles.ZeroTimeTruncation,'Value');
  Settings.InvertCorrection = get(handles.InvertCorrection,'Value');
  Settings.SavitzkyGolayFrameLength = str2double(get(handles.FrameLength,'string'));
  Settings.SavitzkyGolayOrder = str2double(get(handles.FilterOrder,'string'));
  Settings.SavitzkyGolayFilter = get(handles.SavitzkyFilter,'Value');

  Settings.ReconstructionAlgorithm = str2double(get(handles.ReconstructionAlgorithm,'string'));
  Settings.MaxEntBackgroundParameter = str2double(get(handles.MaxEntBackgroundParameter,'string'));
  Settings.MaxEntLagrangianMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));
