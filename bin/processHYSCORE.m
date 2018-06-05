function [handles]=processHYSCORE(handles)

%Convert UIControl variables to doubles
ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
HammingWindow = get(handles.HammingWindow,'Value');
WindowDecay = str2double(get(handles.Hammingedit,'string'));
BackgroundParameter = str2double(get(handles.MaxEntBackgroundParameter,'string'));
LagrangeMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));

%Check if simulated or experimental data
switch get(handles.ExperimentalFlag,'Value')
  case 1
    type='experimental';
  case 0
    type='simulation';
end

Data = handles.Data;
  CombinationsSelection = get(handles.MultiTauDimensions,'Value');
  TauIndexes  = handles.Data.Combinations(CombinationsSelection,:);
  handles.currentTaus = handles.Data.TauValues(TauIndexes(TauIndexes~=0));
  handles.currentIndexes = TauIndexes(TauIndexes~=0);
    
if handles.TauSelectionSwitch && strcmp(type,'experimental') %no need to repeate pre-processing if data not changed
  %Set selection icon to waiting
  set(handles.TauSelectionWaiting,'visible','on'),drawnow
  handles.backgroundCorrectionSwitch = true;
  %Set tau selection icon to waiting
  set(handles.TauSelectionWaiting,'visible','on'),drawnow
  
  % Get values from GUI to pass to integrateEcho.m function
    Data.Integral = zeros(size(Data.TauSignals,2));
    for TauIndex = 1:length(handles.currentTaus)
    Data.Integral  = Data.Integral  + squeeze(Data.TauSignals(handles.currentIndexes(TauIndex),:,:));
    end
    Data.TimeAxis1 = linspace(0,Data.TimeStep1*size(Data.Integral,1),size(Data.Integral,1));
    Data.TimeAxis2 = linspace(0,Data.TimeStep2*size(Data.Integral,2),size(Data.Integral,2));
    
    %Set tau selection icon to check
    set(handles.TauSelectionWaiting,'visible','off')
    set(handles.TauSelectionCheck,'visible','on')
    set(handles.BackgroundCorrectionWaiting,'visible','on'),drawnow
  end
  
  
  
  if handles.backgroundCorrectionSwitch
    % Get values from GUI to pass to correctBackground.m function
    %Set-up options for the two individual background corrections
    switch get(handles.BackgroundMethod1,'Value')
      case 1
        options.BackgroundMethod1 = 0;
        options.BackgroundPolynomOrder1 = [];
        options.BackgroundFractalDimension1 = [];
      case 2
        options.BackgroundMethod1 = 1;
        options.BackgroundPolynomOrder1 = [];
        options.BackgroundFractalDimension1 = str2double(get(handles.BackgroundParameter1,'string'));
      case 3
        options.BackgroundMethod1 = 2;
        options.BackgroundPolynomOrder1 = str2double(get(handles.BackgroundParameter1,'string'));
        options.BackgroundFractalDimension1 = [];
      case 4
        options.BackgroundMethod1 = 3;
        options.BackgroundPolynomOrder1 = str2double(get(handles.BackgroundParameter1,'string'));
        options.BackgroundFractalDimension1 = [];
        
    end
    switch get(handles.BackgroundMethod2,'Value')
      case 1
        options.BackgroundMethod2 = 0;
        options.BackgroundPolynomOrder2 = [];
        options.BackgroundFractalDimension2 = [];
      case 2
        options.BackgroundMethod2 = 1;
        options.BackgroundPolynomOrder2 = [];
        options.BackgroundFractalDimension2 = str2double(get(handles.BackgroundParameter2,'string'));
      case 3
        options.BackgroundMethod2 = 2;
        options.BackgroundPolynomOrder2 = str2double(get(handles.BackgroundParameter2,'string'));
        options.BackgroundFractalDimension2 = [];
      case 4
        options.BackgroundMethod2 = 3;
        options.BackgroundPolynomOrder2 = str2double(get(handles.BackgroundParameter2,'string'));
        options.BackgroundFractalDimension2 = [];
    end
    %Set-up rest of options
    options.AutomaticBackgroundStart = get(handles.AutomaticBackgroundStart,'Value');
    options.BackgroundStart1 = str2double(get(handles.BackgroundStart1,'string'));
    options.BackgroundStart2 = str2double(get(handles.BackgroundStart1,'string'));
    options.BackgroundCorrection2D = 0;
    options.ZeroTimeTruncation = get(handles.ZeroTimeTruncation,'Value');
    options.InvertCorrection = get(handles.InvertCorrection,'Value');
    options.DisplayCorrected = get(handles.DisplayCorrected,'Value');
    options.SavitzkyGolayFiltering = get(handles.SavitzkyFilter,'Value');
    options.SavitzkyOrder = str2double(get(handles.FilterOrder,'string'));
    options.SavitzkyFrameLength = str2double(get(handles.FrameLength,'string'));
    
    set(handles.ProcessingInfo, 'String', 'Status: Correct background'); drawnow;
    [Data] = correctBackground(Data,options);
    %Set background correction icon to check
    set(handles.BackgroundCorrectionWaiting,'visible','off')
    set(handles.BackgroundCorrectionCheck,'visible','on')
    drawnow;
  elseif strcmp(type,'experimental')
    Data = handles.Data;
  end
  handles.TauSelectionSwitch = false;
  handles.backgroundCorrectionSwitch = false;
  handles.MountDataSwitch = false;
  
  
  %Check if input was a NUS signal
  if Data.NUSflag && handles.ReconstructionSwitch
    
    %Set reconstruction icon to waiting
    set(handles.ReconstructionWaiting,'visible','on')
    drawnow;
    %Update status display
    set(handles.ProcessingInfo, 'String', 'Status: Reconstructing signal'); drawnow;
    %If yes, then reconstruct the signal
    switch get(handles.ReconstructionAlgorithm,'Value')
      case 1 %CAMERA Reconstruction
        Data.ReconstructedSignal = camera(Data.PreProcessedSignal,Data.SamplingGrid,BackgroundParameter);
      case 2 %Simple MaxEnt Reconstruction
        Data.ReconstructedSignal =  maxEntReconstruction(Data.PreProcessedSignal,BackgroundParameter,LagrangeMultiplier);
    end
    %Once processed turn the switch to the reconstruction off (will be turned on if parameters in pre-processing changed)
    handles.ReconstructionSwitch = false;
    %Set reconstruction icon to check
    set(handles.ReconstructionWaiting,'visible','off')
    set(handles.ReconstructionCheck,'visible','on')
  else
    %Else just assign the unchanged pre-processed signal (required in order to keep the NUS signal unreconstructed)
    Data.ReconstructedSignal = Data.PreProcessedSignal;
    
  end
  
  
  %Zero-Filling
  [Dimension1,Dimension2] = size(Data.ReconstructedSignal);
  Processed.Signal = zeros(Dimension1 + ZeroFilling1, Dimension2 + ZeroFilling2);
  Processed.Signal(1:Dimension1,1:Dimension2) = Data.ReconstructedSignal(1:Dimension1, 1:Dimension2);
  
  %Compute extended time axis
  Processed.TimeAxis1 = linspace(0,(Dimension1 + ZeroFilling1)*Data.TimeStep1,(Dimension1 + ZeroFilling1));
  Processed.TimeAxis2 = linspace(0,(Dimension2 + ZeroFilling2)*Data.TimeStep2,(Dimension2 + ZeroFilling2));
  
  
  if get(handles.Lorentz2GaussCheck,'Value')
    %Lorentz-to-Gauss transformation along both dimensions
    Parameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
    Parameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
    Parameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
    Parameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
    
    % Sometimes something may be messed up during mountdata.m check that dimensions are consisten
    if ~(size(Processed.Signal,1) == length(Processed.TimeAxis1) && size(Processed.Signal,2) == length(Processed.TimeAxis2))
      temp = Processed.TimeAxis1;
      Processed.TimeAxis1 = Processed.TimeAxis2;
      Processed.TimeAxis2 = temp;
    end
    [Processed]=Lorentz2Gauss2D(Processed,Parameters);
  end
  %Apodization
  if WindowDecay ~= 0
    if HammingWindow
      [Processed]=HammingWin(Processed,WindowDecay);
    else
      [Processed]=ChebishevWin(Processed,WindowDecay);
    end
  end
  
  % Process into spectrum
  [Dimension2,Dimension1] = size(Processed.Signal);
    %Construct frequency axis
  FrequencyAxis1 = linspace(-1/(2*Data.TimeStep1),1/(2*Data.TimeStep1),Dimension1);
  FrequencyAxis2 = linspace(-1/(2*Data.TimeStep2),1/(2*Data.TimeStep2),Dimension2);
  
  Processed.spectrum = fftshift(fft2(Processed.Signal));
  Processed.axis1 = FrequencyAxis1;
  Processed.axis2 = FrequencyAxis2; 

handles.Data = Data;
handles.Processed = Processed;
assignin('base', 'Processed', Processed);

