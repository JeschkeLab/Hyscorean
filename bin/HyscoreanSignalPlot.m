function HyscoreanSignalPlot(handles,Processed)
%------------------------------------------------------------------------
% Time-domain signal traces updater 
%------------------------------------------------------------------------
% Interactively display the traces of the different time-domain traces
% processed throughout Hyscorean via GUI slider.  
% This function is responsible for the update and functionality of the
% signal plot in the Hyscorean main-GUI, as well as for the detached signal
% plot sub-GUI.
%
% Luis Fabregas, Hyscorean 2018

% Preparations
%------------------------------------------------------------------------

%Clear axes
cla(handles.signal_t1)
hold(handles.signal_t1,'on')

%Check crucial fields and set defaults if needed
if handles.Data.NUSflag
  PlotStyle = '.';
else
  PlotStyle = '-';
end
if handles.Data.NUSflag
  NUSgrid = handles.Data.NUS.SamplingGrid;
else
    NUSgrid = ones(size(Processed.Signal));
end
if ~isfield(handles,'PlotProcessedSignal')
  handles.PlotProcessedSignal = true;
end
if ~isfield(handles,'PlotBackground')
  PlotSecondCorrection = false;
else
  PlotSecondCorrection = get(handles.PlotBackground,'Value');
end
if ~isfield(handles,'PlotWithZeroFilling')
   PlotWithZeroFilling = false;
else
   PlotWithZeroFilling = get(handles.PlotWithZeroFilling,'Value');
end
%Find which of the signals to be plotted has the largest maximum
ylimMax = max(max(real(Processed.Signal)/max(max(real(Processed.Signal)))));
ylimMin = min(min(real(Processed.Signal)/max(max(real(Processed.Signal)))));
if ylimMax < max(max(real(handles.Data.NonCorrectedIntegral)/max(max(real(handles.Data.NonCorrectedIntegral)))))
  ylimMax = max(max(real(handles.Data.NonCorrectedIntegral/max(max(real(handles.Data.NonCorrectedIntegral))))));
end
if ylimMin > min(min(real(handles.Data.NonCorrectedIntegral)/max(max(real(handles.Data.NonCorrectedIntegral)))))
  ylimMin =  min(min(real(handles.Data.NonCorrectedIntegral)/max(max(real(handles.Data.NonCorrectedIntegral)))));
end
if ylimMax < max(max(real(handles.Data.PreProcessedSignal)/max(max(real(handles.Data.PreProcessedSignal)))))
  ylimMax = max(max(real(handles.Data.PreProcessedSignal)/max(max(real(handles.Data.PreProcessedSignal)))));
end
if ylimMin > min(min(real(handles.Data.PreProcessedSignal)/max(max(real(handles.Data.PreProcessedSignal)))))
  ylimMin =  min(min(real(handles.Data.PreProcessedSignal)/max(max(real(handles.Data.PreProcessedSignal)))));
end
%Construct time axes for the signals
if  PlotWithZeroFilling
  TimeAxis1 = Processed.TimeAxis1(1:length(Processed.TimeAxis1));
  TimeAxis2 = Processed.TimeAxis2(1:length(Processed.TimeAxis2));
else
  TimeAxis1 = Processed.TimeAxis1(1:length(Processed.TimeAxis1)-str2double(get(handles.ZeroFilling1,'String')));
  TimeAxis2 = Processed.TimeAxis2(1:length(Processed.TimeAxis2)-str2double(get(handles.ZeroFilling2,'String')));
end
%Get current position of the slider
SliderPosition = round(get(handles.t1_Slider,'Value'));

% Processed signal
%------------------------------------------------------------------------

if handles.PlotProcessedSignal
  %Switch to change between t1 and t2 traces
  if get(handles.ChangeSignalPlotDimension,'Value')
    ProcessedSignalTrace = Processed.Signal(SliderPosition,:);
    TimeAxis = TimeAxis2';
  else
    ProcessedSignalTrace = Processed.Signal(:,SliderPosition);
    TimeAxis = TimeAxis1';
  end
  if  PlotWithZeroFilling
    ProcessedSignalTrace = ProcessedSignalTrace(1:length(ProcessedSignalTrace));
  else
      if get(handles.ChangeSignalPlotDimension,'Value')
    ProcessedSignalTrace = ProcessedSignalTrace(1:length(ProcessedSignalTrace)-str2double(get(handles.ZeroFilling2,'String')));
      else
        ProcessedSignalTrace = ProcessedSignalTrace(1:length(ProcessedSignalTrace)-str2double(get(handles.ZeroFilling1,'String')));
      end
  end
  ProcessedSignalTrace = ProcessedSignalTrace/max(max(Processed.Signal));
  plot(handles.signal_t1,TimeAxis,ProcessedSignalTrace,'k','Linewidth',1)
