function [handles]=processHYSCORE(handles)

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------

%Convert UIControl variables to doubles
ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
% HammingWindow = get(handles.HammingWindow,'Value');
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

if handles.TauSelectionSwitch %no need to repeate pre-processing if data not changed
  %Set selection icon to waiting
  set(handles.TauSelectionWaiting,'visible','on'),drawnow
  handles.backgroundCorrectionSwitch = true;
  %Set tau selection icon to waiting
  set(handles.TauSelectionWaiting,'visible','on'),drawnow
  
  %--------------------------------------------------------------------------
  % Integration
  %--------------------------------------------------------------------------
    Data.Integral = zeros(size(Data.TauSignals,2),size(Data.TauSignals,3));
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

%--------------------------------------------------------------------------
% Background Correction
%--------------------------------------------------------------------------

if handles.backgroundCorrectionSwitch
  % Get values from GUI to pass to correctBackground.m function
  %Set-up options for the two individual background corrections
  switch get(handles.BackgroundMethod1,'Value')
    case 1 %Fractal
      options.BackgroundMethod1 = 0;
      options.BackgroundPolynomOrder1 = [];
      options.BackgroundFractalDimension1 = [];
    case 2 %n-Dimensional
      options.BackgroundMethod1 = 1;
      options.BackgroundPolynomOrder1 = [];
      options.BackgroundFractalDimension1 = str2double(get(handles.BackgroundParameter1,'string'));
    case 3 %Polynomial
      options.BackgroundMethod1 = 2;
      options.BackgroundPolynomOrder1 = str2double(get(handles.BackgroundParameter1,'string'));
      options.BackgroundFractalDimension1 = [];
    case 4 %Exponential
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
  options.SavitzkyGolayFiltering = get(handles.SavitzkyFilter,'Value');
  options.SavitzkyOrder = str2double(get(handles.FilterOrder,'string'));
  options.SavitzkyFrameLength = str2double(get(handles.FrameLength,'string'));
  
  set(handles.ProcessingInfo, 'String', 'Status: Correct background'); drawnow;
  
  if Data.NUSflag
  [Dimension1,Dimension2] = size(Data.Integral);
  for i=1:Dimension1
    for j=1:Dimension2
      if Data.AWG_Parameters.NUS.SamplingGrid(i,j) ==0
        Data.Integral(i,j) = NaN;
      end
    end
  end
  end
  
  [Data] = correctBackground(Data,options);
  
  if Data.NUSflag
    for i=1:Dimension1
    for j=1:Dimension2
      if isnan(Data.PreProcessedSignal(i,j))
        Data.PreProcessedSignal(i,j) = 0;
      end
    end
    end
  end
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

%--------------------------------------------------------------------------
% NUS Reconstruction
%--------------------------------------------------------------------------

%Check if input was a NUS signal
if Data.NUSflag && handles.ReconstructionSwitch
  
  %Set reconstruction icon to waiting
  set(handles.ReconstructionWaiting,'visible','on'); drawnow;
  %Update status display
  set(handles.ProcessingInfo, 'String', 'Status: Reconstructing signal'); drawnow;
  %If yes, then reconstruct the signal
  [Rows,Columns] = find(Data.AWG_Parameters.NUS.SamplingGrid==1);
  Schedule = [Rows,Columns];
  switch get(handles.ReconstructionAlgorithm,'Value')
    case 1 %Constant-lambda CAMERA Reconstruction
      SingleLagrangeMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));
      BackgroundParameterVector = 10^(str2double(get(handles.MaxEntBackgroundParameter,'string')));
      [Data.ReconstructedSignal,FunctionEvaluations,~,LagrangeMultipliers_Used] = camera_hyscorean(Data.PreProcessedSignal,Schedule,[],SingleLagrangeMultiplier,BackgroundParameterVector,[],[],[],[],[],handles);
    case 2 %CAMERA 
        [Data.ReconstructedSignal,FunctionEvaluations,~,LagrangeMultipliers_Used] = camera_hyscorean(Data.PreProcessedSignal,Schedule,[],[],[],[],[],[],[],[],handles);
    case 3 %FFM-CG
      BackgroundParameter = 10^(str2double(get(handles.MaxEntBackgroundParameter,'string')));
      [Data.ReconstructedSignal,FunctionEvaluations] = ffm_cg_hyscorean(Data.PreProcessedSignal, Schedule, BackgroundParameter, 5000,handles);
    case 4 %FFM-GD 
      BackgroundParameter = 10^(str2double(get(handles.MaxEntBackgroundParameter,'string')));
      [Data.ReconstructedSignal,FunctionEvaluations] = ffm_cg_hyscorean(Data.PreProcessedSignal, Schedule, BackgroundParameter, 5000,handles);
    case 5 %IST-S Reconstruction
      [Data.ReconstructedSignal,FunctionEvaluations] = ists_hyscorean(Data.PreProcessedSignal,Data.AWG_Parameters.NUS.SamplingGrid,0.5,5000,handles);
    case 6 %IST-D Reconstruction
      [Data.ReconstructedSignal,FunctionEvaluations] = istd_hyscorean(Data.PreProcessedSignal,Data.AWG_Parameters.NUS.SamplingGrid,0.9,5000,handles);
  end
  Data.ReconstructionConvergence = FunctionEvaluations;
  %Once processed turn the switch to the reconstruction off (will be turned on if parameters in pre-processing changed)
  handles.ReconstructionSwitch = false;
  %Set reconstruction icon to check
  set(handles.ReconstructionWaiting,'visible','off')
  set(handles.ReconstructionCheck,'visible','on')
elseif ~Data.NUSflag
  %Else just assign the unchanged pre-processed signal (required in order to keep the NUS signal unreconstructed)
  Data.ReconstructedSignal = Data.PreProcessedSignal;
  
end

%--------------------------------------------------------------------------
% Zero-Filling
%--------------------------------------------------------------------------

%Zero-Filling
[Dimension1,Dimension2] = size(Data.ReconstructedSignal);
Processed.Signal = zeros(Dimension1 + ZeroFilling1, Dimension2 + ZeroFilling2);
Processed.Signal(1:Dimension1,1:Dimension2) = Data.ReconstructedSignal(1:Dimension1, 1:Dimension2);

%Compute extended time axis
Processed.TimeAxis1 = linspace(0,(Dimension1 + ZeroFilling1)*Data.TimeStep1,(Dimension1 + ZeroFilling1));
Processed.TimeAxis2 = linspace(0,(Dimension2 + ZeroFilling2)*Data.TimeStep2,(Dimension2 + ZeroFilling2));

%--------------------------------------------------------------------------
% Lorentz-to-Gauss Transformation
%--------------------------------------------------------------------------

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

%--------------------------------------------------------------------------
% Apodization
%--------------------------------------------------------------------------

WindowMenuState = get(handles.WindowType,'value');
Processed.Signal = apodizationWin(Processed.Signal,handles.WindowTypeString,WindowDecay);

%--------------------------------------------------------------------------
% Fourier Transformation
%--------------------------------------------------------------------------

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

