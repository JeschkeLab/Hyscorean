function updateHyscoreanGUI(handles,Processed)
%==========================================================================
% Updater of the HYSCOREAN GUI
%==========================================================================
% Automatically update all graphical elements present on the GUI according
% to the most recent data. This function is responsible for the plotting the
% main spectrum as well as for calling the function responsible for the
% plots containing the time domain signals.
% During the creation and rendering of the graphics, all UI elements are
% disabled until they are rendered to avoid overloading the main program.
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

try
  
  %Deactivate all pushbuttons until the graphics are rendered  & update info display
  set(findall(handles.HyscoreanFigure, 'Style', 'pushbutton'),'enable','inactive')
  set(findall(handles.HyscoreanFigure, 'Style', 'radiobutton'),'enable','inactive')
  set(findall(handles.HyscoreanFigure, 'Style', 'checkbox'),'enable','inactive')
  set(findall(handles.HyscoreanFigure, 'Style', 'edit'),'enable','inactive')
  set(findall(handles.HyscoreanFigure, 'Style', 'slider'),'enable','inactive')
  set(findall(handles.HyscoreanFigure, 'Style', 'popupmenu'),'enable','inactive')
  set(handles.ProcessingInfo, 'String', 'Status: Rendering...')
  %Re-deactivate all which were deactivated (just aesthetic)
  if ~get(handles.Lorentz2GaussCheck,'Value')
    enableDisableGUI(handles,'Lorent2Gauss','off')
  end
  if ~handles.Data.NUSflag
    enableDisableGUI(handles,'NUSReconstruction','off')
  end
  enableDisableGUI(handles,'AutomaticBackground','off')
  
  
  drawnow;
  %Enable all graphics-related GUI components
  set(handles.PreProcessedTrace,'visible','on')
  set(handles.ImaginaryTrace,'visible','on')
  set(handles.NonCorrectedTrace,'visible','on')
  set(handles.PlotApodizationWindow,'visible','on')
  set(handles.DetachSignalPlot,'visible','on')
  set(handles.ChangeSignalPlotDimension,'visible','on')
  set(handles.t1_Slider,'enable','on')
  %Set background of all signalPlot GUI components to white to match background
  set(handles.PreProcessedTrace,'BackgroundColor','white')
  set(handles.NonCorrectedTrace,'BackgroundColor','white')
  set(handles.ImaginaryTrace,'BackgroundColor','white')
  set(handles.PlotApodizationWindow,'BackgroundColor','white')
  set(handles.DetachSignalPlot,'BackgroundColor','white')
  
  % Update signal plots
  %------------------------------------------------------------------------
  Processed.TimeAxis1 = linspace(0,handles.Data.TimeStep1*size(Processed.Signal,1),size(Processed.Signal,1));
  Processed.TimeAxis2 = linspace(0,handles.Data.TimeStep2*size(Processed.Signal,2),size(Processed.Signal,2));
  % Activate sliders
  Npoints = length(Processed.TimeAxis2) - str2double(get(handles.ZeroFilling2,'string'));
  set(handles.t1_Slider,'Min', 1, 'Max',Npoints , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 1)
  handles.PlotProcessedSignal = true;
  try
    HyscoreanSignalPlot(handles,Processed);
  catch
  end
  
  % Update external signal plot GUI
  %------------------------------------------------------------------------
  if ~isfield(handles,'SignalPlotIsDetached')
    handles.SignalPlotIsDetached = false;
  end
  if handles.SignalPlotIsDetached
    setappdata(0,'Processed',handles.Processed)
    setappdata(0,'Data',handles.Data)
    setappdata(0,'InvertCorrection',get(handles.InvertCorrection,'value'))
    setappdata(0,'ZeroFilling1',str2double(get(handles.ZeroFilling1,'String')))
    setappdata(0,'ZeroFilling2',str2double(get(handles.ZeroFilling2,'String')))
    setappdata(0,'WindowLength1',get(handles.WindowLength1,'String'))
    setappdata(0,'WindowLength2',get(handles.WindowLength2,'String'))
    setappdata(0,'WindowType',get(handles.WindowType,'Value'))
    
    %Call graphical settings GUI
    Hyscorean_detachedSignalPlot
  end
  
  % Update Main plot
  %------------------------------------------------------------------------
  
  %Get data
  Spectrum = Processed.spectrum;
  FrequencyAxis1 = Processed.axis1;
  FrequencyAxis2 = Processed.axis2;
  
  %Get and set axis limits
  XupperLimit = str2double(get(handles.XUpperLimit,'string'));
  XlowerLimit = -XupperLimit;
  YupperLimit = XupperLimit;
  YlowerLimit = 0;
  
  %Load current graphical settings
  GraphicalSettings = getpref('hyscorean','graphicalsettings');
  
  %Type of spectrum
  if GraphicalSettings.Absolute
    Spectrum = abs(Spectrum);
  elseif GraphicalSettings.Real
    Spectrum = real(Spectrum);
  elseif GraphicalSettings.Imaginary
    Spectrum = imag(Spectrum);
  end
  
  %Select current colormap
  if isfield(handles.GraphicalSettings,'ColormapName')
    colormap(colormap(handles.GraphicalSettings.ColormapName))
  else
    colormap('parula')
  end
  %Compute contour levels according to minimal contour level given by user
  Levels=GraphicalSettings.Levels;
  MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'))/100;
  MaximalContourLevel = str2double(get(handles.MaximalContourLevel,'string'))/100;
  
  if MinimalContourLevel~=0 && GraphicalSettings.Absolute
    MaximalContourLevel = MaximalContourLevel*max(max(Spectrum));
    Spectrum(Spectrum>MaximalContourLevel) = MaximalContourLevel;
    MinimalContourLevel = max(max(abs(Processed.spectrum)))*MinimalContourLevel;
    ContourLevelIncrement = (MaximalContourLevel - MinimalContourLevel)/Levels;
    ContourLevels = MinimalContourLevel:ContourLevelIncrement:MaximalContourLevel;
  else
    MaximalContourLevel = max(max(Spectrum));
    MinimalContourLevel = min(min(Spectrum));
    ContourLevelIncrement = (MaximalContourLevel - MinimalContourLevel)/Levels;
    ContourLevels = MinimalContourLevel:ContourLevelIncrement:MaximalContourLevel;
  end
  
  %If blindspots are to be plotted, superimpose them to the spectrum
  if get(handles.ImposeBlindSpots,'Value')
    [BlindSpotsMap,BlindSpotsAxis1,BlindSpotsAxis2] = imposeBlindSpots(handles);
    BlindSpotsMap = BlindSpotsMap/max(max(BlindSpotsMap))*max(max(Spectrum)); colormap('hot')
    BlindSpots = pcolor(handles.mainPlot,BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap);shading(handles.mainPlot,'flat'),
    alpha(BlindSpots,0.7);
    hold(handles.mainPlot,'on')
  end
  
  %Construct main plot
  switch GraphicalSettings.PlotType
    case 1 %Contour plot
      if get(handles.ImposeBlindSpots,'Value')
        %If blindspots are superimposed, make contour only black to adapt to hot-colormap
        contour(handles.mainPlot,FrequencyAxis1,FrequencyAxis2,Spectrum,ContourLevels,'LineWidth',GraphicalSettings.LineWidth,'Color','k');
      else
        contour(handles.mainPlot,FrequencyAxis1,FrequencyAxis2,Spectrum,ContourLevels,'LineWidth',GraphicalSettings.LineWidth);
      end
    case 2 %Filled contour plot
      contourf(handles.mainPlot,FrequencyAxis1,FrequencyAxis2,Spectrum,ContourLevels);
    case 3 %Pseudocolor plot
      pcolor(handles.mainPlot,FrequencyAxis1,FrequencyAxis2,Spectrum),shading(handles.mainPlot,'interp')
  end
  
  %Add diagonal/antidiagonal and zero-vertical auxiliary lines
  hold(handles.mainPlot,'on')
  LineAxis = linspace(-XupperLimit,XupperLimit,1000);
  handles.Diagonals = plot(handles.mainPlot,LineAxis,abs(LineAxis),'k-.');
  set(handles.mainPlot,'LineWidth',0.5)
  handles.VerticalLine = plot(handles.mainPlot,zeros(length(LineAxis)),abs(LineAxis),'k-','LineWidth',0.5);
  set(handles.mainPlot,'LineWidth',1)
  hold(handles.mainPlot,'off')
  
  %Format axes
  grid(handles.mainPlot,'on')
  set(handles.mainPlot,'ylim',[YlowerLimit YupperLimit],'xlim',[XlowerLimit XupperLimit])
  xlabel(handles.mainPlot,'\nu_1 [MHz]');
  ylabel(handles.mainPlot,'\nu_2 [MHz]');
  currentXTicks = xticks(handles.mainPlot);
  currentYTicks = currentXTicks(currentXTicks>=0);
  xticks(handles.mainPlot,currentXTicks)
  yticks(handles.mainPlot,currentYTicks)
  set(handles.mainPlot,'yticklabel',currentYTicks,'xticklabel',currentXTicks)
  
  
  % Finish & Exit
  %------------------------------------------------------------------------
  
  %Reactivate all pushbuttons & update info display
  set(handles.ProcessingInfo, 'String', 'Status: Finished');drawnow
  set(findall(handles.HyscoreanFigure, 'Style', 'pushbutton'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'radiobutton'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'checkbox'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'edit'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'slider'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'popupmenu'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'text'),'enable','on')
  
  %Re-deactivate all which were deactivated
  if ~get(handles.Lorentz2GaussCheck,'Value')
    enableDisableGUI(handles,'Lorent2Gauss','off')
  end
  if ~handles.Data.NUSflag
    enableDisableGUI(handles,'NUSReconstruction','off')
  else
    enableDisableGUI(handles,'NUSReconstruction','on')
  end
  enableDisableGUI(handles,'AutomaticBackground','on')
  
  
catch Error
  
  w = errordlg(sprintf('Error found during rendering of graphics: \n %s',Error.message));
  waitfor(w);
  %Reactivate all pushbuttons & update info display
  set(handles.ProcessingInfo, 'String', 'Status: Finished');drawnow
  set(findall(handles.HyscoreanFigure, 'Style', 'pushbutton'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'radiobutton'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'checkbox'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'edit'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'slider'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'popupmenu'),'enable','on')
  set(findall(handles.HyscoreanFigure, 'Style', 'text'),'enable','on')
  
  %Re-deactivate all which were deactivated
  if ~get(handles.Lorentz2GaussCheck,'Value')
    enableDisableGUI(handles,'Lorent2Gauss','off')
  end
  if ~handles.Data.NUSflag
    enableDisableGUI(handles,'NUSReconstruction','off')
  else
    enableDisableGUI(handles,'NUSReconstruction','on')
  end
  enableDisableGUI(handles,'AutomaticBackground','on')
  
  
end

drawnow