function Reconstruction =  maxEntReconstruction(Signal,BackgroundParameter,LagrangeMultiplier)
%--------------------------------------------------------------------------
%Maximum Entropy (MaxEnt) Reconstruction 
%--------------------------------------------------------------------------
%Maximal Entropy Reconstruction function for reconstruction of 
%non-uniform sampled (NUS) TRIER signals
%Adapted from:
% [1] Kubat et al. JMR, 186, (2007), 201-211
%Luis Fabregas, TrierAnalysis 2018
%--------------------------------------------------------------------------
%(WARNING: This function supports only zero-augmented NUS signals)

if nargin<3
  warning('No Lagrange multiplier given. Assuming a default value of 25.')
  LagrangeMultiplier = 25;
end
if nargin<2
  warning('No BackgroundParameter given. Assuming a default value of 1.')
  BackgroundParameter = 1;
end

% Preparation
%----------------------------------------------------------------------

%Get dimensionality
[Dimension1,Dimension2] = size(Signal);

%Construct initial guess
Reconstruction = zeros(Dimension1,Dimension2);

%Set large evaluation limits (required for convergence) 
SolverOptions = optimset('MaxFunEvals',20000,'Display','on','MaxIter',20000);

%Call fmincon (nonlinear solver)
Reconstruction = fmincon(@(Reconstruction) MaxEntFunctional(Reconstruction,Signal,BackgroundParameter,LagrangeMultiplier),Reconstruction,[],[],[],[],[],[],[],SolverOptions);

end

% MaxEnt Reconstruction Functional
%----------------------------------------------------------------------
function Functional = MaxEntFunctional(Reconstruction,Signal,BackgroundParameter,LagrangeMultiplier)

%Construct auxiliary elements
MockSignal = ifft2(Reconstruction);
ScaledReconstruction = abs(Reconstruction)/BackgroundParameter;

%Construct LSQ-functional with Frobenius norm (instead of Manhattan norm in [1])
LSQError  =  norm(MockSignal - Signal,'fro')^2;
Entropy = sum(sum(ScaledReconstruction.*log((ScaledReconstruction + sqrt(4 + ScaledReconstruction.^2))/2) - sqrt(4 + ScaledReconstruction.^2)));

%Maximal Entropy Reconstruction Functional (take negative value of functional in order to maximize with the fmincon solver)
Functional = -(Entropy  - LagrangeMultiplier*LSQError);

end