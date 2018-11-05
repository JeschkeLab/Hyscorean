function [BlinSpotsMap,BlindSpotsAxis1,BlindSpotsAxis2] = imposeBlindSpots(handles)


TauValues = handles.currentTaus;
Dimension = 1000; 

  XupperLimit = str2double(get(handles.XUpperLimit,'string'));
  XlowerLimit = -XupperLimit;
  YupperLimit = XupperLimit;
  YlowerLimit = 0;
FrequencyAxis = linspace(XlowerLimit,XupperLimit,Dimension);

  BlindSpotsAxis1  = FrequencyAxis;
  BlindSpotsAxis2  = FrequencyAxis;
Dimension1 = length(FrequencyAxis); 
Dimension2 = length(FrequencyAxis); 

BlinSpotsMap =zeros(Dimension1,Dimension2);

TauValues=TauValues/1e3;  % us

for i= 1:length(TauValues)
  BlinSpots1=1-cos(2*pi*BlindSpotsAxis1*TauValues(i)); % 1 tau value
  BlinSpots2=1-cos(2*pi*BlindSpotsAxis2*TauValues(i)); % 1 tau value

  BlinSpotsContribution=(BlinSpots1'*BlinSpots2)/4;
 
  BlinSpotsMap = BlinSpotsMap + BlinSpotsContribution;
  
end




