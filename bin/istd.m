% ists: barebones 1d stern ist reconstruction function.
function [Reconstruction, FunctionalValue] = istd (Signal, SubSamplingVector, mu, MaxIterations)

if (nargin < 2)
  error('At least two arguments are required');
end

%--------------------------------------------------------------------------  
% Preparations
%--------------------------------------------------------------------------
  %Store the input vector length.
  N = length(Signal);
  %Check if one or two dimensional data
  isTwoDimensional = size(Signal,2)>1;

  %Increase dimensions of all variables
  if isTwoDimensional
    ZeroFiller = zeros(2*N);
    ZeroFiller(1:size(SubSamplingVector,1),1:size(SubSamplingVector,2)) = SubSamplingVector;
    SubSamplingVector = ZeroFiller;
    ZeroFiller = zeros(2*N);
    ZeroFiller(1:size(Signal,1),1:size(Signal,2)) = Signal;
    Signal  = ZeroFiller;
    ReconstructedSpectrum = zeros(2*N);
    Reconstruction = zeros(2*N);
  else
    ZeroFiller = zeros(2*N,1);
    ZeroFiller(1:size(SubSamplingVector,2),1) = SubSamplingVector;
    SubSamplingVector = ZeroFiller;
    Signal = [Signal; zeros(N, 1)];
    ReconstructedSpectrum = zeros(2*N, 1);
    Reconstruction = zeros(2*N, 1);
  end
  
  % build an initial threshold value.
  Treshold = max(max(abs(fft2(Signal))));
  % initialize the objective value vector.
  FunctionalValue = [];
  
%--------------------------------------------------------------------------  
% IST-D Reconstruction
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
    if isnan(FunctionalValue(end)) || round(FunctionalValue(end),8)==0
      break
    end
    %Update estimate and threshold.
    Reconstruction = ifft2(ReconstructedSpectrum);
    Treshold = Treshold*mu;
    Treshold = Treshold*(MaxIterations-Iteration)/MaxIterations;
  end

%--------------------------------------------------------------------------  
%Truncation and return
%--------------------------------------------------------------------------

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
