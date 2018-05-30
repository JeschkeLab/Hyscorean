function [Processed]=Lorentz2Gauss2D(Processed,Parameters)
%Two-dimensional Lorentz-to-Gauss transformation
%Input---------------------------------------------------------------------
%---Processed: structure with the required fields...
%-----.Signal: Two-dimensional time trace [NxN]
%-----.TimeAxis1/2: Time axis vectors along each dimension in microseconds [1xN]
%---Parameters: structure with the required fields...
%-----.tauFactor1/2: Constants for computation of tau parameters 
%-----.sigmaFactor1/2: Constants for computation of sigma parameters 
%Output-------------------------------------------------------------------- 
%---Processed: structure with fields...
%-----.Signal: LtG Transformed two-dimensional time trace [NxN]
%-----.TimeAxis1/2: Time axis vectors along each dimension in microseconds [1xN]
%--------------------------------------------------------------------------
%Introducing tauFactor1 or tauFactor2 equals to zero skips the
%transformation procedure
%
% TrierAnalysis 2017, L. Fabregas

tauFactor2 = Parameters.tauFactor1;
sigmaFactor2 = Parameters.sigmaFactor1;
tauFactor1 = Parameters.tauFactor2;
sigmaFactor1 = Parameters.sigmaFactor2;

Dimension2 = size(Processed.Signal,2);

%Lorentz-to-Gauss transformation
if tauFactor1~=0 || tauFactor2~=0 
  %Get LtG parameters
  tau1 = max(Processed.TimeAxis1)*tauFactor1;
  sigma1 = sigmaFactor1/tau1;
  tau2 = max(Processed.TimeAxis2)*tauFactor2;
  sigma2 = sigmaFactor2/tau2;
  
  %Construct filters
  Lorentz2Gauss1 = exp((Processed.TimeAxis1')/tau1 - sigma1^2*Processed.TimeAxis1'.^2/2);
  Lorentz2Gauss2 = exp((Processed.TimeAxis2')/tau2 - sigma2^2*Processed.TimeAxis2'.^2/2);
  
  %Perform transformation
  for iDimension2 = 1:Dimension2
    Processed.Signal(:,iDimension2) = Processed.Signal(:,iDimension2).*Lorentz2Gauss1*Lorentz2Gauss2(iDimension2);
  end
  
  
end