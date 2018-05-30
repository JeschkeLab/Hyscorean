function ReconstructedSignal = camera(Signal,SamplingMatrix,BackgroundParameter)
%--------------------------------------------------------------------------
%Convex Accelerated Maximum Entropy Reconstruction Algorithm (CAMERA)
%--------------------------------------------------------------------------
%Algorithm for the regularization/reconstruction of time-domain signals
%obtained by non-uniform sampling (NUS). This method requires on-grid NUS. 
%Adapted from:
% [1] B. Worley, JMR 265, (2016), 90-98
%Luis Fabregas, TrierAnalysis 2018
%--------------------------------------------------------------------------

if size(Signal) > size(SamplingMatrix)
  error('Dimensionality of sampling matrix cannot exceed that of the measured signal.')
end

if nargin<3
  warning('No input background parameter given. Assuming a default value of 1.')
  BackgroundParameter = 1;
end

% Preparations
%----------------------------------------------------------------------
%Check if signal is zero-agumented
if size(Signal) ~= size(SamplingMatrix)
  %If not perform zero-augmentation according to sampling matrix
  Signal = zeroAugmentation(Signal,SamplingMatrix);
end

%Get constants
Dimension1 = size(Signal,1);
Dimension2 = size(Signal,2);
%Noise deviation requires large numbers (1e6 - 1e9) in order to obtain good results
NoiseDeviation = 7e9;
EstimatedUncertainty = NoiseDeviation*sqrt(length(find(SamplingMatrix>0)));

%Initialize reconstruction models to zero-augmented signal
ReconstructedSignal = Signal;
ProjectedProximalStep = ReconstructedSignal;

%Construct upper Lipschitz constant boundary
LipschitzBound = 1/(2*BackgroundParameter);
%Automatically initiallize Lipschitz constant (reduce the initial constant to accelerate line search)
LipschitzConstant = LipschitzBound*1e-4;

% CAMERA Iterations
%----------------------------------------------------------------------
for Iteration = 1:1000
  
  %Allocate hypercomplex modulus of the reconstructed spectrum
  HyperComplexModulus = abs(fft2(ReconstructedSignal));
  
  %Compute Hoch-Hore entropy and entropy gradient
  Entropy = HyperComplexModulus.*log(HyperComplexModulus/(2*BackgroundParameter) + ...
    sqrt(1 + (HyperComplexModulus/(2*BackgroundParameter)).^2)) + sqrt(HyperComplexModulus.^2 + 4*BackgroundParameter^2);
  
  EntropyGradient = fft2(ReconstructedSignal)./HyperComplexModulus.*log(HyperComplexModulus/(2*BackgroundParameter) + ...
    sqrt(1 + (HyperComplexModulus/(2*BackgroundParameter)).^2));
  
  %Transform entropy gradient into time-domain
  TimeDomainGradient = -ifft2(EntropyGradient);
  
  %Store current proximal step before updating
  PreviousProjectedProximalStep = ProjectedProximalStep;
  
  while true
    
    %Compute Lagrange multiplier
    LagrangeMultiplier = LipschitzConstant/EstimatedUncertainty*norm(Signal - SamplingMatrix*ReconstructedSignal + ...
      1/LipschitzConstant*SamplingMatrix*TimeDomainGradient) - LipschitzConstant;
    %Project the Lagrange multipliers into positive orthant
    if LagrangeMultiplier < 0
      LagrangeMultiplier = 0;
    end
    %Update the projected proximal step
    ProjectedProximalStep = (eye(Dimension1,Dimension2) +  LagrangeMultiplier/LipschitzConstant*(SamplingMatrix')*SamplingMatrix)...
      \(ReconstructedSignal + LagrangeMultiplier/LipschitzConstant*Signal -  1/LipschitzConstant*TimeDomainGradient);
    
    %Update the reconstructed time-domain signal
    ReconstructedSignal = ProjectedProximalStep + (Iteration - 1)/(Iteration + 2)*(ProjectedProximalStep - PreviousProjectedProximalStep);
    
    %Compute the corresponding entropy
    HyperComplexModulus = abs(fft2(ReconstructedSignal));
    NewEntropy = HyperComplexModulus.*log(HyperComplexModulus/(2*BackgroundParameter) + ...
      sqrt(1 + (HyperComplexModulus/(2*BackgroundParameter)).^2)) + sqrt(HyperComplexModulus.^2 + 4*BackgroundParameter^2);
    
    %If the new iterate has produced a decrease in Hoch-Hore entropy
    %or
    %Lipschitz constant has reached its boundary go to next iterate
    if -sum(sum(NewEntropy)) > -sum(sum(Entropy)) || LipschitzConstant==LipschitzBound
      break;
    end
    
    %Otherwise update the local Lipschitz constant and restart the iteration
    LipschitzConstant = 2*LipschitzConstant;
    if LipschitzConstant > LipschitzBound
      LipschitzConstant = LipschitzBound;
    end
  end
  
end