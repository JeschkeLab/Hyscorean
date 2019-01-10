function displayNUSreconstructionResults(handles)

figure(12354987),set(gcf,'NumberTitle','off','Name','Hyscorean: NUS Reconstruction Overview','Position',[150 100 1659 684])
p = subplot(241);
pcolor(handles.Data.TimeAxis1,handles.Data.TimeAxis2,abs(handles.Data.NUSgrid-1));shading flat
colormap(p,'bone')
Dimension1 = length(handles.Data.TimeAxis1);
Dimension2 = length(handles.Data.TimeAxis1);

Sampling  = length(find(handles.Data.NUSgrid==1))/Dimension1/Dimension2*100;
TimeStep1 = handles.Data.TimeStep1;
FrequencyAxis1 = linspace(-1/(2*TimeStep1),1/(2*TimeStep1),2*Dimension1);
TimeStep2 = handles.Data.TimeStep2;
FrequencyAxis2 = linspace(-1/(2*TimeStep2),1/(2*TimeStep2),2*Dimension2);
xlabel('t_1 [ns]'),ylabel('t_2 [ns]'),title(sprintf('NUS Schedule (@%.2f%%)',Sampling))

subplot(242)
plot((handles.Data.ReconstructionConvergence),'b','LineWidth',1.5),axis tight,grid on
xlabel('Iterations'),ylabel('Functional'),title('Reconstruction Functional')
subplot(245)
handles.Data.PreProcessedSignal(handles.Data.NUSgrid==0) = NaN;
pcolor(handles.Data.TimeAxis1,handles.Data.TimeAxis1,handles.Data.PreProcessedSignal),shading flat
xlabel('t_1 [ns]'),ylabel('t_2 [ns]'),title('NUS Signal')
subplot(246)
pcolor(handles.Data.TimeAxis1,handles.Data.TimeAxis2,handles.Data.ReconstructedSignal),shading flat
xlabel('t_1 [ns]'),ylabel('t_2 [ns]'),title('Reconstructed Signal')

subplot(2,4,[3 4])
handles.Data.PreProcessedSignal(isnan(handles.Data.PreProcessedSignal)) = 0;
NUSSpectrum = abs(fftshift(fft2(handles.Data.PreProcessedSignal,2*Dimension1,2*Dimension2)));
contour(FrequencyAxis1,FrequencyAxis2,NUSSpectrum,handles.GraphicalSettings.Levels)
hold on
plot(-50:1:50,abs(-50:1:50),'k-.'),grid on
plot(zeros(length(0:50),1),abs(0:50),'k-')
xlabel('\omega_1 [MHz]'),ylabel('\omega_2 [MHz]'),title('nuDFT HYSCORE Spectrum')
xlim([-20 20]),ylim([0 20])

subplot(2,4,[7 8])
ReconstructedSpectrum = abs(fftshift(fft2(handles.Data.ReconstructedSignal,2*Dimension1,2*Dimension2)));
contour(FrequencyAxis1,FrequencyAxis2,ReconstructedSpectrum,handles.GraphicalSettings.Levels)
hold on
plot(-50:1:50,abs(-50:1:50),'k-.'),grid on
plot(zeros(length(0:50),1),abs(0:50),'k-')
xlabel('\omega_1 [MHz]'),ylabel('\omega_2 [MHz]'),title('Reconstructed HYSCORE Spectrum')
xlim([-20 20]),ylim([0 20])