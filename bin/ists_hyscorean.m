% ists: barebones 1d stern ist reconstruction function.
function [Reconstruction, FunctionalValue] = ists_hyscorean (Signal, SubSamplingVector, mu, MaxIterations,handles)

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
% ISTS Reconstruction
%--------------------------------------------------------------------------

  %Loop over the outer indices.
  for Iteration = 1 : MaxIterations
    %Compute the current spectral estimate.
    Updater = SubSamplingVector.*(Signal - Reconstruction);
    ReconstructedSpectrum =  ReconstructedSpectrum + fft2(Updater);

    %Compute and store the functional values.
    [CurrentFunctionalValue, ReconstructedSpectrum] = ists_functional(ReconstructedSpectrum, Treshold);
    FunctionalValue = [FunctionalValue; CurrentFunctionalValue];

    %Update estimate and threshold.
    Reconstruction = ifft2(ReconstructedSpectrum);
    Treshold = Treshold*mu;
    Treshold = Treshold*(MaxIterations-Iteration)/MaxIterations;
    
    
        FrequencyAxis = linspace(-1/(2*handles.Data.TimeStep1),1/(2*handles.Data.TimeStep1),length(ReconstructedSpectrum));
    contour(handles.mainPlot,FrequencyAxis,FrequencyAxis,abs(fftshift(ReconstructedSpectrum)),handles.GraphicalSettings.Levels)
    set(handles.mainPlot,'ylim',[0 20],'xlim',[-20 20]),grid(handles.mainPlot,'on')
    hold(handles.mainPlot,'on'),plot(handles.mainPlot,FrequencyAxis,abs(FrequencyAxis),'k-.'),hold(handles.mainPlot,'off')
    figure(999),clf,plot(FunctionalValue),xlabel('Iterations'),ylabel('Functional')
    drawnow
    
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
