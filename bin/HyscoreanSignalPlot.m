function HyscoreanSignalPlot(handles,Processed)
cla(handles.signal_t1)
      hold(handles.signal_t1,'on')

if ~get(handles.ChangeSignalPlotDimension,'Value')
  
  position1 = round(get(handles.t1_Slider,'Value'));
  TimeAxis1 = Processed.TimeAxis1(1:length(Processed.TimeAxis1)-str2double(get(handles.ZeroFilling1,'String')));

  if handles.PlotProcessedSignal
    %Time-domain signal trace along t1
    trace1 = Processed.Signal(:,position1);
    trace1 = trace1(1:length(trace1)-str2double(get(handles.ZeroFilling1,'String')));
    plot(handles.signal_t1,TimeAxis1',trace1,'k','Linewidth',1)

  end
  if get(handles.NonCorrectedTrace,'value')
    trace1 = real(handles.Data.NonCorrectedIntegral(:,position1));
    trace1 = trace1 - mean(real(handles.Data.NonCorrectedIntegral(end,:)));
    trace1 = trace1/real(handles.Data.NonCorrectedIntegral(1,1) - mean(real(handles.Data.NonCorrectedIntegral(end,:))));
%     trace1 = trace1/max(abs(trace1));
    Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(trace1));
    plot(handles.signal_t1,Axis,trace1,'Color',[0.2 0.2 0.9])
      hold(handles.signal_t1,'on')

  end
  if get(handles.PreProcessedTrace,'value')
    trace1 = real(handles.Data.PreProcessedSignal(:,position1));
    trace1 = trace1 - mean(real(handles.Data.PreProcessedSignal(end,:)));
    trace1 = trace1/real(handles.Data.PreProcessedSignal(1,1) - mean(real(handles.Data.PreProcessedSignal(end,:))));
    Axis = linspace(min(handles.Data.CorrectedTimeAxis1),max(handles.Data.CorrectedTimeAxis1),length(trace1));
    plot(handles.signal_t1,Axis,trace1,'Color',[0.9 0.2 0.2])
      hold(handles.signal_t1,'on')

  end
  
  if get(handles.PlotApodizationWindow,'value')
    WindowDecay = str2double(get(handles.Hammingedit,'string'));
    arg=linspace(0,pi,WindowDecay);
    if get(handles.HammingWindow,'Value')
      Window=0.54*ones(1,WindowDecay)+0.46*cos(arg);
    else
      ChebishevWindow = ifftshift(chebwin(WindowDecay*2));
      Window = ChebishevWindow(1:WindowDecay)';
    end
    Window = Window/max(Window);
    if WindowDecay>=length(TimeAxis1)
      Window=Window(1:length(TimeAxis1));
    end
    if WindowDecay<length(TimeAxis1)
      Window=[Window zeros(1,length(TimeAxis1)-WindowDecay)];
    end
    plot(handles.signal_t1,TimeAxis1,Window,'Color',[0.1 0.7 0.1])
      hold(handles.signal_t1,'on')

  end
hold(handles.signal_t1,'off')

% set(handles.signal_t1,'ytick',[])
set(handles.signal_t1,'ytick',[],'ylim',[1.1*min(min(Processed.Signal)) 1.1*max(max(Processed.Signal))])
set(handles.signal_t1,'xlim',[min(TimeAxis1) max(TimeAxis1)])

xlabel(handles.signal_t1,'t_1 [\mus]','FontSize',8);
set(handles.trace2Info,'string',sprintf('Trace along t1 at t2 = %g ns',round(1000*Processed.TimeAxis2(position1),1)))
set(handles.signal_t1,'FontSize',8)

else
  position1 = round(get(handles.t1_Slider,'Value'));
  TimeAxis2 = Processed.TimeAxis1(1:length(Processed.TimeAxis1)-str2double(get(handles.ZeroFilling1,'String')));
  
  if handles.PlotProcessedSignal
    %Time-domain signal trace along t2
    
    trace2 = Processed.Signal(position1,:);
    trace2 = trace2(1:length(trace2)-str2double(get(handles.ZeroFilling2,'String')));
    plot(handles.signal_t1,TimeAxis2,trace2,'k','Linewidth',1)
      hold(handles.signal_t1,'on')

  end
  if get(handles.NonCorrectedTrace,'value')
    trace2 = real(handles.Data.NonCorrectedIntegral(position1,:));
    trace2 = trace2 - mean(real(handles.Data.NonCorrectedIntegral(:,end)));
    trace2 = trace2/real(handles.Data.NonCorrectedIntegral(1,1) - mean(real(handles.Data.NonCorrectedIntegral(:,end))));
    Axis = linspace(min(handles.Data.CorrectedTimeAxis2),max(handles.Data.CorrectedTimeAxis2),length(trace2));
    plot(handles.signal_t1,Axis,trace2,'Color',[0.2 0.2 1])
      hold(handles.signal_t1,'on')

  end
  if get(handles.PreProcessedTrace,'value')
    trace2 = real(handles.Data.PreProcessedSignal(position1,:));
    trace2 = trace2 - mean(real(handles.Data.PreProcessedSignal(:,end)));
    trace2 = trace2/real(handles.Data.PreProcessedSignal(1,1) - mean(real(handles.Data.PreProcessedSignal(:,end))));
    Axis = linspace(min(handles.Data.CorrectedTimeAxis2),max(handles.Data.CorrectedTimeAxis2),length(trace2));
    plot(handles.signal_t1,Axis,trace2,'Color',[1 0.2 0.2])
      hold(handles.signal_t1,'on')

  end
  if get(handles.PlotApodizationWindow,'value')
    WindowDecay = str2double(get(handles.Hammingedit,'string'));
    arg=linspace(0,pi,WindowDecay);
    if get(handles.HammingWindow,'Value')
      Window=0.54*ones(1,WindowDecay)+0.46*cos(arg);
    else
      ChebishevWindow = ifftshift(chebwin(WindowDecay*2));
      Window = ChebishevWindow(1:WindowDecay)';
    end
    Window = Window/max(Window);
    if WindowDecay>=length(TimeAxis2)
      Window=Window(1:length(TimeAxis2));
    end
    if WindowDecay<length(TimeAxis2)
      Window=[Window zeros(1,length(TimeAxis2)-WindowDecay)];
    end
    plot(handles.signal_t1,TimeAxis2,Window,'Color',[0.1 0.7 0.1])
      hold(handles.signal_t1,'on')

  end
hold(handles.signal_t1,'off')

% set(handles.signal_t2,'ytick',[])
set(handles.signal_t1,'ytick',[],'ylim',[1.1*min(min(Processed.Signal)) 1.1*max(max(Processed.Signal))])
set(handles.signal_t1,'xlim',[min(TimeAxis2) max(TimeAxis2)])

xlabel(handles.signal_t1,'t_2 [\mus]','FontSize',8);
set(handles.trace2Info,'string',sprintf('Trace along t2 at t1 = %g ns',round(1000*Processed.TimeAxis1(position1),1)))
set(handles.signal_t1,'FontSize',8)
  
  
  
  
  
end
