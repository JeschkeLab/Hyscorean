function Blindspot_simulator(FrequencyAxis,Spectrum,SpecLim)
%==========================================================================
% HYSCORE blind spot simulator
%==========================================================================
% Function for the simulation of the blind-spot behaviour of the HYSCORE 
% experiments. An experimental spectrum can be overlaid on top of the
% simulated blindspot map in order to assess potential new tau-value
% combinations for HYSCORE experiments. 
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================
%Check inputs
if nargin<2
  Spectrum = nan(length(FrequencyAxis));
  warning('off','all')
end
if nargin<3
  SpecLim = max(FrequencyAxis);
end
TauValues = []; 

%Use a global variable to pass inputs between all callbacks more easily
clear global;
global SimData
SimData.FrequencyAxis = FrequencyAxis;
SimData.Spectrum = abs(Spectrum/max(max(abs(Spectrum))));
SimData.TauValues = TauValues;
SimData.SpecLim = SpecLim;

%Get relative position of the Hyscorean figure
Position = get(gcf,'Position');
%Find figure, close it and open it again
Figure = findobj('Tag','blindspotSimulator');
if isempty(Figure)
  Figure = figure('Tag','blindspotSimulator','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
set(gcf,'NumberTitle','off','Name','HYSCORE Blind spot simulator','Position',[Position(1) Position(2) 985 445])
%Contruct slider
SliderHandle = uicontrol('units','normalized','tag','slider','position',[0.04 0.08 0.025 0.90],'Style','slider','value',100,...
                    'min',100,'max',350,'sliderstep',[1/250 1/250],'callback',{@BlindspotsSpoter});
%Construct pushbutton
uicontrol('units','normalized','string','Add Tau','position',[0.015 0.01 0.08 0.06],...
          'Style','pushbutton','callback',{@addTau,SliderHandle});

%Construct pushbutton
uicontrol('units','normalized','string','Overlap experimental spectrum','position',[0.1 0.01 0.25 0.06],...
          'Style','checkbox','Tag','displaySpectrum','callback',{@BlindspotsSpoter,SliderHandle});        
      
%Plot the experimental contour spectrum already and just make it (in)-visible later
[~,ContourHandle] = contour(SimData.FrequencyAxis,SimData.FrequencyAxis,SimData.Spectrum,40,'LineWidth',1,'Color','k');
SimData.ConoturHandle =  ContourHandle;

%Plot with lowest tau value to construct and initialize the plot
FirstTauValue = 100/1000;
Axis = linspace(min(SimData.FrequencyAxis),max(SimData.FrequencyAxis),50);
BlindSpotsAxis1  = Axis;
BlindSpotsAxis2  = Axis;
Dimension1 = length(BlindSpotsAxis1);
Dimension2 = length(BlindSpotsAxis2);
BlinSpotsMap = zeros(Dimension1,Dimension2);

%Compute blindspots along each dimension
BlinSpots1=sin(2*pi*BlindSpotsAxis1*FirstTauValue/2);
BlinSpots2=sin(2*pi*BlindSpotsAxis2*FirstTauValue/2); 
%Get 2D-blindspots map contribution
BlinSpotsContribution=(BlinSpots1'*BlinSpots2)/4;
BlinSpotsMap = BlinSpotsMap +  BlinSpotsContribution;
%Update the display
plotBlindSpots(BlindSpotsAxis1,BlindSpotsAxis2,BlinSpotsMap)
%Display also tau values employed currently
title(sprintf('\\tau = [ %.0f ] ns ',FirstTauValue*1000))
end  
%==========================================================================

%==========================================================================  
function BlindspotsSpoter(varargin)
global SimData
%Get stored tau values
CurrentTau = SimData.TauValues;
%Get current state of the slider
TauValue = get(findobj('tag','slider'),'value');
TauValues = [CurrentTau TauValue]/1000;
%Compute blindspots
Axis = linspace(min(SimData.FrequencyAxis),max(SimData.FrequencyAxis),200);
BlindSpotsAxis1  = Axis;
BlindSpotsAxis2  = Axis;
Dimension1 = length(BlindSpotsAxis1);
Dimension2 = length(BlindSpotsAxis2);
BlinSpotsMap = zeros(Dimension1,Dimension2);
for i=1:length(TauValues)
  %Compute blindspots along each dimension
  BlinSpots1=sin(2*pi*BlindSpotsAxis1*TauValues(i)/2);
  BlinSpots2=sin(2*pi*BlindSpotsAxis2*TauValues(i)/2);
  %Get 2D-blindspots map contribution
  BlinSpotsContribution=(BlinSpots1'*BlinSpots2)/4;
  BlinSpotsMap = BlinSpotsMap +  BlinSpotsContribution;
end
%Update the display
plotBlindSpots(BlindSpotsAxis1,BlindSpotsAxis2,BlinSpotsMap)
%Update the tau values employed on the display
TauValuesString = '[';
for i=1:length(TauValues)
  TauValuesString = [TauValuesString ' ' num2str(TauValues(i)*1000)];
end
TauValuesString = [TauValuesString ' ]'];
title(sprintf('\\tau = %s ns ',TauValuesString))
end
%==========================================================================

%==========================================================================
function addTau(varargin)
global SimData
%Get stored taus
CurrentTau = SimData.TauValues;
%Get slider state and add to stored taus
CurrentTau(end+1) = get(varargin{3},'value'); 
%Update global variable
SimData.TauValues = CurrentTau;
%Update display info
TauValuesString = '[';
for i=1:length(CurrentTau)
  TauValuesString = [TauValuesString ' ' num2str(CurrentTau(i))];
end
TauValuesString = [TauValuesString ' ]'];
title(sprintf('\\tau = %s ns ',TauValuesString))
end
%==========================================================================

%==========================================================================
function plotBlindSpots(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap)

global SimData
%Check if user requests spectrum to be displayed
if get(findobj('tag','displaySpectrum'),'Value')
  %If yes use a transparent colormap
  BlindSpotsMap = BlindSpotsMap/max(max(BlindSpotsMap));
  colormap('hot')
  hold on
  BlindSpots = pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap');
  alpha(BlindSpots,0.7);
  shading interp,
  %And make spectrum visible again and bring it on top
  SimData.ConoturHandle.Visible = 'on';
  uistack( SimData.ConoturHandle,'top');
else
  %If not then use normal colormap
  hold on
  pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap')
  shading interp
  colormap hot
  %And make spectrum invisible
  SimData.ConoturHandle.Visible = 'off';
end
%Configure axis
xlim([-SimData.SpecLim SimData.SpecLim])
ylim([0 SimData.SpecLim])
xlabel('\nu_1 [MHz]')
ylabel('\nu_2 [MHz]')
set(gca,'FontSize',10)
end
%==========================================================================