end

% First background correction 
%------------------------------------------------------------------------

if get(handles.NonCorrectedTrace,'value')
  
  %Check if the correction order has been inverted
  if get(handles.InvertCorrection,'Value')
    SignalTrace = real(handles.Data.NonCorrectedIntegral(SliderPosition,:));
    Background1Trace = real(handles.Data.Background1(SliderPosition,:));
  else
    SignalTrace = real(handles.Data.NonCorrectedIntegral(:,SliderPosition));
    Background1Trace = real(handles.Data.Background1(:,SliderPosition));
  end
  
  %Rescale and zero-adjust the signal trace
  Mean = mean(real(handles.Data.NonCorrectedIntegral(:,end)),'omitnan');
  if isnan(Mean)
    Mean = 0;
  end
  SignalTrace = SignalTrace - Mean;
  SignalTrace = SignalTrace/max(max(real(handles.Data.NonCorrectedIntegral)));
  
  %Construct axis and plot
  Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(SignalTrace));
  plot(handles.signal_t1,Axis,SignalTrace,PlotStyle,'MarkerSize',16,'Color',[0.2 0.2 0.9])
  hold(handles.signal_t1,'on')
  
  %Rescale and zero-adjust the background trace
  Background1Trace = Background1Trace - Mean;
  Background1Trace = Background1Trace/max(max(real(handles.Data.NonCorrectedIntegral)));
  
  %Construct axis and plot
  Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(Background1Trace));
  plot(handles.signal_t1,Axis,Background1Trace,'Color',[0.2 0.2 0.9],'LineStyle','--')
  hold(handles.signal_t1,'on')
  
  %Set line and label with background fit start time
  XCoordinate = Axis(handles.Data.BackgroundStartIndex1)*[1 1];
  YCoordinate = [0.9*ylimMin 1.1*ylimMax];
  line(handles.signal_t1,XCoordinate,YCoordinate,'Color',[0.2 0.2 0.9],'LineStyle','--')
  text(handles.signal_t1,1.1*Axis(handles.Data.BackgroundStartIndex1),ylimMin,sprintf('%i ns',round(1000*Axis(handles.Data.BackgroundStartIndex1),0)),'Color',[0.2 0.2 0.9])
  hold(handles.signal_t1,'on')
end

% Second background correction
%------------------------------------------------------------------------

if PlotSecondCorrection
  
  %Check if the correction order has been inverted
  if get(handles.InvertCorrection,'Value')
    SignalTrace = real(handles.Data.FirstBackgroundCorrected(SliderPosition,:));
    Background2Trace = real(handles.Data.Background2(:,SliderPosition));
  else
    SignalTrace = real(handles.Data.FirstBackgroundCorrected(:,SliderPosition));
    Background2Trace = real(handles.Data.Background2(SliderPosition,:));
  end
  
  Mean = mean(real(handles.Data.FirstBackgroundCorrected(end,:)),'omitnan');
  if isnan(Mean)
    Mean = 0;
  end
  
  %Rescale and zero-adjust the signal trace
  SignalTrace = SignalTrace - Mean;
  SignalTrace = SignalTrace/max(max(real(handles.Data.FirstBackgroundCorrected)));
  
  %Construct axis and plot
  Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(SignalTrace));
  plot(handles.signal_t1,Axis,SignalTrace,PlotStyle,'MarkerSize',16,'Color',[0.6 0.0 0.8])
  hold(handles.signal_t1,'on')
  
  %Rescale and zero-adjust the background trace
  Background2Trace = Background2Trace - Mean;
  Background2Trace = Background2Trace/max(max(real(handles.Data.FirstBackgroundCorrected)));
  
  %Construct axis and plot
  Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(Background2Trace));
  plot(handles.signal_t1,Axis,Background2Trace,'Color',[0.6 0.0 0.8],'LineStyle','--')
  hold(handles.signal_t1,'on')
  
  %Set line and label with background fit start time
  XCoordinate = Axis(handles.Data.BackgroundStartIndex2)*[1 1];
  YCoordinate = [0.9*ylimMin 1.1*ylimMax];
  line(handles.signal_t1,XCoordinate,YCoordinate,'Color',[0.6 0.0 0.8],'LineStyle','--')
  text(handles.signal_t1,1.1*Axis(handles.Data.BackgroundStartIndex2),ylimMax,sprintf('%i ns',round(1000*Axis(handles.Data.BackgroundStartIndex2),0)),'Color',[0.6 0.0 0.8])
  hold(handles.signal_t1,'on')
  
