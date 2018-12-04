function [Data] = integrateEcho(Data,Integration,options)

if nargin<3
  options = struct();
end
if ~isfield(options,'FittingTime')
  options.FittingTime = max(Data.EchoAxis);
end
if ~isfield(options,'Boxcar')
  options.Boxcar = 0;
end

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------

%Find where to start fitting the echo
TimeIndex = find(Data.EchoAxis > -abs(options.FittingTime),1);

AverageEcho = Data.AverageEcho;
EchoAxis=Data.EchoAxis;

% Integration = 'boxcar';

switch Integration
%--------------------------------------------------------------------------
% Gaussian-Fit Integration
%--------------------------------------------------------------------------
  case 'gaussian'
    Pos = 1;
    Pos2 = 1;
    while sum(AverageEcho(:,Pos,Pos2)) == 0
      Pos = Pos+1;
      if Pos > size(AverageEcho,2)
        Pos = 1;
        Pos2 = Pos2+1;
      end
    end
    
    %Gaussian fit of the first echo (for better SNR)
    AverageEchoFitted = zeros(size(AverageEcho));
    FitTimeAxis = EchoAxis(TimeIndex:end - TimeIndex);
    FitData = abs(squeeze(AverageEcho(TimeIndex:end - TimeIndex,Pos,Pos2)));
    GaussianWindow = fit(FitTimeAxis,FitData,'gauss1');
    %Normalize window
    GaussianWindow = GaussianWindow(EchoAxis)/max(GaussianWindow(EchoAxis));
    %Apply to first echo

    AverageEchoFitted(:,Pos,1) = GaussianWindow.*AverageEcho(:,1,1);
    
    for iDimension2 = 1 : size(AverageEcho,2)
      for iDimension3 = 1: size(AverageEcho,3)
        %Repeat for the other echos applying same window
        AverageEchoFitted(:,iDimension2,iDimension3) = GaussianWindow.*AverageEcho(:,iDimension2,iDimension3);
      end
      %Update on the status of integration
      if isfield(options,'status')
      set(options.status, 'String', sprintf('Status: Integr. Echoes %2.1f%%',iDimension2/size(AverageEcho,2)*100)); drawnow;
      end
    end
    %Integration of the gaussian fits of the echos
    Integral = squeeze(sum(AverageEchoFitted,1));

%--------------------------------------------------------------------------
% Boxcar Integration
%--------------------------------------------------------------------------    
  case 'boxcar'
    % Do a boxcar-integration over the (entire) echo
    Integral = squeeze(sum(AverageEcho(TimeIndex:end-TimeIndex,:,:),1));
end

  figure(125124),set(gcf,'Color','w'),clf
plot([-options.FittingTime, -options.FittingTime],[0, 1],'b--','LineWidth',1.5)
hold on
plot([options.FittingTime, options.FittingTime],[0, 1],'b--','LineWidth',1.5)
plot(EchoAxis,abs(AverageEcho(:,1,1))/max(abs(AverageEcho(:,1,1))),'k','LineWidth',1)
try
plot(EchoAxis,GaussianWindow,'r','LineWidth',1)
catch
end
xlabel('Echo Time Axis [ns]'),ylabel('Intensity')
set(gca,'fontsize',9)
hold off
drawnow;


%--------------------------------------------------------------------------
% Return
%--------------------------------------------------------------------------

%Normalize integral and mount to data-structure
Data.Integral = real(Integral/max(max(Integral)));

% Time axis, no zero time adaption
% Data.TimeAxis1 = Data.TimeAxis1 - min(Data.TimeAxis1);
% Data.TimeAxis2 = Data.TimeAxis2 - min(Data.TimeAxis2);

% If requested, display integral
%   figure(2000)
%   set(gcf,'NumberTitle','off','Name','TrierAnalysis: Echo integrals','Units','pixels');
%   surf(Data.TimeAxis1,Data.TimeAxis2,Data.Integral)
%   shading flat
%   xlabel('t_1 [ns]')
%   ylabel('t_2 [ns]')
%   az = 135; el = 40.4000; 
%   view(az,el)


end


