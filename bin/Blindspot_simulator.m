function Blindspot_simulator(SpecLlim,FrequencyAxis,Spectrum)

if nargin<1
  SpecLlim = 20;
end

%Initialize app-data to be passed between UI controls
TauValues = []; 
setappdata(0,'SavedTaus',TauValues)

%Get relative position of the Hyscorean figure
Position = get(gcf,'Position');
%Construct new figure
figure(12312),clf
set(gcf,'NumberTitle','off','Name','HYSCORE Blind spot simulator','Position',[Position(1) Position(2) 985 445])
%Contruct slider
SliderHandle = uicontrol('units','normalized','position',[0.04 0.08 0.025 0.90],'Style','slider','value',100,...
                    'min',100,'max',350,'sliderstep',[1/250 1/250],'callback',{@BlindspotsSpoter,TauValues});
%Construct pushbutton
uicontrol('units','normalized','string','Add Tau','position',[0.015 0.01 0.08 0.06],...
          'Style','pushbutton','callback',{@addTau,SliderHandle,TauValues});

%Plot with lowest tau value to construct and initialize the plot
DummyTauValue = 100/1000;
BlindSpotsAxis1  = linspace(-SpecLlim,SpecLlim,1000);
BlindSpotsAxis2  = linspace(0,SpecLlim,1000);
Dimension1 = length(BlindSpotsAxis1); 
Dimension2 = length(BlindSpotsAxis2); 
BlinSpotsMap = zeros(Dimension1,Dimension2);

  BlinSpots1=1-cos(2*pi*BlindSpotsAxis1*DummyTauValue); % 1 tau value
  BlinSpots2=1-cos(2*pi*BlindSpotsAxis2*DummyTauValue); % 1 tau value

  BlinSpotsContribution=(BlinSpots1'*BlinSpots2)/4;
  BlinSpotsMap = BlinSpotsMap +  BlinSpotsContribution;
  
pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlinSpotsMap'),shading interp, colormap hot
  title(sprintf('\\tau = [ %.0f ] ns ',DummyTauValue*1000))
xlabel('\omega_1 [MHz]')
ylabel('\omega_2 [MHz]')
set(gca,'FontSize',11)
end  
  
  
function BlindspotsSpoter(varargin)
CurrentTau = getappdata(0,'SavedTaus');

TauValue = get(varargin{1},'value');
TauValues = [CurrentTau TauValue]/1000;
BlindSpotsAxis1  = linspace(-20,20,500);
BlindSpotsAxis2  = linspace(0,20,500);
Dimension1 = length(BlindSpotsAxis1); 
Dimension2 = length(BlindSpotsAxis2); 
BlinSpotsMap = zeros(Dimension1,Dimension2);
for i=1:length(TauValues)

%   BlinSpots1=1-cos(2*pi*BlindSpotsAxis1*TauValues(i)); % 1 tau value
%   BlinSpots2=1-cos(2*pi*BlindSpotsAxis2*TauValues(i)); % 1 tau value
 BlinSpots1=sin(2*pi*BlindSpotsAxis1*TauValues(i)/2); % 1 tau value
  BlinSpots2=sin(2*pi*BlindSpotsAxis2*TauValues(i)/2); % 1 tau value

  BlinSpotsContribution=(BlinSpots1'*BlinSpots2);
  BlinSpotsMap = BlinSpotsMap +  BlinSpotsContribution;
  
end
pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlinSpotsMap'),shading interp, colormap hot

TauValuesString = '[';
for i=1:length(TauValues)
  TauValuesString = [TauValuesString ' ' num2str(TauValues(i)*1000)];
end
TauValuesString = [TauValuesString ' ]'];
title(sprintf('\\tau = %s ns ',TauValuesString))
xlabel('\omega_1 [MHz]')
ylabel('\omega_2 [MHz]')
set(gca,'FontSize',11)

end

function addTau(varargin)
CurrentTau = getappdata(0,'SavedTaus');
CurrentTau(end+1) = get(varargin{3},'value'); 
setappdata(0,'SavedTaus',CurrentTau)
BlindspotsSpoter(varargin{3})
end