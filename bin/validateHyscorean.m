function [ReconstructedSpectra,ParameterSets] = validateHyscorean(RawData,ValidationVectors,StatusHandle,Defaults)
%==========================================================================
% Validation protocol
%==========================================================================
% This function takes care of performing the validation computations.
% Taking all parameter sets from the validation module, this function
% generates the corresponding spectra and returns them.
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

%Get the unprocessed signal
RawSignal = RawData.Signal;
TimeAxis1 = RawData.TimeAxis1;
TimeAxis2 = RawData.TimeAxis1;
%Get dimensions
Dimension1 = size(RawSignal,1);
Dimension2 = size(RawSignal,2);
   
%Get number of validation trials for each parameter
Length1 = length(ValidationVectors.BackgroundStart1_Vector);
Length2 = length(ValidationVectors.BackgroundStart2_Vector);
Length3 = length(ValidationVectors.BackgroundDimension1_Vector);
Length4 = length(ValidationVectors.BackgroundDimension2_Vector);
Length5 = length(ValidationVectors.LagrangeMultiplier_Vector);
Length6 = length(ValidationVectors.BackgroundParameter_Vector);
Length7 = length(ValidationVectors.ThresholdParameter_Vector);
Length8 = ValidationVectors.SamplingDensity_Vector(2);
Length9 = length(ValidationVectors.NoiseLevel_Vector);

%If data is NUS, compute also the sampling density and the validation vector
if RawData.NUSflag
  FullDensity = 100*RawData.NUS.SamplingDensity;
  SmallestDensity = ValidationVectors.SamplingDensity_Vector(1);
  ReducedDensity = linspace(SmallestDensity,FullDensity,Length8);
end

%Total number of paramter combinations to evaluate
TotalTrials = Length1*Length2*Length3*Length4*Length5*Length6*Length7*Length8*Length9;

%Pre-allocate the matrix containing all validation spectra
ReconstructedSpectra = zeros(Dimension1 + Defaults.ZeroFilling1,Dimension2 + Defaults.ZeroFilling2,TotalTrials);
%Pre-allocate structure array for parameter sets
ParameterSets = zeros(1,TotalTrials);

%==========================================================================
% Validation
%==========================================================================

