function [ReconstructedSignal, FunctionalValues] = istd_hyscorean (Signal, SubSamplingVector, mu, MaxIterations,handles)
%==========================================================================  
% Drori Iterative Soft-Thresholding (IST-D)
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

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------
%Store the input vector length.
N = length(Signal);
%Check if one or two dimensional data
isTwoDimensional = ~isvector(Signal);

%Increase dimensions of all variables
if isTwoDimensional
  ZeroFiller = zeros(2*N);
  ZeroFiller(1:size(SubSamplingVector,1),1:size(SubSamplingVector,2)) = SubSamplingVector;
  SubSamplingVector = ZeroFiller;
  ZeroFiller = zeros(2*N);
  ZeroFiller(1:size(Signal,1),1:size(Signal,2)) = Signal;
  Signal  = ZeroFiller;
  ReconstructedSpectrum = zeros(2*N);
  ReconstructedSignal = zeros(2*N);
else
  ZeroFiller = zeros(2*N,1);
  ZeroFiller(1:size(SubSamplingVector,2),1) = SubSamplingVector;
  SubSamplingVector = ZeroFiller;
  Signal = [Signal; zeros(N, 1)];
  ReconstructedSpectrum = zeros(2*N, 1);
  ReconstructedSignal = zeros(2*N, 1);
end
% build an initial threshold value.
Threshold = max(max(abs(fft2(Signal))));
% initialize the objective value vector.
FunctionalValues = [];

%--------------------------------------------------------------------------
% IST-D Reconstruction
%--------------------------------------------------------------------------

%Loop over the outer indices.
for Iteration = 1 : MaxIterations
  %Compute the current spectral estimate.
  Updater = SubSamplingVector.*(Signal - ReconstructedSignal);
  ReconstructedSpectrum =  ReconstructedSpectrum + fft2(Updater);
  %Compute and store the functional values.
  [CurrentFunctionalValue, ReconstructedSpectrum] = ists_functional(ReconstructedSpectrum, Threshold);
  FunctionalValues = [FunctionalValues; CurrentFunctionalValue];
  
  % Should some point become NaN, set it to zero otherwise ifft2 will set
  % everything to NaN leadin to a crash later
  ReconstructedSpectrum(isnan(ReconstructedSpectrum)) = 0;
  
  
  %Update estimate and threshold.
  ReconstructedSignal = ifft2(ReconstructedSpectrum);
  Threshold = Threshold*mu;
  Threshold = Threshold*(MaxIterations-Iteration)/MaxIterations;
  
  if Iteration>10
    NormalizedFunctionalValues = FunctionalValues/max(FunctionalValues);
    RelativeFunctionalDecrease(Iteration) = NormalizedFunctionalValues(end)-NormalizedFunctionalValues(end-1);
    if  abs(RelativeFunctionalDecrease(Iteration))<1e-7
      break; % Finishes algorithm
    end
  end
  
end

%--------------------------------------------------------------------------
%Truncation and return
%--------------------------------------------------------------------------

if isTwoDimensional
  for i=(N + 1):size(ReconstructedSignal,2)
    ReconstructedSignal(:, N + 1) = [];
  end
  for i=(N + 1):size(ReconstructedSignal,1)
    ReconstructedSignal(N + 1, :) = [];
  end
else
  ReconstructedSignal(N + 1 : end) = [];
end

end
