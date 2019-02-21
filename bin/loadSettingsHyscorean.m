function handles = loadSettingsHyscorean(handles)
%==========================================================================
% Load Settings
%==========================================================================
% This function loads a previously saved settings file and sets all UI
% elements in the Hyscorean GUI to the corresponding values.
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2018-2019
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Get path to settings file with loading GUI
[File, Path]=uigetfile('MultiSelect','off');
%If user has cancelled then return
if File == 0
  return;
end

try
  %Load settings
  FileImport = load(fullfile(Path,File));
  Settings = FileImport.Settings;
  %Set all UI elements to the corresponding values
  set(handles.L2G_tau,'string',Settings.tauFactor1);
  set(handles.L2G_tau2,'string',Settings.tauFactor2);
  set(handles.L2G_sigma,'string',Settings.sigmaFactor1);
  set(handles.L2G_sigma2,'string',Settings.sigmaFactor2);
  set(handles.ZeroFilling2,'string',Settings.zerofilling2);
  set(handles.ZeroFilling1,'string',Settings.zerofilling1);
  set(handles.MaxEntBackgroundParameter,'string',Settings.MaxEntBackgroundParameter);
  set(handles.MaxEntLagrangianMultiplier,'string',Settings.MaxEntLagrangianMultiplier);
  set(handles.WindowType,'value',Settings.WindowType);
  switch Settings.WindowType
    case 1
      WindowType =  'hamming';
    case 2
      WindowType =  'chebyshev';
    case 3
      WindowType =  'welch';
    case 4
      WindowType = 'blackman';
    case 5
      WindowType = 'bartlett';
    case 6
      WindowType = 'connes';
    case 7
      WindowType = 'cosine';
    case 8
      WindowType = 'tukey25';
    case 9
      WindowType = 'tukey50';
    case 10
      WindowType = 'tukey75';
    case 11
      WindowType = 'hann';
    case 12
      WindowType = 'none';
  end
  try
    handles.WindowTypeString = WindowType;
    set(handles.WindowLength1,'string',Settings.WindowDecay1);
    set(handles.WindowLength2,'string',Settings.WindowDecay2);
    set(handles.Symmetrization_ListBox,'value',Settings.Symmetrization);
  catch
  end
  set(handles.WindowType,'value',Settings.WindowType)
  set(handles.BackgroundParameter1,'string',Settings.BackgroundParameter1);
  set(handles.BackgroundParameter2,'string',Settings.BackgroundParameter2);
  set(handles.Lorentz2GaussCheck,'value',Settings.Lorentz2GaussCheck);
  set(handles.BackgroundStart1,'string',Settings.BackgroundStart1);
  set(handles.BackgroundStart2,'string',Settings.BackgroundStart2);
  set(handles.MinimalContourLevel,'string',Settings.MinimalContourLevel);
  set(handles.XUpperLimit,'string',Settings.XUpperLimit);
  set(handles.FieldOffset,'string',Settings.FieldOffset);
  try %Try because if not the exact same file is loaded, value of list may exceed current one
    set(handles.MultiTauDimensions,'value',Settings.MultiTauDimension);
  catch
  end
  %Set buttons
  set(handles.BackgroundMethod2,'Value',Settings.BackgroundMethod2);
  set(handles.BackgroundMethod1,'Value',Settings.BackgroundMethod1);
  set(handles.InvertCorrection,'Value',Settings.InvertCorrection)
  set(handles.ReconstructionAlgorithm,'Value',Settings.ReconstructionAlgorithm)
  
catch
  %If user loads another type of file then error occurs. Inform user.
  f = errordlg(sprintf('An error occurred while loading the settings file: \n %s \n Please check your input.',File),'File Error');
  waitfor(f);
end

end

