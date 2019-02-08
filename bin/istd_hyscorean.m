% ists: barebones 1d stern ist reconstruction function.
function [ReconstructedSignal, FunctionalValues] = ists_hyscorean (Signal, SubSamplingVector, mu, MaxIterations,handles)

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
%       figure(99),clf,subplot(121),plot(FunctionalValues),subplot(122),plot(log10(abs(RelativeFunctionalDecrease))),drawnow
      if  abs(RelativeFunctionalDecrease(Iteration))<1e-7  % || RelativeFunctionalDecrease(InnerIteration)>0
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
