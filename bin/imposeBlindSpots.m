function [BlinSpotsMap,BlindSpotsAxis1,BlindSpotsAxis2] = imposeBlindSpots(handles)
%==========================================================================
% Blindspot map
%==========================================================================
% This function calculates the blindspot map to be superimposed onto the
% displayed experimental spectrum in the Hyscorean GUI.
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Get current experimental tau-values
TauValues = handles.currentTaus;
TauValues=TauValues/1e3;
%Use a fixed dimension with good resolution-speed compromise
Dimension = 500; 
%Get the current limits of the spectrum
SpectralLimit = str2double(get(handles.XUpperLimit,'string'));
%Generate the axes
BlindSpotsAxis1 = linspace(-SpectralLimit,SpectralLimit,Dimension);
BlindSpotsAxis2 = BlindSpotsAxis1;
%Initialize the blindspot map
BlinSpotsMap =zeros(Dimension,Dimension);


for i= 1:length(TauValues)
  %Compute blindspots along each dimension
  BlinSpots1=sin(2*pi*BlindSpotsAxis1*TauValues(i)/2); % 1 tau value
  BlinSpots2=sin(2*pi*BlindSpotsAxis2*TauValues(i)/2); % 1 tau value
  %Construct 2D-blindspot map contribution for current tau value
  BlinSpotsContribution=(BlinSpots1'.*BlinSpots2)/4;
  %Add to the rest
  BlinSpotsMap = BlinSpotsMap + BlinSpotsContribution;
end

return




