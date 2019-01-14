%-----------------------------------------------------------------------
% Construct on-grid Non-Uniform Sampling (NUS) for HYSCORE measurements
%-----------------------------------------------------------------------
% Luis Fabregas, 2018
%-----------------------------------------------------------------------

% Parameters
%-----------------------------------------------------------------------

FileName = 'NUSgrid_PRODEL_10x10_example';

%Grid greatest-common denominator (GCD) [ns]
TimeStep1 = 16;
TimeStep2 = 16;

%Dimensionality
Dimension1 = 10;
Dimension2 = 10;

%NUS sampler settings
SamplingDensity = 0.25;
Envelope = 'expdiag';
Decay = [];

% Construction
%-----------------------------------------------------------------------
TwoDimensionalFlag = true;
RandomGenerator = 'lhs';

%Construct time axes
t1_axis = linspace(0,TimeStep1*(Dimension1 -1),Dimension1);
t2_axis = linspace(0,TimeStep2*(Dimension2 -1),Dimension2);

%Generate linear-conditioned random NUS grid
 [SamplingGrid,Decay] = NUS_Scheduler(SamplingDensity,t1_axis/1000,Envelope,Decay,TwoDimensionalFlag,RandomGenerator);

 %Plot resulting sampling grid
PointsSampled = length(find(SamplingGrid>0));
FullSampling = Dimension1*Dimension2;
Sampling = PointsSampled/FullSampling*100;
figure(122),clf
imagesc(t1_axis/1000,t2_axis/1000,1-SamplingGrid'),colormap('gray'),
try
title(sprintf('NUS-Schedule @%i%% (%s-matched, Decay=%.2f us)',round(Sampling),Envelope,Decay))
catch
end
xlabel('t_1 [\mus]'),ylabel('t_2 [\mus]')
% axis off

%Save variables to structure and then to file
NUSgrid = struct();
NUSgrid.SamplingGrid = SamplingGrid;
NUSgrid.Dimension1 = Dimension1;
NUSgrid.Dimension2 = Dimension2;
NUSgrid.t2Timings = t2_axis;
NUSgrid.t1Timings = t1_axis;
save(strcat(FileName,'.mat'),'NUSgrid')

%Get schedule and timings
[t1_indices,t2_indices] = find(SamplingGrid==1);
t1_timings = t1_axis(t1_indices);
t2_timings = t2_axis(t2_indices);

%Save them to DSC file to be loaded by PRODEL program
eprsave(FileName,t1_timings,t2_timings,FileName)

