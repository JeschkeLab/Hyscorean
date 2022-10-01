function Processed = Lorentz2Gauss2D(Processed,Parameters)
% Two-dimensional Lorentz-to-Gauss transformation
%
% Input:
%   Processed: structure with the following fields
%     .Signal: Two-dimensional time trace [NxN]
%     .TimeAxis1: Time axis vector along first dimension, in microseconds [1xN]
%     .TimeAxis2: Time axis vector along second dimension, in microseconds [1xN]
%   Parameters: structure with the required fields
%     .tauFactor1/2: Constants for computation of tau parameters 
%     .sigmaFactor1/2: Constants for computation of sigma parameters
%
% Output:
%   Processed: structure with the following fields
%     .Signal: LtG Transformed two-dimensional time trace [NxN]
%     .TimeAxis1/2: Time axis vectors along each dimension in microseconds [1xN]
%
% Introducing tauFactor1 or tauFactor2 equals to zero skips the
% transformation procedure
%
% TrierAnalysis 2017, L. Fabregas

tauFactor2 = Parameters.tauFactor1;
sigmaFactor2 = Parameters.sigmaFactor1;
tauFactor1 = Parameters.tauFactor2;
sigmaFactor1 = Parameters.sigmaFactor2;

if tauFactor1==0 && tauFactor2==0 
  return
end

t1 = Processed.TimeAxis1;
t2 = Processed.TimeAxis2;

% Get LtG parameters
tauL1 = max(t1)*tauFactor1;
sigma1 = sigmaFactor1/tauL1;
tauL2 = max(t2)*tauFactor2;
sigma2 = sigmaFactor2/tauL2;

% Construct Lorentz-to-Gauss filter and perform transformation
Lorentz2Gauss1 = exp(t1/tauL1).*exp(-sigma1^2*t1.^2/2);
Lorentz2Gauss2 = exp(t2/tauL2).*exp(-sigma2^2*t2.^2/2);
Lorentz2Gauss = Lorentz2Gauss1(:) * Lorentz2Gauss2(:).';
Processed.Signal = Processed.Signal.*Lorentz2Gauss;

end
