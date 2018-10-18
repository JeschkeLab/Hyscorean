function [Data] = integrateEcho(Data,options)

FittingTime = options.FittingTime;

options.FittingTime = FittingTime; %ns
TimeIndex = find(Data.EchoAxis > -abs(options.FittingTime),1);

AverageEcho = Data.AverageEcho;
EchoAxis=Data.EchoAxis;

if options.PlotIntegration
plot(options.PlotHandle,[-FittingTime, -FittingTime],[0, 1],'b--','LineWidth',1.5)
hold(options.PlotHandle,'on')
plot(options.PlotHandle,[FittingTime, FittingTime],[0, 1],'b--','LineWidth',1.5)
plot(options.PlotHandle,EchoAxis,abs(AverageEcho(:,1,1))/max(abs(AverageEcho(:,1,1))),'k','LineWidth',1)
set(options.PlotHandle,'fontsize',9,'YTickLabel',[],'XTickLabel',[])
hold(options.PlotHandle,'off')
drawnow;
end

switch options.Boxcar
  case 0
    %Gaussian fit of the echo
    AverageEchoFitted = zeros(size(AverageEcho));
    FitTimeAxis = EchoAxis(TimeIndex:end - TimeIndex);
    FitData = real(squeeze(AverageEcho(TimeIndex:end - TimeIndex,1,1)));
    GaussianWindow = fit(FitTimeAxis,FitData,'gauss1');
    %Normalize window
    GaussianWindow = GaussianWindow/max(GaussianWindow);
    %Apply to first echo
    AverageEchoFitted(:,1,1) = GaussianWindow(EchoAxis).*AverageEcho(:,1,1);
    
    for iDimension2 = 1 : size(AverageEcho,2)
      for iDimension3 = 1: size(AverageEcho,3)
%         FitData = real(squeeze(AverageEcho(TimeIndex:end - TimeIndex,iDimension2,iDimension3)));
%         try
%         FitOutput = fit(FitTimeAxis,FitData,'gauss1');
%         catch
%           %use previous fit
%         end
        AverageEchoFitted(:,iDimension2,iDimension3) = GaussianWindow(EchoAxis).*AverageEcho(:,iDimension2,iDimension3);
      end
      set(options.status, 'String', sprintf('Status: Integrating Echo %2.1f%%',iDimension2/size(AverageEcho,2)*100)); drawnow;

    end
    %Integration of the gaussian fit of the echo
    Integral = squeeze(sum(AverageEchoFitted,1));

  case 1
    % Do a boxcar-integration over the (entire) echo
    Integral = squeeze(sum(AverageEcho(TimeIndex:end-TimeIndex,:,:),1));
end

%Normalize integral and mount to data-structure
Data.Integral = real(Integral/max(max(Integral)));

% Time axis, no zero time adaption
Data.TimeAxis1 = Data.TimeAxis1 - min(Data.TimeAxis1);
Data.TimeAxis2 = Data.TimeAxis2 - min(Data.TimeAxis2);
disp('Echo Integration finished')

% If requested, display integral
if options.DisplayIntegral
  figure(2000)
  set(gcf,'NumberTitle','off','Name','TrierAnalysis: Echo integrals','Units','pixels');
  surf(Data.TimeAxis1,Data.TimeAxis2,Data.Integral)
  shading flat
  xlabel('t_1 [ns]')
  ylabel('t_2 [ns]')
  az = 135; el = 40.4000; 
  view(az,el)
end

end


