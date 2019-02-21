function enableDisableGUI(handles,Panel,Action)
%==========================================================================
% HYSCORE blind spot simulator
%==========================================================================
% Function for enabling or disabling different groups of UI elements of
% Hyscorean fast and in one line. 
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

switch Panel
  
  case 'NUSReconstruction'
    set(handles.MaxEntBackgroundParameter,'enable',Action)
    set(handles.BackgroundParameterText,'enable',Action)
    if strcmp(Action,'on')
    switch get(handles.ReconstructionAlgorithm,'Value')
      case 1
        set(handles.MaxEntLagrangianMultiplier,'enable','on')
        set(handles.LagrangeMultiplierText,'enable','on')
        set(handles.BackgroundParameterText,'enable','on')
        set(handles.MaxEntBackgroundParameter,'enable','on')
      case {2,3,4}
        set(handles.MaxEntLagrangianMultiplier,'enable','on')
        set(handles.LagrangeMultiplierText,'enable','on')
        set(handles.BackgroundParameterText,'enable','off')
        set(handles.MaxEntBackgroundParameter,'enable','off')
      otherwise
        set(handles.MaxEntLagrangianMultiplier,'enable','off')
        set(handles.LagrangeMultiplierText,'enable','off')
        set(handles.BackgroundParameterText,'enable','off')
        set(handles.MaxEntBackgroundParameter,'enable','off')
    end
    else
      set(handles.MaxEntLagrangianMultiplier,'enable',Action)
      set(handles.LagrangeMultiplierText,'enable',Action)
      set(handles.BackgroundParameterText,'enable',Action)
      set(handles.NUSReconstructionText,'enable',Action)
    end
    set(handles.NUSReconstructionText,'enable',Action)
    set(handles.ReconstructionAlgorithm,'enable',Action)
    set(handles.plotNUSgridText,'enable',Action)
    set(handles.plotNUSgrid,'enable',Action)
    
  case 'Lorent2Gauss'
    set(handles.L2G_sigma,'enable',Action)
    set(handles.L2G_sigma2,'enable',Action)
    set(handles.L2GSigmaText,'enable',Action)
    set(handles.L2GSigmaText2,'enable',Action)
    set(handles.L2GTauText,'enable',Action)
    set(handles.L2GTauText2,'enable',Action)
    set(handles.L2G_tau,'enable',Action)
    set(handles.L2G_tau2,'enable',Action)
    
  case 'AutomaticBackground'
    set(handles.BackgroundStart1,'enable',Action)
    set(handles.BackgroundStart2,'enable',Action)
    
  case 'SG-Filtering'
    set(handles.FilterOrder,'enable',Action)
    set(handles.FilterOrderText,'enable',Action)
    set(handles.FrameLength,'enable',Action)
    set(handles.FrameLengthText,'enable',Action)
end