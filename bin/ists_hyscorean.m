function [Reconstruction, FunctionalValue] = ists_hyscorean (Signal, SubSamplingVector, mu, MaxIterations,NZeroFillings)
%==========================================================================  
% Stern Iterative Soft-Thresholding (IST-S)
%==========================================================================
% Algorithm for the reconstruction of one- or two-dimensional non-uniformly
% sampled (NUS) signals basde on maximization of the l1-norm functional.
% The signal is zero-filled during the procedure to double its dimension 
% size and after reconstruction it is truncated to its original size. 
%==========================================================================
%
% Adapted from Bradley Worley under the GNU GPL 3.0. license.
% 
% Copyright (C) 2019, Luis Fabregas Ibanez, Hyscorean 
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

if (nargin < 2)
  error('At least two arguments are required');
end
% check for a zero-fill count argument.
if (nargin < 5 || isempty(NZeroFillings))
  % none supplied, use a default value.
  NZeroFillings = 0;
end

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------
  %Store the input vector length.
  SignalDimension = length(Signal);
  %Check if one or two dimensional data
  isTwoDimensional = size(Signal,2)>1;
OutputDimension = (2 ^ NZeroFillings) * SignalDimension;
  %Increase dimensions of all variables
  if isTwoDimensional
    ZeroFiller = zeros(OutputDimension);
    ZeroFiller(1:size(SubSamplingVector,1),1:size(SubSamplingVector,2)) = SubSamplingVector;
    SubSamplingVector = ZeroFiller;
    ZeroFiller = zeros(OutputDimension);
    ZeroFiller(1:size(Signal,1),1:size(Signal,2)) = Signal;
    Signal  = ZeroFiller;
    ReconstructedSpectrum = zeros(OutputDimension);
    Reconstruction = zeros(OutputDimension);
  else
    ZeroFiller = zeros(OutputDimension,1);
    ZeroFiller(1:size(SubSamplingVector,2),1) = SubSamplingVector;
    SubSamplingVector = ZeroFiller;
    Signal = [Signal; zeros(OutputDimension - SignalDimension, 1)];
    ReconstructedSpectrum = zeros(OutputDimension, 1);
    Reconstruction = zeros(OutputDimension, 1);
  end
  
  % build an initial threshold value.
  Treshold = max(max(abs(fft2(Signal))));
  % initialize the objective value vector.
  FunctionalValue = [];
  
%--------------------------------------------------------------------------  
% IST-S Reconstruction
%--------------------------------------------------------------------------

  %Loop over the outer indices.
  for Iteration = 1 : MaxIterations
    %Compute the current spectral estimate.
    Updater = SubSamplingVector.*(Signal - Reconstruction);
    Updater =  fft2(Updater);

    %Compute and store the functional values.
    [CurrentFunctionalValue, Updater] = ists_functional(Updater, Treshold);
    ReconstructedSpectrum = ReconstructedSpectrum + Updater;
    FunctionalValue = [FunctionalValue; CurrentFunctionalValue];

    % Should some point become NaN, set it to zero otherwise ifft2 will set
    % everything to NaN leadin to a crash later
    ReconstructedSpectrum(isnan(ReconstructedSpectrum)) = 0;
    
    %Update estimate and threshold.
    Reconstruction = ifft2(ReconstructedSpectrum);
    Treshold = Treshold*mu;
    Treshold = Treshold*(MaxIterations-Iteration)/MaxIterations;

    if Iteration>1
    FunctionalDecrease = FunctionalValue(end) - FunctionalValue(end-1);
    if isnan(FunctionalValue(end)) || round(FunctionalValue(end),7)==0 || FunctionalDecrease>0
      break
    end
    end
  end

%--------------------------------------------------------------------------  
%Truncation and return
%--------------------------------------------------------------------------

  if isTwoDimensional
    for i=(SignalDimension + 1):size(Reconstruction,2)
      Reconstruction(:, SignalDimension + 1) = [];
    end
    for i=(SignalDimension + 1):size(Reconstruction,1)
      Reconstruction(SignalDimension + 1, :) = [];
    end
  else
    Reconstruction(SignalDimension + 1 : end) = [];
  end

end