end

% Signal after background correction
%------------------------------------------------------------------------

if get(handles.PreProcessedTrace,'value')
  
  %Switch to change between t1 and t2 traces
  if get(handles.ChangeSignalPlotDimension,'Value')
    PreProcessedSignalTrace = real(handles.Data.PreProcessedSignal(SliderPosition,:));
    PreProcessedSignalTrace(NUSgrid(SliderPosition,:)==0) = NaN;
  else
    PreProcessedSignalTrace = real(handles.Data.PreProcessedSignal(:,SliderPosition));
    PreProcessedSignalTrace(NUSgrid(:,SliderPosition)==0) = NaN;
  end
  
  %Rescale and zero-adjust the trace
  PreProcessedSignalTrace = PreProcessedSignalTrace - mean(real(handles.Data.PreProcessedSignal(end,:)),'omitnan');
  PreProcessedSignalTrace = PreProcessedSignalTrace/max(max(real(handles.Data.PreProcessedSignal)));
  
  %Get axis for plot
  Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(PreProcessedSignalTrace));
  
  %Plot and hold
  plot(handles.signal_t1,Axis,PreProcessedSignalTrace,PlotStyle,'MarkerSize',16,'Color',[0.9 0.2 0.2])
  hold(handles.signal_t1,'on')
  
end

% Apodization Window
%------------------------------------------------------------------------

if get(handles.PlotApodizationWindow,'value')
  
%   %Get window decay
  WindowDecay = str2double(get(handles.Hammingedit,'string'));
    WindowMenuState = get(handles.WindowType,'value');
  switch WindowMenuState
    case 1
     WindowType =  'hamming';
    case 2
     WindowType =  'chebyshev';  
    case 3
     WindowType =  'welch';
    case 4
      WindowType = 'blackman'; 
    case 5
      WindowType = 'bartlett';
    case 6
      WindowType = 'connes';
    case 7
      WindowType = 'cosine';      
  end
  [~,Window] = apodizationWin(Processed.Signal,WindowType,WindowDecay);
  %Adjust window to current axis
  Window = Window/max(Window);
  Window = Window';
  if WindowDecay>=length(TimeAxis1)
    Window=Window(1:length(TimeAxis1));
  end
  if WindowDecay<length(TimeAxis1)
    Window=[Window Window(end)+zeros(1,length(TimeAxis1)-WindowDecay)];
  end
  %Plot and hold
  plot(handles.signal_t1,TimeAxis1,Window,'Color',[0.1 0.7 0.1])
  hold(handles.signal_t1,'on')
  
end

% Format axes accordingly
%------------------------------------------------------------------------

%Set axes limits
set(handles.signal_t1,'ytick',[],'ylim',[0.9*ylimMin 1.1*ylimMax],'xlim',[min(TimeAxis1) max(TimeAxis1)])

%Format axis labels and trace information according to current dimension
if get(handles.ChangeSignalPlotDimension,'Value')
  set(handles.signal_t1,'xlim',[min(TimeAxis2) max(TimeAxis2)])
  try
    %Try to use 1 digit after comma
    set(handles.signal_t1,'xtick',round(linspace(TimeAxis2(1),TimeAxis2(end),10),1))
  catch
    %If not possible use 2 digits
    set(handles.signal_t1,'xtick',round(linspace(TimeAxis2(1),TimeAxis2(end),10),2))
  end
  xlabel(handles.signal_t1,'t_2 [\mus]','FontSize',8);
  set(handles.trace2Info,'string',sprintf('Trace along t2 at t1 = %g ns',round(1000*Processed.TimeAxis1(SliderPosition),1)))
else
  set(handles.signal_t1,'xlim',[min(TimeAxis1) max(TimeAxis1)])
  try
    %Try to use 1 digit after comma
    set(handles.signal_t1,'xtick',round(linspace(TimeAxis1(1),TimeAxis1(end),10),1))
  catch
    %If not possible use 2 digits
    set(handles.signal_t1,'xtick',round(linspace(TimeAxis1(1),TimeAxis1(end),10),2))
  end
  xlabel(handles.signal_t1,'t_1 [\mus]','FontSize',8);
  set(handles.trace2Info,'string',sprintf('Trace along t1 at t2 = %g ns',round(1000*Processed.TimeAxis2(SliderPosition),1)))
end
set(handles.signal_t1,'FontSize',8)

%Stop holding
hold(handles.signal_t1,'off')

