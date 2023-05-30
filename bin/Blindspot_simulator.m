function Blindspot_simulator(FrequencyAxis1,FrequencyAxis2,Spectrum,SpecLim,spccontourlevels)
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
if nargin<3
  Spectrum = nan(length(FrequencyAxis1),length(FrequencyAxis2));
  warning('off','all')
end
if nargin<4
  SpecLim = max(FrequencyAxis1);
end
TauValues = []; 

%Use a global variable to pass inputs between all callbacks more easily
clear global;
global SimData
SimData.FrequencyAxis1 = FrequencyAxis1;
SimData.FrequencyAxis2 = FrequencyAxis2;
SimData.Spectrum = abs(Spectrum/max(max(abs(Spectrum))));
SimData.TauValues = TauValues;
SimData.SpecLim = SpecLim;
SimData.spccontourlevels = spccontourlevels/max(abs(spccontourlevels));         % contourlevels to get the same exp. plot as in main gui

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
%Construct slider
SliderHandle = uicontrol('units','normalized','tag','slider','position',[0.04 0.08 0.025 0.90],'Style','slider','value',80,...
                    'min',80,'max',350,'sliderstep',[1/270 1/270],'callback',{@BlindspotsSpoter});
%Construct pushbutton
uicontrol('units','normalized','string','Add Tau','position',[0.015 0.01 0.08 0.06],...
          'Style','pushbutton','callback',{@addTau,SliderHandle});

%Construct pushbutton (only if experimental spectrum is loaded)
if nargin > 2
    uicontrol('units','normalized','string','Overlap experimental spectrum','position',[0.1 0.01 0.25 0.06],...
          'Style','checkbox','Tag','displaySpectrum','callback',{@BlindspotsSpoter,SliderHandle});   
end
      
%Plot the experimental contour spectrum already and just make it (in)-visible later
[~,ContourHandle] = contour(SimData.FrequencyAxis1,SimData.FrequencyAxis2,SimData.Spectrum,SimData.spccontourlevels,'LineWidth',1,'Color','k');
SimData.ContourHandle =  ContourHandle;

%Plot with lowest tau value to construct and initialize the plot
FirstTauValue = 80/1000;
BlindSpotsAxis1 = linspace(min(SimData.FrequencyAxis1),max(SimData.FrequencyAxis1),80);
BlindSpotsAxis2 = linspace(min(SimData.FrequencyAxis2),max(SimData.FrequencyAxis2),80);
Dimension1 = length(BlindSpotsAxis1);
Dimension2 = length(BlindSpotsAxis2);
BlindSpotsMap = zeros(Dimension1,Dimension2);

%Compute blindspots along each dimension
BlindSpots1=sin(2*pi*BlindSpotsAxis1*FirstTauValue/2);
BlindSpots2=sin(2*pi*BlindSpotsAxis2*FirstTauValue/2); 
%Get 2D-blindspots map contribution
BlindSpotsContribution=(BlindSpots1'*BlindSpots2)/4;
BlindSpotsMap = BlindSpotsMap +  BlindSpotsContribution;
%Update the display
plotBlindSpots(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap)
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
BlindSpotsAxis1 = linspace(min(SimData.FrequencyAxis1),max(SimData.FrequencyAxis1),80);
BlindSpotsAxis2 = linspace(min(SimData.FrequencyAxis2),max(SimData.FrequencyAxis2),80);
Dimension1 = length(BlindSpotsAxis1);
Dimension2 = length(BlindSpotsAxis2);
BlindSpotsMap = zeros(Dimension1,Dimension2);
for i=1:length(TauValues)
  %Compute blindspots along each dimension
  BlindSpots1=sin(2*pi*BlindSpotsAxis1*TauValues(i)/2);
  BlindSpots2=sin(2*pi*BlindSpotsAxis2*TauValues(i)/2);
  %Get 2D-blindspots map contribution
  BlindSpotsContribution=(BlindSpots1'*BlindSpots2)/4;
  BlindSpotsMap = BlindSpotsMap +  BlindSpotsContribution;
end
%Update the display
plotBlindSpots(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap)
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
  % Normalize Blindspot map (so that it has the same intensities as exp. spectrum)
  % VisibilityFactor: decrease blindspot intensity and make exp spectrum more visible
  VisibilityFactor = 0.6;                           
  BlindSpotsMapNormalized = BlindSpotsMap/max(max(BlindSpotsMap))*VisibilityFactor;
  colormap('hot')
  hold on
  BlindSpots = pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMapNormalized');
  alpha(BlindSpots,0.7);            
  shading interp,
  %And make spectrum visible again and bring it on top
  SimData.ContourHandle.Visible = 'on';
  uistack( SimData.ContourHandle,'top');
else
  %If not then use normal colormap
  hold on;
  BlindSpotsMapNormalized = BlindSpotsMap/max(max(BlindSpotsMap));
  BlindSpots = pcolor(BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMapNormalized');
  shading interp
  colormap hot
  %And make spectrum invisible
  SimData.ContourHandle.Visible = 'off';
end
%Configure axis
xlim([-SimData.SpecLim SimData.SpecLim])
ylim([0 SimData.SpecLim])
xlabel('\nu_1 [MHz]')
ylabel('\nu_2 [MHz]')
set(gca,'FontSize',10)
end
%==========================================================================

