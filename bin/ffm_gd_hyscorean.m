function [Reconstruction, FunctionalValues] = ffm_gd_hyscorean(Signal,Schedule,BackgroundParameter,MaxIter)
%==========================================================================  
% FFM-GD (Fast Forward Maximum Entropy - Gradient Descent) Reconstruction
%==========================================================================
% Algorithm for the reconstruction of one- or two-dimensional non-uniformly
% sampled (NUS) signals basde on maximization of the Hoch-Hore entropy.
% This method solves the FFM problem [1] by Broyden–Fletcher–Goldfarb–Shanno 
% (BFGS) gradient descent method [2].
% The signal is zero-filled during the procedure to double its dimension 
% size and after reconstruction it is truncated to its original size. 
%==========================================================================
% Literature:
%  [1] N.M. Balsgart, T. Vosegaard, Journal of Magnetic Resonance 223, 
%      2012, 164-169  
%  [2] Fletcher, Roger, Practical methods of optimization, 1987, New York
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

% Check whether one or two dimensional reconstruction
if ~isvector(Signal) || ~isvector(Schedule)
  isTwoDimensional = true;
else
  isTwoDimensional = false;
end

%Check if user-supplied else use same default as camera
if (nargin < 3 || isempty(BackgroundParameter))
  NoiseLevel = 1e-5*norm(Signal);
  BackgroundParameter = 0.1*NoiseLevel;
end

%Check if user-supplied else use default
if (nargin < 4 || isempty(MaxIter))
  MaxIter = 500;
end

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------

%Store the input vector length.
N = length(Signal);

%Increase dimensions of all variables
if isTwoDimensional
  SubSamplingGrid = zeros(2*N);
  ZeroFiller = zeros(2*N);
  ZeroFiller(1:size(Signal,1),1:size(Signal,2)) = Signal;
  Signal  = ZeroFiller;
  for i=1:size(Schedule,1)
    SubSamplingGrid(Schedule(i,1),Schedule(i,2)) = 1;
  end
else
  SubSamplingGrid = zeros(2*N,1);
  Signal = [Signal; zeros(N, 1)];
  SubSamplingGrid(Schedule) = ones(size(Schedule));
end

% initialize the objective value vector.
FunctionalValues = [];

% initialize the reconstruction vectors.
Reconstruction = Signal;

% compute the Lipschitz constant.
LipschitzConstant = 0.5/BackgroundParameter;

%--------------------------------------------------------------------------
% Algorithm
%--------------------------------------------------------------------------

% loop over the inner indices.
for Iteration = 1:MaxIter
  
  %Compute the current spectral estimate.
  ReconstructedSpectrum = fft2(Reconstruction);
  
  %Get functional state and gradient
  [CurrentFunctionalValue, SpectralGradient] = camera_functional(ReconstructedSpectrum,BackgroundParameter);
  
  %Compute and store time-domain gradient.
  Gradient = (2*N).*ifft2(SpectralGradient);
  Gradient = (1/LipschitzConstant).*Gradient.*(1 - SubSamplingGrid);
  FunctionalValues = [FunctionalValues; CurrentFunctionalValue];
  
  %Update the reconstruction
  Reconstruction  = Reconstruction - Gradient;
  
  %Stopping conditions
  if Iteration>1
    NormalizedFunctionalValues = FunctionalValues/max(FunctionalValues);
    RelativeFunctionalDecrease(Iteration) = NormalizedFunctionalValues(end) - NormalizedFunctionalValues(end-1);
    if  abs(RelativeFunctionalDecrease(Iteration)) < 1e-7 
      break; % Finishes algorithm
    end
  end
  
end

%--------------------------------------------------------------------------  
% Truncate & Return
%--------------------------------------------------------------------------

%Truncate the reconstructed vector.
if isTwoDimensional
  for i = (N + 1):size(Reconstruction,2)
    Reconstruction(:,N + 1) = [];
  end
  for i = (N + 1):size(Reconstruction,1)
    Reconstruction(N + 1,:) = [];
  end
else
  Reconstruction(N + 1:end) = [];
end

end
