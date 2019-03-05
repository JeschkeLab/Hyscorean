function [NUSgrid,Decay,PDF] = NUS_Scheduler(SamplingDensity,TimeAxis,Envelope,Decay,TwoDimensionalFlag,RandomGenerator,BME)
%Construct a non-uniform sampling schedule for one-dimensional or
%two-dimensional measurements. Envelope-matched sampling (EMS) is available
%for different probability density functions matched to the time-decay
%constant. Using the 'random' option employs purely non-matched sampling.
%The schedule is constructed in a loop based on a minimal-rank criterion
%until the desired coverage (i.e. sampling density) is achieved.
%
% Luis Fabregas, 2018

%If not specified otherwise, default grid is one-dimensional
if nargin < 5
  TwoDimensionalFlag = false;
end
%If not specified, take T2 as half of the maximal measurement time
if isempty(Decay)
  Decay = max(TimeAxis)/2;
end
%If not specified otherwise, default sampling is random
if nargin < 6
  RandomGenerator = 'rand';
end
%Preparations
%-----------------------------------------------------------------------

%Get dimensionality
Dimension = numel(TimeAxis);

%Fix random number generator and seed
rng(1,'Twister')

%Compute sampling probability density function envelope
switch Envelope
  case 'random'
    PDF = ones(1,numel(TimeAxis));
  case 'linear'
    PDF = fliplr(TimeAxis);
  case 'exponential'
    PDF = exp(-TimeAxis/Decay);
  case 'expdiag'
    PDF = exp(-TimeAxis/Decay);
  case 'sine'
    PDF = 1 - sin(TimeAxis/(2*Decay));
  case 'gaussian'
    PDF = exp(-TimeAxis.^2/(4*Decay^2));
  case 'cosine'
    PDF = cos(TimeAxis/(2*Decay));
  case 'BMS'
    PDF = BME./max(max(BME));
end

%Construct schedule
%-----------------------------------------------------------------------

%Two-dimensional grid
if TwoDimensionalFlag
  if size(PDF,1)~=size(PDF,2)
  PDF = PDF.*PDF';
  end
  switch RandomGenerator
    case 'rand'
      Ranks = rand(Dimension,Dimension).^PDF;
    case 'lhs'
      Ranks = lhsdesign(Dimension,Dimension).^PDF;
  end
  if strcmp(Envelope,'expdiag')
    Ranks = Ranks.*(exp((TimeAxis - TimeAxis'))+exp(-(TimeAxis - TimeAxis')));
  end
  FullSampling = Dimension*Dimension;

  NUSgrid = zeros(Dimension);
  %Always sample first and last point
  NUSgrid(1,1) = 1;
  NUSgrid(end,end) = 1;

  a = round(FullSampling * SamplingDensity);
  [~, i] = mink(Ranks(:), a);
  NUSgrid(i) = 1;
else
  %One-dimensional grid
  switch RandomGenerator
    case 'rand'
      Ranks = rand(1,Dimension).^(PDF');
    case 'lhs'
      Ranks = lhsdesign(1,Dimension).^(PDF');
  end
  FullSampling = Dimension;

  NUSgrid = zeros(1,Dimension);
  %Always sample first and last point
  NUSgrid(1) = 1;
  NUSgrid(end) = 1;

  a = round(FullSampling * SamplingDensity);
  [~, i] = mink(Ranks(:), a);
  NUSgrid(i) = 1;
end
