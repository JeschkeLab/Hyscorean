function enableDisableGUI(handles,Panel,Action)

switch Panel
  case 'NUSReconstruction'
    set(handles.MaxEntBackgroundParameter,'enable',Action)
    set(handles.BackgroundParameterText,'enable',Action)
    switch get(handles.ReconstructionAlgorithm,'Value')
      case 1
        set(handles.MaxEntLagrangianMultiplier,'enable','off')
        set(handles.LagrangeMultiplierText,'enable','off')
      case 2
        set(handles.MaxEntLagrangianMultiplier,'enable','on')
        set(handles.LagrangeMultiplierText,'enable','on')
    end
    set(handles.ReconstructionAlgorithm,'enable',Action)
    set(handles.NUSReconstructionText,'enable',Action)
    set(handles.plotNUSgridText,'enable',Action)
    set(handles.plotNUSgrid,'enable',Action)
    set(handles.plotNUSsignal,'enable',Action)
    set(handles.plotNUSsignalText,'enable',Action)
  case 'Lorent2Gauss'
    set(handles.L2G_sigma,'enable',Action)
    set(handles.L2G_sigma2,'enable',Action)
    set(handles.L2GSigmaText,'enable',Action)
    set(handles.L2GSigmaText2,'enable',Action)
    set(handles.L2GTauText,'enable',Action)
    set(handles.L2GTauText2,'enable',Action)
    set(handles.L2G_tau,'enable',Action)
    set(handles.L2G_tau2,'enable',Action)
    
    
    
end