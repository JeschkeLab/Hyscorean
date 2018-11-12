function enableDisableGUI(handles,Panel,Action)

switch Panel
  
  case 'NUSReconstruction'
    set(handles.MaxEntBackgroundParameter,'enable',Action)
    set(handles.BackgroundParameterText,'enable',Action)
    if strcmp(Action,'on')
    switch get(handles.ReconstructionAlgorithm,'Value')
      case 1
        set(handles.MaxEntLagrangianMultiplier,'enable','on')
        set(handles.LagrangeMultiplierText,'enable','on')
      case 2
        set(handles.MaxEntLagrangianMultiplier,'enable','off')
        set(handles.LagrangeMultiplierText,'enable','off')
    end
    else
      set(handles.MaxEntLagrangianMultiplier,'enable',Action)
      set(handles.LagrangeMultiplierText,'enable',Action)
    end
    set(handles.ReconstructionAlgorithm,'enable',Action)
    set(handles.NUSReconstructionText,'enable',Action)
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