TrialsCompleted = 0;
PreviousTimes = [];
%Inform user on GUI
set(StatusHandle,'string','Validating: estimating validation time...'),drawnow
%Loop in an order that longer times are first
for Index6 = 1:Length6 
  for Index7 = 1:Length7
    for Index1 = 1:Length1
      for Index2 = 1:Length2
        for Index3 = 1:Length3
          for Index4 = 1:Length4
            for Index5 = 1:Length5
              for Index8 = 1:Length8
                for Index9 = 1:Length9
                  
                  %Start measuring validation time for this parameter set
                  tic         
                  %Extract NUS grid and get schedule
                  if RawData.NUSflag
                    NUSgrid = RawData.NUSgrid;
                    
                    %Check if smpling density has to be validated
                    if (FullDensity > ReducedDensity(Index8))
                      rng(1,'twister')
                      Ranks = NUSgrid.*rand(Dimension1,Dimension2);
                      CurrentSamplingDensity = FullDensity;
                      %Randomly remove points from the NUS grid until desired density is achieved
                      while CurrentSamplingDensity > ReducedDensity(Index8)
                        [row,col] = find(Ranks == max(max(Ranks)));
                        NUSgrid(row,col) = 0;
                        Ranks(row,col) = 0;
                        PointsSampled = length(find(NUSgrid > 0));
                        CurrentSamplingDensity = 100*PointsSampled/(Dimension1*Dimension2);
                      end
                    end
                    %Generate schedule from NUS grid
                    [Rows,Columns] = find(NUSgrid == 1);
                    Schedule = [Rows,Columns];
                  end
                  
                  %Start background correction protocol
                  CorrectedSignal = RawSignal;
                  %If NUS then set non-measured points to NaN
                  if  RawData.NUSflag
                    for i=1:Dimension1
                      for j=1:Dimension2
                        if NUSgrid(i,j) == 0
                          CorrectedSignal(i,j) = NaN;
                        end
                      end
                    end
                  end
                  
                  %Set background correction input paratmers
                  Data.Integral = CorrectedSignal;
                  Data.TimeAxis2 = TimeAxis1';
                  Data.TimeAxis1 = TimeAxis2';
                  %Set background correction options
                  options.BackgroundMethod1 = Defaults.BackgroundMethod1;
                  options.BackgroundMethod2 = Defaults.BackgroundMethod2;
                  options.BackgroundStart1 = ValidationVectors.BackgroundStart1_Vector(Index1);
                  options.BackgroundStart2 = ValidationVectors.BackgroundStart2_Vector(Index2);
                  options.BackgroundPolynomOrder1 = ValidationVectors.BackgroundDimension1_Vector(Index3);
                  options.BackgroundPolynomOrder2 = ValidationVectors.BackgroundDimension2_Vector(Index4);
                  options.BackgroundFractalDimension1 = ValidationVectors.BackgroundDimension1_Vector(Index3);
                  options.BackgroundFractalDimension2 = ValidationVectors.BackgroundStart2_Vector(Index2);
                  options.InvertCorrection = Defaults.InvertCorrection;
                  
                  %Correct background
                  [Data] = correctBackground(Data,options);
                  CorrectedSignal = Data.PreProcessedSignal;
                  
                  %If NUS restore NaN points to zero-augmentation
                  if  RawData.NUSflag
                    for i=1:Dimension1
                      for j=1:Dimension2
                        if isnan(CorrectedSignal(i,j))
                          CorrectedSignal(i,j) = 0;
                        end
                      end
                    end
                  end
                  
                  %Save current parameter set
                  ParameterSets(TrialsCompleted+1).BackgroundDimension1  = ValidationVectors.BackgroundDimension1_Vector(Index3);
                  ParameterSets(TrialsCompleted+1).BackgroundDimension2  = ValidationVectors.BackgroundDimension2_Vector(Index4);
                  ParameterSets(TrialsCompleted+1).BackgroundStart1 = ValidationVectors.BackgroundStart1_Vector(Index1);
                  ParameterSets(TrialsCompleted+1).BackgroundStart2 = ValidationVectors.BackgroundStart2_Vector(Index2);
                  if RawData.NUSflag
                    ParameterSets(TrialsCompleted+1).BackgroundParameter = ValidationVectors.BackgroundParameter_Vector(Index6);
                    ParameterSets(TrialsCompleted+1).LagrangeMultiplier = ValidationVectors.LagrangeMultiplier_Vector(Index5);
                    ParameterSets(TrialsCompleted+1).ThresholdParameter = ValidationVectors.ThresholdParameter_Vector(Index7);
                    ParameterSets(TrialsCompleted+1).SamplingDensity = ReducedDensity(Index8);
                    ParameterSets(TrialsCompleted+1).NoiseLevel = ValidationVectors.NoiseLevel_Vector(Index9);
                  else
                    ParameterSets(TrialsCompleted+1).BackgroundParameter = NaN;
                    ParameterSets(TrialsCompleted+1).LagrangeMultiplier = NaN;
                    ParameterSets(TrialsCompleted+1).ThresholdParameter = NaN;
                    ParameterSets(TrialsCompleted+1).SamplingDensity = NaN;
                    ParameterSets(TrialsCompleted+1).NoiseLevel = NaN;
                  end
                  
                  %Add spectral white noise for validation of noise
                  rng(2,'twister')
                  PowerSpectrum = randn(size(CorrectedSignal));
                  WhiteNoise = ifft2(PowerSpectrum);
                  WhiteNoise = WhiteNoise/max(max(WhiteNoise));
                  %If not requested the noise level is zero and signal remains untouched
                  CorrectedSignal = CorrectedSignal + ValidationVectors.NoiseLevel_Vector(Index9)*WhiteNoise;
                  
                  %If NUS then do spectral reconstruction
                  if  RawData.NUSflag
                    LagrangeMultiplier = ValidationVectors.LagrangeMultiplier_Vector(Index5);
                    ThresholdParameter = ValidationVectors.ThresholdParameter_Vector(Index7);
                    BackgroundParameter = 10^ValidationVectors.BackgroundParameter_Vector(Index6);
                    switch Defaults.ReconstructionMethod
                      case 'constantcamera'
                        ReconstructedSignal = camera_hyscorean(CorrectedSignal,Schedule,[],LagrangeMultiplier,BackgroundParameter);
                      case 'camera'
                        ReconstructedSignal = camera_hyscorean(CorrectedSignal,Schedule);
                      case 'ffmcg'
                        ReconstructedSignal = ffm_cg_hyscorean(CorrectedSignal,Schedule,BackgroundParameter,5000);
                      case 'ffmgd'
                        ReconstructedSignal = ffm_gd_hyscorean(CorrectedSignal,Schedule,BackgroundParameter,5000);
                      case 'ists'
                        ReconstructedSignal = ists_hyscorean(CorrectedSignal,NUSgrid,ThresholdParameter,5000);
                      case 'istd'
                        ReconstructedSignal = istd_hyscorean(CorrectedSignal,NUSgrid,ThresholdParameter,5000);
                    end
                  else
                    ReconstructedSignal = CorrectedSignal;
                  end
                  
                  %Get Hoch-Hore Entropy and RMSD of current resconstruction
                  if RawData.NUSflag
                    PointsSampled = length(find(NUSgrid > 0));
                    ParameterSets(TrialsCompleted+1).RMSD = norm(NUSgrid.*CorrectedSignal - NUSgrid.*ReconstructedSignal)/sqrt(PointsSampled);
                    ParameterSets(TrialsCompleted+1).Entropy = camera_functional(fft2(ReconstructedSignal),BackgroundParameter);
                  else
                    ParameterSets(TrialsCompleted+1).RMSD = NaN;
                    ParameterSets(TrialsCompleted+1).Entropy = NaN;
                  end
                  
                  %Check if some NaN has appeared (should not)
                  ReconstructedSignal(isnan(ReconstructedSignal)) = 0;
                  
                  %If done for experimental data, then do Lorentz-Gauss transformation
                  if Defaults.L2GCheck
                    Processed.TimeAxis1 = RawData.TimeAxis1;
                    Processed.TimeAxis2 = RawData.TimeAxis2;
                    Processed.Signal = ReconstructedSignal;
                    [Processed] = Lorentz2Gauss2D(Processed,Defaults.L2GParameters);
                    ReconstructedSignal = Processed.Signal;
                  end
                  %Use same apodization window as experimental data
                  ReconstructedSignal =  apodizationWin(ReconstructedSignal,Defaults.WindowType,Defaults.WindowDecay1,Defaults.WindowDecay2);
                  
                  %Compute spectrum for current parameter set
                  Reconstruction = abs(fftshift(fft2(ReconstructedSignal,Dimension1 + Defaults.ZeroFilling1,Dimension2 + Defaults.ZeroFilling2)));
                  
                  % if done for experimental data, then symmetrize
                  switch Defaults.SymmetrizationString
                    case 'Diagonal'
                      Reconstruction = (Reconstruction.*Reconstruction').^0.5;
                    case 'Anti-Diagonal'
                      Reconstruction = fliplr(fliplr(Reconstruction).*fliplr(Reconstruction)').^0.5;
                    case 'Both'
                      Reconstruction = (Reconstruction.*Reconstruction').^0.5;
                      Reconstruction = fliplr(fliplr(Reconstruction).*fliplr(Reconstruction)').^0.5;
                  end
                  
                  %Normalize and save spectrum
                  ReconstructedSpectra(:,:,TrialsCompleted + 1) = abs(Reconstruction)/max(max(abs(Reconstruction)));
                  
                  TrialsCompleted = TrialsCompleted + 1;
                  CPU_time = toc;
                  PreviousTimes(end + 1) = CPU_time;
                  %Include previous times to stabilize the estimate
                  CPU_time = mean(PreviousTimes);
                  TimeRemaining = CPU_time/60*(TotalTrials - TrialsCompleted);
                  Minutes = floor(TimeRemaining);
                  Seconds = round((TimeRemaining - Minutes)*60);
                  %Update user on approx. remaining validation time
                  set(StatusHandle,'string',sprintf('%i min %i sec remaining... (%.1f%% completed)',Minutes,Seconds,100*TrialsCompleted/TotalTrials)),drawnow
                end
              end
            end
          end
        end
      end
    end
  end
end

return