function [Reconstruction, FunctionalValues, NumberOfOperations] = camera_hyscorean (Signal,Schedule,NoiseLevel,SingleLagrangeMultiplier,BackgroundParameterVector,MultiplierBackgroundParameter,MaxOutIter,MaxInIter,NZeroFillings,Weights,handles)
%--------------------------------------------------------------------------  
% Convex Accelerated Maximum Entropy Reconstruction (CAMERA)
%--------------------------------------------------------------------------
% Algorithm for the reconstruction of one- or two-dimensional non-uniformly
% sampled (NUS) signals basde on maximization of the Hoch-Hore entropy [1].
% The signal is zero-filled during the procedure to double (or more) its 
% dimension size and after reconstruction it is truncated to its original 
% size.
%
% Literature:
%   [1] B. Worley, Journal of Magnetic Resonance 265, (2016), 90-98
%
% Adapted from Bradley Worley under the GNU GPL 3.0. license.
% by
% Luis Fabregas Ibanez, 2018  

if (nargin < 2)
  error('At least two arguments are required');
end

% Check whether one or two dimensional reconstruction
if ~isvector(Signal) || ~isvector(Schedule)
  isTwoDimensional = true;
else
  isTwoDimensional = false;
end

%Store the input vector lengths.
ScheduleLength = length(Schedule);
SignalDimension = length(Signal);

% check for an estimated noise argument.
if (nargin < 3 || isempty(NoiseLevel))
  % none supplied, use a default value.
  NoiseLevel = 1e-6 * norm(Signal);
end

% check for a lagrange multiplier argument.
if (nargin < 4)
  % none supplied, use a default value.
  SingleLagrangeMultiplier = [];
end

% check for a default background argument.
if (nargin < 5 || isempty(BackgroundParameterVector))
  % none supplied, use a default value.
  BackgroundParameterVector = 0.1 * NoiseLevel;
end

% check for a default line search argument.
if (nargin < 6 || isempty(MultiplierBackgroundParameter))
  % none supplied, use a default value.
  MultiplierBackgroundParameter = 1;
end

% check for an outer loop count argument.
if (nargin < 7 || isempty(MaxOutIter))
  % none supplied, use a default value.
  MaxOutIter = 1;
end

% check for an inner loop count argument.
if (nargin < 8 || isempty(MaxInIter))
  % none supplied, use a default value.
  MaxInIter = 1000;
end

% check for a zero-fill count argument.
if (nargin < 9 || isempty(NZeroFillings))
  % none supplied, use a default value.
  NZeroFillings = 1;
end

% check for a weight argument.
if (nargin < 10 || isempty(Weights))
  % none supplied, use a default value.
  Weights = @(idx) 1;
end

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------

% Set the output size.
OutputDimension = (2 ^ NZeroFillings) * SignalDimension;

%Increase dimensions of all variables
if isTwoDimensional
  SubSamplingGrid = zeros(OutputDimension);
  ZeroFiller = zeros(OutputDimension);
  ZeroFiller(1:size(Signal,1),1:size(Signal,2)) = Signal;
  Signal  = ZeroFiller;
  for i=1:size(Schedule,1)
    SubSamplingGrid(Schedule(i,1),Schedule(i,2)) = 1;
  end
else
  SubSamplingGrid = zeros(OutputDimension,1);
  Signal = [Signal; zeros(OutputDimension - SignalDimension, 1)];
  SubSamplingGrid(Schedule) = ones(size(Schedule));
end


