function [handles]=processHYSCORE(handles)
%==========================================================================
% HYSCORE Processing Main Protocol 
%==========================================================================
% This function represents the backbone of the Hyscorean pre-processing and
% processing protocols. The functions organizes variables taken from the GUI
% and sends them to the respective processing functions through all processing
% steps. Depending on the GUI changes, several steps can be skipped for quicker
% processing.
%
% (See Hyscorean's manual for more information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%==========================================================================
% Preparations
%==========================================================================

%Get processing parameters from corresponding UI elements
ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
WindowDecay1 = str2double(get(handles.WindowLength1,'string'));
WindowDecay2 = str2double(get(handles.WindowLength2,'string'));
BackgroundParameter = 10^(str2double(get(handles.MaxEntBackgroundParameter,'string')));
LagrangeMultiplier = str2double(get(handles.MaxEntLagrangianMultiplier,'string'));
CombinationsSelection = get(handles.MultiTauDimensions,'Value');
BackgroundCorrectionParameter1 = str2double(get(handles.BackgroundParameter1,'string'));
BackgroundCorrectionParameter2 = str2double(get(handles.BackgroundParameter2,'string'));
BackgroundStart1 = str2double(get(handles.BackgroundStart1,'string'));
BackgroundStart2 = str2double(get(handles.BackgroundStart2,'string'));
InvertCorrection = get(handles.InvertCorrection,'Value');
L2GParameters.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
L2GParameters.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
L2GParameters.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
L2GParameters.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
ApoWindowName = handles.WindowTypeString;

%Get mounted data
Data = handles.Data;

%==========================================================================
% Tau-Signals Combination
%==========================================================================

%Get the combination of tau-values chosen by user
TauIndexes  = handles.Data.Combinations(CombinationsSelection,:);
handles.currentTaus = handles.Data.TauValues(TauIndexes(TauIndexes~=0));
handles.currentIndexes = TauIndexes(TauIndexes~=0);
%If first time or user has changed selection then continue
if handles.TauSelectionSwitch
  %Set selection icon to waiting
  set(handles.TauSelectionWaiting,'visible','on'),drawnow
  %Since signal is combined anew, background correction has to be repeated
  handles.backgroundCorrectionSwitch = true;
  %Combine the different tau-signals into one according to selection
  Data.Integral = zeros(size(Data.TauSignals,2),size(Data.TauSignals,3));
  for TauIndex = 1:length(handles.currentTaus)
    CurrentTauIntegral = squeeze(Data.TauSignals(handles.currentIndexes(TauIndex),:,:));
    %Combine signals in time-domain
    Data.Integral  = Data.Integral  + CurrentTauIntegral/max(max(CurrentTauIntegral));
  end
  %Cosntruct appropiate time axis
  Data.TimeAxis1 = linspace(0,Data.TimeStep1*size(Data.Integral,1),size(Data.Integral,1));
  Data.TimeAxis2 = linspace(0,Data.TimeStep2*size(Data.Integral,2),size(Data.Integral,2));
  %Set tau selection icon to check
  set(handles.TauSelectionWaiting,'visible','off')
  set(handles.TauSelectionCheck,'visible','on')
  %Set background icon to waiting
  set(handles.BackgroundCorrectionWaiting,'visible','on'),drawnow
end

%==========================================================================
% Background Correction
%==========================================================================

%If first time or user has changed background parameters then continue
if handles.backgroundCorrectionSwitch
  %Set-up options for the two individual background corrections
  switch get(handles.BackgroundMethod1,'Value')
    case 1 %Fractal
      options.BackgroundMethod1 = 0;
      options.BackgroundPolynomOrder1 = [];
      options.BackgroundFractalDimension1 = [];
    case 2 %n-Dimensional
      options.BackgroundMethod1 = 1;
      options.BackgroundPolynomOrder1 = [];
      options.BackgroundFractalDimension1 = BackgroundCorrectionParameter1;
    case 3 %Polynomial
      options.BackgroundMethod1 = 2;
      options.BackgroundPolynomOrder1 = BackgroundCorrectionParameter1;
      options.BackgroundFractalDimension1 = [];
    case 4 %Exponential
      options.BackgroundMethod1 = 3;
      options.BackgroundPolynomOrder1 = BackgroundCorrectionParameter1;
      options.BackgroundFractalDimension1 = [];
  end
  switch get(handles.BackgroundMethod2,'Value')
    case 1 %Fractal
      options.BackgroundMethod2 = 0;
      options.BackgroundPolynomOrder2 = [];
      options.BackgroundFractalDimension2 = [];
    case 2 %n-Dimensional
      options.BackgroundMethod2 = 1;
      options.BackgroundPolynomOrder2 = [];
      options.BackgroundFractalDimension2 = BackgroundCorrectionParameter2;
    case 3 %Polynomial
      options.BackgroundMethod2 = 2;
      options.BackgroundPolynomOrder2 = BackgroundCorrectionParameter2;
      options.BackgroundFractalDimension2 = [];
    case 4 %Exponential
      options.BackgroundMethod2 = 3;
      options.BackgroundPolynomOrder2 = BackgroundCorrectionParameter2;
      options.BackgroundFractalDimension2 = [];
  end
  %Set user-defined background starts
  options.BackgroundStart1 = BackgroundStart1;
  options.BackgroundStart2 = BackgroundStart2;
  %Set if user requests inversion of correction order
  options.InvertCorrection = InvertCorrection;
  
  %Inform user of current step in progress
  set(handles.ProcessingInfo, 'String', 'Status: Correct background'); drawnow;
  
  %If data is NUS then set zero-augmented points to NaN for MATLAB to ignore them
  if Data.NUSflag
  [Dimension1,Dimension2] = size(Data.Integral);
  for i=1:Dimension1
    for j=1:Dimension2
      if Data.NUSgrid(i,j) == 0
        Data.Integral(i,j) = NaN;
      end
    end
  end
  end
  
  %Perform background correction
  [Data] = correctBackground(Data,options);
  
  %If data is NUS then set NaN points back to zero-augmentation
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
else
  Data = handles.Data;
end
%Set all passed switches off for the next processing to skip them
handles.TauSelectionSwitch = false;
handles.backgroundCorrectionSwitch = false;
handles.MountDataSwitch = false;

%==========================================================================
% NUS Reconstruction
%==========================================================================

%Check if input is a NUS signal, otherwise skip this step
if Data.NUSflag && handles.ReconstructionSwitch
  %Set reconstruction icon to waiting
  set(handles.ReconstructionWaiting,'visible','on'); drawnow;
  %Update status display
  set(handles.ProcessingInfo, 'String', 'Status: Reconstructing signal'); drawnow;
  %Cosntruct point sampling schedule from NUS grid
  [Rows,Columns] = find(Data.NUSgrid==1);
  Schedule = [Rows,Columns];
  
  %Perform NUS reconstruction according to method selection by user
  switch get(handles.ReconstructionAlgorithm,'Value')
    case 1 %constant-lambda CAMERA
      [Data.ReconstructedSignal,FunctionEvaluations,~,LagrangeMultipliers_Used] = camera_hyscorean(Data.PreProcessedSignal,Schedule,[],LagrangeMultiplier,BackgroundParameter);
    case 2 %constant-aim CAMERA
      [Data.ReconstructedSignal,FunctionEvaluations,~,LagrangeMultipliers_Used] = camera_hyscorean(Data.PreProcessedSignal,Schedule);
    case 3 %FFM-CG
      [Data.ReconstructedSignal,FunctionEvaluations] = ffm_cg_hyscorean(Data.PreProcessedSignal,Schedule,BackgroundParameter,5000);
    case 4 %FFM-GD
      [Data.ReconstructedSignal,FunctionEvaluations] = ffm_gd_hyscorean(Data.PreProcessedSignal,Schedule,BackgroundParameter,5000);
    case 5 %IST-S Reconstruction
      [Data.ReconstructedSignal,FunctionEvaluations] = ists_hyscorean(Data.PreProcessedSignal,Data.NUSgrid,0.98,5000);
    case 6 %IST-D Reconstruction
      [Data.ReconstructedSignal,FunctionEvaluations] = istd_hyscorean(Data.PreProcessedSignal,Data.NUSgrid,0.98,5000);
  end
  
  %Save functional evolution information
  if exist('LagrangeMultipliers_Used','var')
    Data.LagrangeMultipliers_Used = LagrangeMultipliers_Used;
  end
  Data.ReconstructionConvergence = FunctionEvaluations;
  
  %Turn the switch of the reconstruction off
  handles.ReconstructionSwitch = false;
  %Set reconstruction icon to check
  set(handles.ReconstructionWaiting,'visible','off')
  set(handles.ReconstructionCheck,'visible','on')
  
elseif ~Data.NUSflag
  
  %If not NUS just assign the unchanged pre-processed signal (required in order to keep the NUS signal unreconstructed)
  Data.ReconstructedSignal = Data.PreProcessedSignal;
  
end

%==========================================================================
% Zero-Filling
%==========================================================================

%If symmetrization is requested later, then enforce a square matrix
if ~strcmp(handles.SymmetrizationString,'None')
  %Use the largest zero-filling requested
  ZeroFilling1 = max(ZeroFilling1,ZeroFilling2);
  ZeroFilling2 = max(ZeroFilling1,ZeroFilling2);
  %Update this change in the GUI so that user knows
  set(handles.ZeroFilling1, 'String',ZeroFilling1 );
  set(handles.ZeroFilling2, 'String',ZeroFilling2 );
  drawnow;
end

%Zero-Filling of signal
[Dimension1,Dimension2] = size(Data.ReconstructedSignal);
Processed.Signal = zeros(Dimension1 + ZeroFilling1, Dimension2 + ZeroFilling2);
Processed.Signal(1:Dimension1,1:Dimension2) = Data.ReconstructedSignal(1:Dimension1, 1:Dimension2);
%Compute extended time axis of zero-filled signal
Processed.TimeAxis1 = linspace(0,(Dimension1 + ZeroFilling1)*Data.TimeStep1,(Dimension1 + ZeroFilling1));
Processed.TimeAxis2 = linspace(0,(Dimension2 + ZeroFilling2)*Data.TimeStep2,(Dimension2 + ZeroFilling2));

%==========================================================================
% Lorentz-to-Gauss Transformation
%==========================================================================

%Perform L2G transformation only if requested by user
if get(handles.Lorentz2GaussCheck,'Value')
  % Sometimes something may be messed up during mountdata.m check that dimensions are consistent
  if ~(size(Processed.Signal,1) == length(Processed.TimeAxis1) && size(Processed.Signal,2) == length(Processed.TimeAxis2))
    temp = Processed.TimeAxis1;
    Processed.TimeAxis1 = Processed.TimeAxis2;
    Processed.TimeAxis2 = temp;
  end
  [Processed]=Lorentz2Gauss2D(Processed,L2GParameters);
end

%==========================================================================
% Apodization
%==========================================================================

%Perform signal apodization along both dimensions according to user selection
Processed.Signal = apodizationWin(Processed.Signal,ApoWindowName,WindowDecay1, WindowDecay2);

%==========================================================================
% Fourier Transformation
%==========================================================================

%Process into spectrum
[Dimension2,Dimension1] = size(Processed.Signal);
%Construct frequency axes
FrequencyAxis1 = linspace(-1/(2*Data.TimeStep1),1/(2*Data.TimeStep1),Dimension1);
FrequencyAxis2 = linspace(-1/(2*Data.TimeStep2),1/(2*Data.TimeStep2),Dimension2);
%Perform 2D-FFT of the processed signal
Spectrum = fftshift(fft2(Processed.Signal));

%==========================================================================
% Symmetrization
%==========================================================================

%If requested by user, symmetrize the spectrum
switch handles.SymmetrizationString
  case 'Diagonal'
    Spectrum = (Spectrum.*Spectrum').^0.5;
  case 'Anti-Diagonal'
    Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
  case 'Both'
    Spectrum = (Spectrum.*Spectrum').^0.5;
    Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
end

%==========================================================================
% Finish and return
%==========================================================================

%Save in structure and return
Processed.spectrum = Spectrum;
Processed.axis1 = FrequencyAxis1;
Processed.axis2 = FrequencyAxis2;
handles.Data = Data;
handles.Processed = Processed;

return
