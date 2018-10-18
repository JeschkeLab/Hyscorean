function updateHyscoreanGUI(handles,Processed)
%------------------------------------------------------------------------
% Updater of the HYSCOREAN GUI
%------------------------------------------------------------------------
% Automatically update all graphical elements present on the GUI according
% to the most recent data.
% This function is responsible for the plotting the main spectrum as well
% as for calling the function responsible for the plots containing the time
% domain signals
%
% Luis Fabregas, Hyscorean 2018

% Preparations
%------------------------------------------------------------------------

%Deactivate all pushbuttons until the graphics are rendered  & update info display
set(findall(handles.HyscoreanFigure, 'Style', 'pushbutton'),'enable','inactive')
set(findall(handles.HyscoreanFigure, 'Style', 'radiobutton'),'enable','inactive')
set(findall(handles.HyscoreanFigure, 'Style', 'checkbox'),'enable','inactive')
set(findall(handles.HyscoreanFigure, 'Style', 'edit'),'enable','inactive')
set(findall(handles.HyscoreanFigure, 'Style', 'slider'),'enable','inactive')
set(findall(handles.HyscoreanFigure, 'Style', 'popupmenu'),'enable','inactive')
set(handles.ProcessingInfo, 'String', 'Status: Rendering...'); drawnow;

%Enable all graphics-related GUI components
set(handles.PreProcessedTrace,'visible','on')
set(handles.NonCorrectedTrace,'visible','on')
set(handles.PlotApodizationWindow,'visible','on')
set(handles.DetachSignalPlot,'visible','on')
set(handles.ChangeSignalPlotDimension,'visible','on')
set(handles.t1_Slider,'enable','on')
%Set background of all signalPlot GUI components to white to match background
set(handles.PreProcessedTrace,'BackgroundColor','white')
set(handles.NonCorrectedTrace,'BackgroundColor','white')
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
  setappdata(0,'Hammingedit',get(handles.Hammingedit,'String'))
setappdata(0,'WindowType',get(handles.WindowType,'Value'))
  
  %Call graphical settings GUI
  Hyscorean_detachedSignalPlot
end

% Update Main plot
%------------------------------------------------------------------------

%Get data
Spectrum = Processed.spectrum;
axis1 = Processed.axis1;
axis2 = Processed.axis2;

%Get and set axis limits
XupperLimit = str2double(get(handles.XUpperLimit,'string'));
XlowerLimit = -XupperLimit;
YupperLimit = XupperLimit;
YlowerLimit = 0;

%Load current graphical settings
GraphicalSettings = handles.GraphicalSettings;

%Type of spectrum
if GraphicalSettings.Absolute
  Spectrum = abs(Spectrum);
elseif GraphicalSettings.Real
  Spectrum = abs(Spectrum);
elseif GraphicalSettings.Imaginary
  Spectrum = imag(Spectrum);
end

%Select current colormap
switch GraphicalSettings.Colormap
  case 1
    colormap('parula')
  case 2
    colormap('jet')
  case 3
    colormap('hsv')
  case 4
    colormap('hot')
  case 5
    colormap('cool')
  case 6
    colormap('spring')
  case 7
    colormap('summer')
  case 8
    colormap('autumn')
  case 9
    colormap('winter')
  case 10
    colormap('gray')
end

%Compute contour levels according to minimal contour level given by user
Levels=GraphicalSettings.Levels;
MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
MaximalContourLevel = max(max(abs(Processed.spectrum)));
MinimalContourLevel = MaximalContourLevel*MinimalContourLevel/100;
ContourLevelIncrement = (MaximalContourLevel - MinimalContourLevel)/Levels;
ContourLevels = MinimalContourLevel:ContourLevelIncrement:MaximalContourLevel;

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
      contour(handles.mainPlot,axis1,axis2,Spectrum,ContourLevels,'LineWidth',GraphicalSettings.Linewidth,'Color','k');
    else
      contour(handles.mainPlot,axis1,axis2,Spectrum,ContourLevels,'LineWidth',GraphicalSettings.Linewidth);
    end
  case 2 %Filled contour plot
    contourf(handles.mainPlot,axis1,axis2,Spectrum,ContourLevels);
  case 3 %Pseudocolor plot
    pcolor(handles.mainPlot,axis1,axis2,Spectrum),shading(handles.mainPlot,'interp')
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
curerntXTicks = xticks(handles.mainPlot);
yticks(handles.mainPlot,curerntXTicks(curerntXTicks>=0))

%If auxiliare lines have been added (and not cleared) add them again
if isfield(handles,'AddedLines')
  for i=1:length(handles.AddedLines)
    hold(handles.mainPlot,'on')
    plot(handles.mainPlot,handles.AddedLines{i}.x,handles.AddedLines{i}.y,'k-.','LineWidth',0.5)
    hold(handles.mainPlot,'off')
  end
end

%If isotope tags have been added (and not cleared) add them again
if isfield(handles,'AddedTags')
  for i=1:length(handles.AddedTags)
    text(handles.mainPlot,XupperLimit/20 + handles.AddedTags{i}.x,handles.AddedTags{i}.y,handles.AddedTags{i}.Tag,'FontSize',14)
  end
end


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
