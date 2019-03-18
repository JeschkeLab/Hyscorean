function [Reconstruction, FunctionalValues] = ffm_cg_hyscorean (Signal, Schedule, BackgroundParameter, MaxIter,handles)
%==========================================================================  
% FFM-CG (Fast Forward Maximum Entropy - Conjugate Gradient) Reconstruction
%==========================================================================
% Algorithm for the reconstruction of one- or two-dimensional non-uniformly
% sampled (NUS) signals basde on maximization of the Hoch-Hore entropy while
% enforcing strict accordancy with the experimental data.
% This method solves the FFM problem [1] by using Polak-Ribiere's conjugate
% gradient method [2].
%==========================================================================
% Literature:
%  [1] N.M. Balsgart, T. Vosegaard, Journal of Magnetic Resonance 223, 
%      2012, 164-169  
%  [2] E. Polak, G. Ribière, Rev. Francaise Informat Recherche 
%      Operationelle, (1969), 35–43
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

%Check if user-supplied else use default
if (nargin < 4 || isempty(MaxIter))
  MaxIter = 500;
end

%Check if user-supplied else use same default as camera
if (nargin < 3 || isempty(BackgroundParameter))
  NoiseLevel = 1e-6 * norm(Signal);
  BackgroundParameter = 0.1*NoiseLevel;
end
%--------------------------------------------------------------------------  
% Preparations
%--------------------------------------------------------------------------

% store the input vector length.
N = length(Signal);

%Increase dimensions of all variables
if isTwoDimensional
  SearchDirection = zeros(2*N);
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
  SearchDirection = zeros(2 * N, 1);
end

%Initialize the objective value vector.
FunctionalValues = [];

%Initialize the reconstruction vectors.
Reconstruction = Signal;

%Compute the Lipschitz constant 
LipschitzConstant = 0.5/BackgroundParameter;

%--------------------------------------------------------------------------  
% Algorithm
%--------------------------------------------------------------------------

% loop over the inner indices.
for Iteration = 1 : MaxIter
  
  % Should some point become NaN, set it to zero otherwise fft2 will set
  % everything to NaN leadin to a crash later
  Reconstruction(isnan(Reconstruction)) = 0;
  
  %Compute the current spectral estimate.
  ReconstructedSpectrum = fft2(Reconstruction);
  
  %Get functional state and gradient
  [CurrentFunctionalValue, SpectralGradient] = camera_functional(ReconstructedSpectrum, BackgroundParameter);
  
  % Should some point become NaN, set it to zero otherwise ifft2 will set
  % everything to NaN leadin to a crash later
  SpectralGradient(isnan(SpectralGradient)) = 0;
  
  
  %Compute the time-domain gradient.
  Gradient = (2*N).*ifft2(SpectralGradient);
  Gradient = (1 / LipschitzConstant).*Gradient.*(1 - SubSamplingGrid);
  FunctionalValues = [FunctionalValues; CurrentFunctionalValue];
  
  %Conjugate gradient factor according to PR method
  if (Iteration > 1)
    PolakRibiereFactor = dot(Gradient-PrevGradient,Gradient)/dot(PrevGradient,PrevGradient);
  else
    PolakRibiereFactor = 0;
  end
  
  % Update the reconstruction
  SearchDirection = Gradient + PolakRibiereFactor.*SearchDirection;
  Reconstruction  = Reconstruction - SearchDirection;
  
  %Store the previous gradient for next iteration
  PrevGradient = Gradient;
  
  %Stopping conditions
  if Iteration>1
    NormalizedFunctionalValues = FunctionalValues/max(FunctionalValues);
    RelativeFunctionalDecrease(Iteration) = NormalizedFunctionalValues(end)-NormalizedFunctionalValues(end-1);
    if  abs(RelativeFunctionalDecrease(Iteration)) < 1e-7 
      break; % Finishes algorithm
    end
  end
  
end

%--------------------------------------------------------------------------  
% Truncate & Return
%--------------------------------------------------------------------------

%Truncate the reconstructed vector or matrix.
if isTwoDimensional
  for i=(N + 1):size(Reconstruction,2)
    Reconstruction(:, N + 1) = [];
  end
  for i=(N + 1):size(Reconstruction,1)
    Reconstruction(N + 1, :) = [];
  end
else
  Reconstruction(N + 1 : end) = [];
end

end
