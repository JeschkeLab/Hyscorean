function displayNUSreconstructionResults(handles)
%==========================================================================
% Hyscorean NUS results
%==========================================================================
% Function to create a figure with a summary of the different elements
% involved in the NUS reconstruction of the signal. 
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

%Find figure, close it and open it again
Figure = findobj('Tag','NUSsummaryfigure');
if isempty(Figure)
  Figure = figure('Tag','NUSsummaryfigure','WindowStyle','normal');
else
  figure(Figure);
  clf(Figure);
end
set(Figure,'NumberTitle','off','Name','Hyscorean: NUS Reconstruction Overview','Position',[150 100 1659 684])

%Define colormap for whole figure
colormap('parula')

%Get frequency axes
FrequencyAxis1 = handles.Processed.axis1;
FrequencyAxis2 = handles.Processed.axis2;
XLim = str2double(get(handles.XUpperLimit,'string'));

% Plot #1 NUS grid
%==========================================================================
p = subplot(241);
imagesc(handles.Data.TimeAxis1,handles.Data.TimeAxis2,1-abs(handles.Data.NUSgrid))
colormap(p,'gray')
axis('xy')
%Determine sampling density and siplay as title
Dimension1 = length(handles.Data.TimeAxis1);
Dimension2 = length(handles.Data.TimeAxis1);
Sampling  = length(find(handles.Data.NUSgrid==1))/Dimension1/Dimension2*100;
title(sprintf('NUS Schedule (@%.2f%%)',Sampling))
xlabel('t_1 [ns]')
ylabel('t_2 [ns]')

% Plot #2 NUS reconstruction functional
%==========================================================================
subplot(242)
plot((handles.Data.ReconstructionConvergence),'b','LineWidth',1.5)
axis tight
grid on
xlabel('Iterations')
ylabel('Functional')
title('Reconstruction Functional')

% Plot #3 NUS signal
%==========================================================================
subplot(245)
handles.Data.PreProcessedSignal(handles.Data.NUSgrid==0) = NaN;
pcolor(handles.Data.TimeAxis2,handles.Data.TimeAxis1,abs(handles.Data.PreProcessedSignal))
shading flat
xlabel('t_1 [ns]')
ylabel('t_2 [ns]')
title('NUS Signal')

% Plot #4 Recosntructed signal
%==========================================================================
subplot(246)
pcolor(handles.Data.TimeAxis2,handles.Data.TimeAxis1,abs(handles.Data.ReconstructedSignal)),shading flat
xlabel('t_1 [ns]'),ylabel('t_2 [ns]'),title('Reconstructed Signal')

% Plot #5 nuDFT HYSCORE spectrum
%==========================================================================
subplot(2,4,[3 4])
ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
handles.Data.PreProcessedSignal(isnan(handles.Data.PreProcessedSignal)) = 0;
NUSSpectrum = abs(fftshift(fft2(handles.Data.PreProcessedSignal,ZeroFilling1 + Dimension1,ZeroFilling2 + Dimension2)));
contour(FrequencyAxis2,FrequencyAxis1,NUSSpectrum,handles.GraphicalSettings.Levels)
hold on
%Plot auxilliary lines
plot(-max(FrequencyAxis1):1:max(FrequencyAxis1),abs(-max(FrequencyAxis1):1:max(FrequencyAxis1)),'k-.'),grid on
plot(zeros(length(0:max(FrequencyAxis1)),1),abs(0:max(FrequencyAxis1)),'k-')
xlabel('\nu_1 [MHz]'),ylabel('\nu_2 [MHz]'),title('nuDFT HYSCORE Spectrum')
xlim([-XLim XLim]),ylim([0 XLim])

% Plot #6 Reconstructed HYSCORE spectrum
%=========================================================================
subplot(2,4,[7 8])
ReconstructedSpectrum = abs(fftshift(fft2(handles.Data.ReconstructedSignal,ZeroFilling1 + Dimension1,ZeroFilling2 + Dimension2)));
contour(FrequencyAxis1,FrequencyAxis2,ReconstructedSpectrum,handles.GraphicalSettings.Levels)
hold on
%Plot auxilliary lines
plot(-max(FrequencyAxis1):1:max(FrequencyAxis1),abs(-max(FrequencyAxis1):1:max(FrequencyAxis1)),'k-.'),grid on
plot(zeros(length(0:max(FrequencyAxis1)),1),abs(0:max(FrequencyAxis1)),'k-')
xlabel('\nu_1 [MHz]'),ylabel('\nu_2 [MHz]'),title('Reconstructed HYSCORE Spectrum')
xlim([-XLim XLim]),ylim([0 XLim])

end