% build a weighting vector.
W = Weights([0 : OutputDimension - 1]');

% build easy-to-understand transformation variables.
A = SubSamplingGrid .* W;
At = W .* SubSamplingGrid;
AtA = (W .^ 2) .* SubSamplingGrid;

% build an epsilon value.
vareps = sqrt(2 * ScheduleLength) * NoiseLevel;

% initialize the objective value vector.
FunctionalValues = [];
LagrangeMultiplierVector = [];

% initialize the operation count vector.
NumberOfOperations = 0;

%Initialize the reconstruction vectors.
Reconstruction = Signal;
y = Signal;

%Check that the defs vector is the correct size.
if (length(BackgroundParameterVector) ~= MaxOutIter)
  BackgroundParameterVector = repmat(BackgroundParameterVector(1), MaxOutIter, 1);
end

%--------------------------------------------------------------------------
% Algorithm
%--------------------------------------------------------------------------

% Loop over the outer indices.
for OuterIteration = 1 : MaxOutIter
  % Get the background paremeter value and compute the Lipschitz constant.
  CurrentBackgroundParameter = BackgroundParameterVector(OuterIteration);
  TresholdBackgroundparameter = 0.5 / CurrentBackgroundParameter;
  LipschitzConstant = 0.5 / (CurrentBackgroundParameter * MultiplierBackgroundParameter);
  
  % Compute the initial spectral estimate.
  ReconstructedSpectrum = fft2(Reconstruction);
  NumberOfOperations(end) = NumberOfOperations +1;
  
  % Loop over the inner indices.
  for InnerIteration = 1 : MaxInIter
    % Get functional state and gradient
    [CurrentFunctionalValue, SpectralGradient] = camera_functional(ReconstructedSpectrum, CurrentBackgroundParameter);
    FunctionalValues = [FunctionalValues; CurrentFunctionalValue];
    
    % Compute and store the time-domain gradient.
    Gradient = OutputDimension .* ifft2(SpectralGradient);
    NumberOfOperations(end) =  NumberOfOperations +1;
    
    % Compute the velocity factor.
    VelocityFactor = (InnerIteration - 1) / (InnerIteration + 2);
    
    ok =1;
    % Line-search loop
    while ok
      % compute a projected gradient update.
      if (isempty(SingleLagrangeMultiplier))
        LagrangeMultiplier = max(0, (LipschitzConstant/vareps) .* norm(Signal - A .* (Reconstruction - Gradient ./ LipschitzConstant)) - LipschitzConstant);
      else
        LagrangeMultiplier = SingleLagrangeMultiplier;
      end
      ReconstructionUpdate = (1 ./ (1 + (LagrangeMultiplier / LipschitzConstant) .* AtA)) .* ...
        (Reconstruction + (LagrangeMultiplier / LipschitzConstant) .* At .* Signal - Gradient ./ LipschitzConstant);
      
      % compute a potential x-update.
      ReconstructionUpdate = (1 + VelocityFactor) .* ReconstructionUpdate - VelocityFactor .* y;
      ReconstructedSpectrum = fft2(ReconstructionUpdate);
      FrequencyAxis = linspace(-1/(2*handles.Data.TimeStep1),1/(2*handles.Data.TimeStep1),length(ReconstructedSpectrum));
      contour(handles.mainPlot,FrequencyAxis,FrequencyAxis,abs(fftshift(ReconstructedSpectrum)),handles.GraphicalSettings.Levels)
      set(handles.mainPlot,'ylim',[0 20],'xlim',[-20 20]),grid(handles.mainPlot,'on')
      hold(handles.mainPlot,'on'),plot(handles.mainPlot,FrequencyAxis,abs(FrequencyAxis),'k-.'),hold(handles.mainPlot,'off')
%     figure(999),clf,plot(FunctionalValues),xlabel('Iterations'),ylabel('Functional')

      drawnow
      NumberOfOperations(end) =  NumberOfOperations +1;
      
      %Check for a primary termination criterion.
      ok = 1;
      if (LipschitzConstant >= TresholdBackgroundparameter)
        break; % Breaks while loop
      end
      
      %Check for a secondary termination criterion.
      [NewFunctionalValue, ~] = camera_functional(ReconstructedSpectrum, CurrentBackgroundParameter);
      if (NewFunctionalValue > CurrentFunctionalValue)
        % backtrack by a fixed factor of two.
        LipschitzConstant = min(TresholdBackgroundparameter, 2 * LipschitzConstant);
        ok = 0;
      end
    end
    % store the accepted new values.
    y = (ReconstructionUpdate + VelocityFactor .* y) ./ (1 + VelocityFactor);
    Reconstruction = ReconstructionUpdate;
    
    %Check for a final termination criterion
    if InnerIteration>1
      FunctionalDecrease = FunctionalValues(end)-FunctionalValues(end-1);
      if abs(FunctionalDecrease) < FunctionalValues(1)/1e6 || FunctionalDecrease>0
        break; % Finishes algorithm
      end
    end
    
  end
  
  % update the operation count vector.
  NumberOfOperations = NumberOfOperations +1;
end

%--------------------------------------------------------------------------  
% Truncate & Return
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

% Truncate the operation count vector.
NumberOfOperations(end) = [];
end
